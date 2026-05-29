library(shiny)
library(bslib)
library(brand.yml)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(pins)

source("config.R")
source("R/storage.R")

# ── Theme ─────────────────────────────────────────────────────────────────────
brand_theme <- bs_theme(brand = "_brand.yml") |>
  bs_add_rules("
    .vel-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(80px, 1fr)); gap: 6px; }
    .vel-grid .form-group { margin-bottom: 0; }
    .vel-grid label { font-size: 0.78rem; color: #A7A9AC; margin-bottom: 2px; }
    .vel-grid input { font-size: 1rem; font-weight: 600; text-align: center; padding: 6px 4px; height: 42px; }
    .stat-box { background: #fff; border-left: 4px solid #D71920; border-radius: 4px;
                padding: 10px 14px; margin-bottom: 8px; }
    .stat-box .stat-label { font-size: 0.75rem; color: #A7A9AC; text-transform: uppercase; letter-spacing: .04em; }
    .stat-box .stat-value { font-size: 1.5rem; font-weight: 700; font-family: 'Roboto Slab', serif; }
    .sidebar-section { font-family: 'Roboto Slab', serif; font-size: 0.85rem;
                       text-transform: uppercase; letter-spacing: .06em;
                       color: #A7A9AC; margin: 14px 0 6px; }
    .btn-entry { width: 100%; margin-top: 4px; }
    #save_sheet { background-color: #4CAF50 !important; border-color: #4CAF50 !important; }
    #clear_session { background-color: #A7A9AC !important; border-color: #A7A9AC !important; color: #fff !important; }
    .save-status { font-size: 0.85rem; margin-top: 6px; min-height: 20px; }
  ")

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- page_navbar(
  title = tags$span(
    tags$img(src = "csi_logo.png", height = "28px", style = "margin-right:8px; vertical-align:middle;", alt = ""),
    "Performance Testing"
  ),
  theme = brand_theme,

  # ── Load-Velocity Tab ──────────────────────────────────────────────────────
  nav_panel(
    title = "Load-Velocity",
    icon  = icon("chart-line"),

    layout_sidebar(
      fillable = TRUE,

      # ── Sidebar ────────────────────────────────────────────────────────────
      sidebar = sidebar(
        width = 280,

        # Session setup
        div(class = "sidebar-section", "Session"),
        selectInput("athlete",  "Athlete",   choices = ATHLETES,  selected = ""),
        selectInput("exercise", "Exercise",  choices = EXERCISES, selected = "Back Squat"),
        dateInput(  "date",     "Date",      value   = Sys.Date(), width = "100%"),

        # Set entry
        div(class = "sidebar-section", "Set Entry"),
        fluidRow(
          column(7, numericInput("load",   paste0("Load (", LOAD_UNIT, ")"),
                                 value = NA, min = 0, max = 999, step = 2.5, width = "100%")),
          column(5, numericInput("n_reps", "Reps",
                                 value = 5,  min = 1, max = 20,  step = 1,   width = "100%"))
        ),

        # Dynamic velocity inputs
        uiOutput("velocity_inputs"),

        hr(style = "margin: 10px 0;"),

        # Action buttons
        actionButton("add_set",      "Add Set",             class = "btn btn-primary btn-entry"),
        actionButton("save_sheet",   "Save to Connect", class = "btn btn-entry mt-2"),
        actionButton("clear_session","Clear Session",        class = "btn btn-entry mt-1"),

        div(class = "save-status", uiOutput("save_status"))
      ),

      # ── Main panel ─────────────────────────────────────────────────────────
      div(
        # Summary stats row
        fluidRow(
          column(3, uiOutput("stat_sets")),
          column(3, uiOutput("stat_mv")),
          column(3, uiOutput("stat_peak")),
          column(3, uiOutput("stat_load"))
        ),

        # Charts row
        fluidRow(
          column(6,
            card(
              card_header("Load-Velocity Profile"),
              card_body(
                padding = "8px",
                plotlyOutput("lv_plot", height = "320px")
              )
            )
          ),
          column(6,
            card(
              card_header("Rep Velocities — Current Set"),
              card_body(
                padding = "8px",
                plotlyOutput("rep_plot", height = "320px")
              )
            )
          )
        ),

        # Session table
        card(
          card_header("Session Log"),
          card_body(
            padding = "8px",
            DTOutput("session_table")
          )
        )
      )
    )
  ),

  # Placeholder tabs for future tests
  nav_panel(
    title   = "Countermovement Jump",
    icon    = icon("person-running"),
    p("Coming soon.", style = "color: #A7A9AC; padding: 40px; font-style: italic;")
  ),

  nav_spacer(),
  nav_item(
    tags$a(
      icon("circle-info"), " CSI Pacific",
      href = "https://www.csipacific.ca", target = "_blank",
      style = "color: rgba(255,255,255,.8); font-size:.85rem;"
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # Reactive store for session data
  rv <- reactiveValues(
    session_data = tibble(
      date       = as.Date(character()),
      athlete    = character(),
      exercise   = character(),
      set_number = integer(),
      load       = numeric(),
      rep        = integer(),
      velocity   = numeric()
    ),
    set_counter  = 0L,
    save_message = NULL,
    save_ok      = TRUE
  )

  # ── Dynamic velocity inputs ──────────────────────────────────────────────
  output$velocity_inputs <- renderUI({
    n <- as.integer(input$n_reps)
    if (is.na(n) || n < 1) return(NULL)

    inputs <- lapply(seq_len(n), function(i) {
      div(
        tags$label(paste0("Rep ", i)),
        numericInput(
          inputId = paste0("vel_", i),
          label   = NULL,
          value   = NA,
          min     = 0, max = 5, step = 0.01,
          width   = "100%"
        )
      )
    })

    tagList(
      tags$label(paste0("Velocity (", VEL_UNIT, ") per Rep")),
      div(class = "vel-grid", inputs)
    )
  })

  # ── Add Set ──────────────────────────────────────────────────────────────
  observeEvent(input$add_set, {
    req(input$athlete, input$exercise, input$load, input$n_reps)

    if (!nzchar(input$athlete)) {
      showNotification("Please select an athlete.", type = "warning")
      return()
    }
    if (is.na(input$load) || input$load <= 0) {
      showNotification("Please enter a valid load.", type = "warning")
      return()
    }

    n      <- as.integer(input$n_reps)
    vels   <- vapply(seq_len(n), function(i) {
      val <- input[[paste0("vel_", i)]]
      if (is.null(val) || is.na(val)) NA_real_ else as.numeric(val)
    }, numeric(1))

    if (any(is.na(vels))) {
      showNotification("Please enter velocity for every rep.", type = "warning")
      return()
    }

    rv$set_counter <- rv$set_counter + 1L

    new_rows <- tibble(
      date       = input$date,
      athlete    = input$athlete,
      exercise   = input$exercise,
      set_number = rv$set_counter,
      load       = as.numeric(input$load),
      rep        = seq_len(n),
      velocity   = vels
    )

    rv$session_data  <- bind_rows(rv$session_data, new_rows)
    rv$save_message  <- NULL

    # Clear velocity inputs
    lapply(seq_len(n), function(i) updateNumericInput(session, paste0("vel_", i), value = NA))

    showNotification(
      paste0("Set ", rv$set_counter, " added — ", input$load, " ", LOAD_UNIT,
             " × ", n, " reps"),
      type = "message", duration = 3
    )
  })

  # ── Save to pin ──────────────────────────────────────────────────────────
  observeEvent(input$save_sheet, {
    if (nrow(rv$session_data) == 0) {
      showNotification("No data to save yet.", type = "warning")
      return()
    }

    rv$save_message <- "Saving..."
    rv$save_ok      <- TRUE

    tryCatch({
      storage_append(rv$session_data)
      rv$save_message <- paste0("✓ Saved ", nrow(rv$session_data),
                                " rows at ", format(Sys.time(), "%H:%M"))
      rv$save_ok      <- TRUE
      showNotification("Saved to Connect.", type = "message", duration = 4)
    }, error = function(e) {
      rv$save_message <- paste0("✗ Error: ", conditionMessage(e))
      rv$save_ok      <- FALSE
      showNotification(paste("Save failed:", conditionMessage(e)), type = "error", duration = 8)
    })
  })

  # ── Clear Session ────────────────────────────────────────────────────────
  observeEvent(input$clear_session, {
    showModal(modalDialog(
      title  = "Clear session?",
      "This will remove all sets from the current session. Unsaved data will be lost.",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_clear", "Clear", class = "btn btn-danger")
      )
    ))
  })

  observeEvent(input$confirm_clear, {
    rv$session_data  <- rv$session_data[0, ]
    rv$set_counter   <- 0L
    rv$save_message  <- NULL
    removeModal()
    showNotification("Session cleared.", type = "warning", duration = 3)
  })

  # ── Save status text ─────────────────────────────────────────────────────
  output$save_status <- renderUI({
    req(rv$save_message)
    colour <- if (isTRUE(rv$save_ok)) "#4CAF50" else "#D32F2F"
    div(style = paste0("color:", colour, ";"), rv$save_message)
  })

  # ── Summary stats ────────────────────────────────────────────────────────
  stat_box <- function(label, value_expr) {
    output_id <- paste0("stat_", label)
    renderUI({
      val <- value_expr()
      div(
        class = "stat-box",
        div(class = "stat-label", label),
        div(class = "stat-value", val)
      )
    })
  }

  output$stat_sets <- renderUI({
    n <- rv$set_counter
    div(class = "stat-box",
        div(class = "stat-label", "Sets"),
        div(class = "stat-value", n))
  })

  output$stat_mv <- renderUI({
    d <- rv$session_data
    val <- if (nrow(d) == 0) "—" else {
      latest_set <- max(d$set_number)
      mv <- mean(d$velocity[d$set_number == latest_set], na.rm = TRUE)
      sprintf("%.2f %s", mv, VEL_UNIT)
    }
    div(class = "stat-box",
        div(class = "stat-label", "Mean Vel (last set)"),
        div(class = "stat-value", val))
  })

  output$stat_peak <- renderUI({
    d <- rv$session_data
    val <- if (nrow(d) == 0) "—" else {
      latest_set <- max(d$set_number)
      pv <- max(d$velocity[d$set_number == latest_set], na.rm = TRUE)
      sprintf("%.2f %s", pv, VEL_UNIT)
    }
    div(class = "stat-box",
        div(class = "stat-label", "Peak Vel (last set)"),
        div(class = "stat-value", val))
  })

  output$stat_load <- renderUI({
    d <- rv$session_data
    val <- if (nrow(d) == 0) "—" else {
      latest_load <- d$load[d$set_number == max(d$set_number)][1]
      paste(latest_load, LOAD_UNIT)
    }
    div(class = "stat-box",
        div(class = "stat-label", "Load (last set)"),
        div(class = "stat-value", val))
  })

  # ── Load-Velocity Profile plot ───────────────────────────────────────────
  output$lv_plot <- renderPlotly({
    d <- rv$session_data
    if (nrow(d) == 0) {
      p <- ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "Add a set to see the profile",
                 colour = "#A7A9AC", size = 4, family = "Open Sans") +
        theme_void()
      return(ggplotly(p) |> layout(paper_bgcolor = "#FCFCFC", plot_bgcolor = "#FCFCFC"))
    }

    # Mean velocity per set
    summary_d <- d |>
      group_by(set_number, load) |>
      summarise(mean_vel = mean(velocity, na.rm = TRUE),
                .groups = "drop")

    p <- ggplot(summary_d, aes(x = load, y = mean_vel,
                                text = paste0("Set ", set_number, "<br>",
                                              load, " ", LOAD_UNIT, "<br>",
                                              sprintf("%.2f", mean_vel), " ", VEL_UNIT))) +
      geom_smooth(method = "lm", se = TRUE, colour = "#D71920", fill = "#D71920",
                  alpha = 0.12, linewidth = 0.8, na.rm = TRUE) +
      geom_point(colour = "#D71920", size = 4, alpha = 0.9) +
      geom_text(aes(label = paste0("S", set_number)),
                vjust = -1, size = 3, colour = "#000000", family = "Open Sans") +
      scale_x_continuous(expand = expansion(mult = 0.15)) +
      scale_y_continuous(expand = expansion(mult = 0.15)) +
      labs(x = paste0("Load (", LOAD_UNIT, ")"),
           y = paste0("Mean Velocity (", VEL_UNIT, ")")) +
      theme_minimal(base_family = "Open Sans") +
      theme(
        plot.background  = element_rect(fill = "#FCFCFC", colour = NA),
        panel.grid.minor = element_blank(),
        axis.title       = element_text(size = 11),
        axis.text        = element_text(size = 10)
      )

    ggplotly(p, tooltip = "text") |>
      layout(paper_bgcolor = "#FCFCFC", plot_bgcolor = "#FCFCFC",
             hoverlabel = list(bgcolor = "#000", font = list(color = "#fff")))
  })

  # ── Rep velocity bar chart ───────────────────────────────────────────────
  output$rep_plot <- renderPlotly({
    d <- rv$session_data
    if (nrow(d) == 0) {
      p <- ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "Add a set to see rep velocities",
                 colour = "#A7A9AC", size = 4, family = "Open Sans") +
        theme_void()
      return(ggplotly(p) |> layout(paper_bgcolor = "#FCFCFC", plot_bgcolor = "#FCFCFC"))
    }

    latest_set  <- max(d$set_number)
    latest_load <- d$load[d$set_number == latest_set][1]
    set_d       <- d |> filter(set_number == latest_set)
    mean_vel    <- mean(set_d$velocity, na.rm = TRUE)

    # Colour reps by velocity loss from rep 1
    set_d <- set_d |>
      mutate(
        vel_loss = (velocity[1] - velocity) / velocity[1] * 100,
        bar_colour = case_when(
          vel_loss < 10 ~ "#4CAF50",
          vel_loss < 20 ~ "#FFC107",
          TRUE          ~ "#D71920"
        )
      )

    p <- ggplot(set_d, aes(x = factor(rep), y = velocity,
                            fill = bar_colour,
                            text = paste0("Rep ", rep, "<br>",
                                          sprintf("%.2f", velocity), " ", VEL_UNIT, "<br>",
                                          sprintf("%.1f%%", vel_loss), " loss"))) +
      geom_col(colour = NA, width = 0.65, alpha = 0.9) +
      geom_hline(yintercept = mean_vel, linetype = "dashed",
                 colour = "#000000", linewidth = 0.5, alpha = 0.6) +
      annotate("text", x = Inf, y = mean_vel,
               label = paste0("Mean: ", sprintf("%.2f", mean_vel)),
               hjust = 1.1, vjust = -0.4, size = 3, colour = "#000000",
               family = "Open Sans") +
      scale_fill_identity() +
      scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
      labs(
        x       = "Rep",
        y       = paste0("Velocity (", VEL_UNIT, ")"),
        caption = paste0("Set ", latest_set, "  |  ", latest_load, " ", LOAD_UNIT,
                         "  |  Green <10% loss · Yellow <20% · Red ≥20%")
      ) +
      theme_minimal(base_family = "Open Sans") +
      theme(
        plot.background  = element_rect(fill = "#FCFCFC", colour = NA),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.title       = element_text(size = 11),
        axis.text        = element_text(size = 10),
        plot.caption     = element_text(size = 8, colour = "#A7A9AC")
      )

    ggplotly(p, tooltip = "text") |>
      layout(paper_bgcolor = "#FCFCFC", plot_bgcolor = "#FCFCFC",
             showlegend = FALSE)
  })

  # ── Session table ────────────────────────────────────────────────────────
  output$session_table <- renderDT({
    d <- rv$session_data
    if (nrow(d) == 0) return(
      datatable(
        tibble(Message = "No sets recorded yet."),
        options = list(dom = "t"), rownames = FALSE
      )
    )

    display <- d |>
      mutate(
        date     = format(date, "%Y-%m-%d"),
        velocity = round(velocity, 3)
      ) |>
      rename(
        Date     = date,
        Athlete  = athlete,
        Exercise = exercise,
        Set      = set_number,
        `Load (kg)` = load,
        Rep      = rep,
        `Velocity (m/s)` = velocity
      )

    datatable(
      display,
      rownames  = FALSE,
      selection = "none",
      options   = list(
        pageLength = 15,
        dom        = "frtip",
        order      = list(list(3, "asc"), list(5, "asc")),
        columnDefs = list(list(className = "dt-center", targets = "_all"))
      )
    ) |>
      formatStyle(
        "Velocity (m/s)",
        background = styleColorBar(range(d$velocity, na.rm = TRUE), "#D71920", angle = -90),
        backgroundSize = "100% 88%",
        backgroundRepeat = "no-repeat",
        backgroundPosition = "center"
      )
  })
}

shinyApp(ui, server)
