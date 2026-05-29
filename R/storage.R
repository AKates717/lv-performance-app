# Storage helpers (pins-based) -------------------------------------------------
library(connectapi)  # required by pins::board_connect()

PIN_NAME <- "lv_performance_data"

#' Return the appropriate pins board.
#' On Posit Connect Cloud, CONNECT_SERVER and CONNECT_API_KEY are injected
#' automatically once "Use Service Account" is enabled in the app's Settings.
#' Locally falls back to a folder-based board in the project directory.
get_board <- function() {
  server  <- Sys.getenv("CONNECT_SERVER")
  api_key <- Sys.getenv("CONNECT_API_KEY")

  if (nzchar(server) && nzchar(api_key)) {
    pins::board_connect(
      server = server,
      key    = api_key
    )
  } else if (nzchar(server)) {
    # Server known but no key — try anonymous/implicit auth (self-hosted Connect)
    pins::board_connect(server = server)
  } else {
    # Local development: persist to a local folder
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
