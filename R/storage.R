# Storage helpers (pins-based) -------------------------------------------------

PIN_NAME <- "lv_performance_data"

#' Return the appropriate pins board.
#' On Posit Connect the CONNECT_SERVER env var is set automatically.
#' Locally falls back to a folder-based board in the project directory.
get_board <- function() {
  if (nzchar(Sys.getenv("CONNECT_SERVER"))) {
    pins::board_connect()
  } else {
    pins::board_folder("data", versioned = FALSE)
  }
}

#' Read all historical data from the pin.
#' Returns an empty tibble with the correct schema if the pin doesn't exist yet.
storage_read <- function() {
  board <- get_board()
  pins_list <- pins::pin_list(board)
  if (!PIN_NAME %in% pins_list) {
    return(tibble::tibble(
      date       = as.Date(character()),
      athlete    = character(),
      exercise   = character(),
      set_number = integer(),
      load       = numeric(),
      rep        = integer(),
      velocity   = numeric()
    ))
  }
  pins::pin_read(board, PIN_NAME)
}

#' Append new rows to the pin, creating it if it doesn't exist.
storage_append <- function(new_rows) {
  board    <- get_board()
  existing <- storage_read()
  updated  <- dplyr::bind_rows(existing, new_rows)
  pins::pin_write(board, updated, name = PIN_NAME, type = "csv")
  invisible(updated)
}
