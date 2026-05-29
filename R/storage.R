# Storage helpers (Supabase REST API) ------------------------------------------
# Reads SUPABASE_URL and SUPABASE_KEY from environment variables.
# Set them in Posit Connect → Settings → Vars, or in a local .Renviron file.

supabase_url <- function() {
  url <- Sys.getenv("SUPABASE_URL")
  if (!nzchar(url)) stop("SUPABASE_URL environment variable is not set.")
  # Normalise: strip trailing slash, ensure /rest/v1 suffix
  url <- sub("/+$", "", url)
  if (!grepl("/rest/v1$", url)) url <- paste0(url, "/rest/v1")
  url
}

supabase_key <- function() {
  key <- Sys.getenv("SUPABASE_KEY")
  if (!nzchar(key)) stop("SUPABASE_KEY environment variable is not set.")
  key
}

supabase_headers <- function() {
  key <- supabase_key()
  httr2::req_headers(
    apikey        = key,
    Authorization = paste("Bearer", key),
    `Content-Type` = "application/json",
    Prefer        = "return=minimal"
  )
}

#' Append rows to the Supabase load_velocity table.
storage_append <- function(df) {
  # Convert date to character for JSON serialisation
  df$date <- as.character(df$date)

  payload <- jsonlite::toJSON(df, auto_unbox = FALSE)

  httr2::request(paste0(supabase_url(), "/load_velocity")) |>
    supabase_headers() |>
    httr2::req_body_raw(payload, type = "application/json") |>
    httr2::req_method("POST") |>
    httr2::req_error(is_error = \(r) FALSE) |>
    httr2::req_perform() -> resp

  status <- httr2::resp_status(resp)
  if (status >= 300) {
    body <- httr2::resp_body_string(resp)
    stop(paste0("Supabase error (", status, "): ", body))
  }

  invisible(TRUE)
}

#' Read all rows from the Supabase load_velocity table.
storage_read <- function() {
  resp <- httr2::request(paste0(supabase_url(), "/load_velocity")) |>
    httr2::req_headers(
      apikey        = supabase_key(),
      Authorization = paste("Bearer", supabase_key())
    ) |>
    httr2::req_url_query(select = "*", order = "created_at.asc") |>
    httr2::req_error(is_error = \(r) FALSE) |>
    httr2::req_perform()

  status <- httr2::resp_status(resp)
  if (status >= 300) {
    warning("Could not read from Supabase: ", httr2::resp_body_string(resp))
    return(tibble::tibble())
  }

  rows <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  if (length(rows) == 0) return(tibble::tibble())

  tibble::as_tibble(rows) |>
    dplyr::mutate(date = as.Date(date))
}
