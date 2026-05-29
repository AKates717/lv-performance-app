# Load-Velocity Performance Testing App

R Shiny app for real-time load-velocity profiling during strength training.

## Setup

### 1. Install R packages

```r
install.packages(c("shiny", "bslib", "dplyr", "ggplot2", "plotly", "DT", "googlesheets4"))
```

Or use `renv`:

```r
install.packages("renv")
renv::restore()
```

### 2. Configure athletes and exercises

Edit `config.R`:
- Update the `ATHLETES` vector with your roster.
- Add or remove exercises in the `EXERCISES` list.

### 3. Set up Google Sheets

1. Create a Google Sheet with any name.
2. Copy the Sheet ID from the URL:
   `https://docs.google.com/spreadsheets/d/**<<SHEET_ID>>**/edit`
3. Paste it into `config.R` as `GSHEET_ID`.
4. Share the sheet with your Google account (or service account — see below).

**Local development** — authenticate once interactively:

```r
googlesheets4::gs4_auth()
```

This caches a token in `~/.config/gargle/`.

**Posit Connect Cloud** — use a service account:

1. Create a service account in [Google Cloud Console](https://console.cloud.google.com) → IAM & Admin → Service Accounts.
2. Enable the Google Sheets API for your project.
3. Download the JSON key file.
4. Share your Google Sheet with the service account email (e.g. `my-sa@project.iam.gserviceaccount.com`).
5. In Posit Connect, add an environment variable / secret:
   - Name: `GOOGLE_APPLICATION_CREDENTIALS`
   - Value: the **contents** of the JSON key file (as a string), or the path to the file if you include it in the repo (not recommended).

> The app's `R/sheets.R` automatically detects this environment variable and uses it for auth.

### 4. Run locally

```r
shiny::runApp()
```

### 5. Deploy to Posit Connect Cloud

1. Push the repo to GitHub.
2. Connect your GitHub repo in Posit Connect Cloud.
3. Set the `GOOGLE_APPLICATION_CREDENTIALS` secret in the Connect dashboard.
4. Deploy.

## Data Schema

Each row in Google Sheets represents one **repetition**:

| Column     | Description                         |
|------------|-------------------------------------|
| date       | Session date (YYYY-MM-DD)           |
| athlete    | Athlete name                        |
| exercise   | Exercise name                       |
| set_number | Set number within the session       |
| load       | Load in kg                          |
| rep        | Rep number within the set           |
| velocity   | Mean concentric velocity (m/s)      |

## Visualisations

- **Load-Velocity Profile** — scatter + linear regression of mean set velocity vs. load, updated after each set.
- **Rep Velocities** — bar chart for the most recent set, coloured by velocity loss from rep 1 (green <10%, yellow <20%, red ≥20%).
- **Session Log** — full rep-level table with velocity colour bars.
