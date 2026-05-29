# Google Sheets helpers --------------------------------------------------------

#' Authenticate with Google Sheets.
#' On Posit Connect, place your service account JSON path in the
#' GOOGLE_APPLICATION_CREDENTIALS environment variable (Connect secret).
#' Locally, run `googlesheets4::gs4_auth()` once interactively to cache a token.
sheets_auth <- function() {
  creds <- Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS")
  if (nzchar(creds) && file.exists(creds)) {
    googlesheets4::gs4_auth(path = creds)
  } else {
    googlesheets4::gs4_auth()
  }
}

#' Append rows to the configured Google Sheet.
#' Creates the sheet tab with a header row if it doesn't exist yet.
sheets_append <- function(df, sheet_id, tab) {
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
