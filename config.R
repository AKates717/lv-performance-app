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

# ── Units ─────────────────────────────────────────────────────────────────────
LOAD_UNIT  <- "kg"   # "kg" or "lbs"
VEL_UNIT   <- "m/s"
