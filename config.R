# ── Athletes ──────────────────────────────────────────────────────────────────
# Edit this list to update the athlete roster.
ATHLETES <- c(
  "Select athlete..." = "",
  "Athlete 1",
  "Athlete 2",
  "Athlete 3",
  "Athlete 4",
  "Athlete 5"
)

# ── Exercises ─────────────────────────────────────────────────────────────────
# Grouped by movement pattern for easier selection.
EXERCISES <- list(
  "Squat" = c(
    "Back Squat",
    "Front Squat",
    "Goblet Squat",
    "Safety Bar Squat"
  ),
  "Hinge" = c(
    "Conventional Deadlift",
    "Trap Bar Deadlift",
    "Romanian Deadlift",
    "Hex Bar Jump"
  ),
  "Push" = c(
    "Bench Press",
    "Push Press",
    "Overhead Press"
  ),
  "Pull" = c(
    "Barbell Row",
    "Pendlay Row"
  ),
  "Olympic" = c(
    "Power Clean",
    "Hang Power Clean",
    "Power Snatch",
    "Hang Power Snatch",
    "Clean Pull",
    "Snatch Pull"
  )
)

# ── Google Sheets ─────────────────────────────────────────────────────────────
# Paste the ID from your Google Sheet URL:
#   https://docs.google.com/spreadsheets/d/<<SHEET_ID>>/edit
# Leave blank to skip Google Sheets saving during development.
GSHEET_ID <- ""

# Name of the worksheet tab to write to.
GSHEET_TAB <- "load_velocity"

# ── Units ─────────────────────────────────────────────────────────────────────
LOAD_UNIT  <- "kg"   # "kg" or "lbs"
VEL_UNIT   <- "m/s"
