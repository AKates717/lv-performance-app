# Google Sheets helpers --------------------------------------------------------

#' Authenticate with Google Sheets.
#' On Posit Connect, place your service account JSON path in the
#' GOOGLE_APPLICATION_CREDENTIALS environment variable (Connect secret).
#' Locally, run `googlesheets4::gs4_auth()` once interactively to cache a token.
sheets_auth <- function() {
  creds <- Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS")
  if (!nzchar(creds)) {
    # Local dev: interactive browser auth
    googlesheets4::gs4_auth()
  } else if (file.exists(creds)) {
    # Path to a local JSON key file
    googlesheets4::gs4_auth(path = creds)
  } else {
    # JSON content pasted directly as an env var (Posit Connect)
    googlesheets4::gs4_auth(path = jsonlite::fromJSON(creds))
  }
}

#' Extract the bare Sheet ID from a full URL or return the value unchanged.
sheets_resolve_id <- function(x) {
  m <- regmatches(x, regexpr("(?<=/d/)[A-Za-z0-9_-]+", x, perl = TRUE))
  if (length(m) == 1L) m else x
}

#' Append rows to the configured Google Sheet.
#' Creates the sheet tab with a header row if it doesn't exist yet.
sheets_append <- function(df, sheet_id, tab) {
  sheet_id <- sheets_resolve_id(sheet_id)
  if (!nzchar(sheet_id)) {
    warning("GSHEET_ID is not set in config.R — skipping save.")
    return(invisible(NULL))
  }

  existing_tabs <- googlesheets4::sheet_names(sheet_id)

  if (!tab %in% existing_tabs) {
    googlesheets4::sheet_add(sheet_id, sheet = tab)
    googlesheets4::range_write(
      sheet_id,
      data = df,
      sheet = tab,
      range = "A1",
      col_names = TRUE,
      reformat = FALSE
    )
  } else {
    googlesheets4::sheet_append(sheet_id, data = df, sheet = tab)
  }
}
