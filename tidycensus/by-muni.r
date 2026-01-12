suppressPackageStartupMessages({
  library(tidycensus)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(tidyr)
})

# ============================================================
# 0) Census API key (run once to install; then restart session)
# ============================================================
# If you've never installed your key on this machine, run this ONCE:
# census_api_key("YOUR_KEY_HERE", install = TRUE)

# If you've already installed it, you usually don't need this.
# If you want to force-load from ~/.Renviron in-session:
# readRenviron("~/.Renviron")

# ============================================================
# 1) Params
# ============================================================
year_selected  <- 2023
survey_type    <- "acs5"
dvrpc_states   <- c("NJ", "PA")
dvrpc_counties <- "^34005|^34007|^34015|^34021|^42017|^42029|^42045|^42091|^42101"

# Variables (example: vehicles)
vars_list <- c(
  tot_hh = "B08201_001",   # universe for % calc
  no_veh = "B08201_002"    # numerator
)

universe_name  <- "tot_hh"
numerator_name <- "no_veh"

# ============================================================
# 2) Pull ACS for county subdivisions (NJ + PA), keep DVRPC only
# ============================================================
acs_cousub <- map_dfr(dvrpc_states, \(st) {
  get_acs(
    geography = "county subdivision",
    state     = st,
    year      = year_selected,
    survey    = survey_type,
    variables = vars_list,
    output    = "wide"
  )
}) %>%
  # keep DVRPC counties by GEOID prefix (STATE+COUNTY)
  filter(str_detect(GEOID, dvrpc_counties)) %>%
  select(GEOID, NAME, ends_with("E"), ends_with("M")) %>%
  rename_with(~ str_replace(.x, "E$", ""), ends_with("E")) %>%
  rename_with(~ str_replace(.x, "M$", "_MOE"), ends_with("M"))

# ============================================================
# 3) Helpers
# ============================================================
# Optional: find cousubs by name so you can grab GEOIDs
find_cousub <- function(df, pattern) {
  df %>%
    filter(str_detect(NAME, regex(pattern, ignore_case = TRUE))) %>%
    select(GEOID, NAME)
}

# Aggregate one or many cousubs into one row (sum + % + MOE)
aggregate_cousub <- function(df, geoids, label, num_col, den_col) {
  x <- df %>% filter(GEOID %in% geoids)
  if (nrow(x) == 0) stop("No matching GEOIDs found.")
  
  num_est <- sum(x[[num_col]], na.rm = TRUE)
  den_est <- sum(x[[den_col]], na.rm = TRUE)
  
  num_moe <- tidycensus::moe_sum(x[[paste0(num_col, "_MOE")]], na.rm = TRUE)
  den_moe <- tidycensus::moe_sum(x[[paste0(den_col, "_MOE")]], na.rm = TRUE)
  
  pct <- ifelse(is.na(den_est) | den_est == 0, NA_real_, 100 * num_est / den_est)
  pct_moe <- ifelse(is.na(den_est) | den_est == 0, NA_real_,
                    100 * tidycensus::moe_prop(num_est, den_est, num_moe, den_moe))
  
  tibble(
    combined_name = label,
    geoids_used   = paste(geoids, collapse = ","),
    numerator     = num_col,
    universe      = den_col,
    estimate      = num_est,
    moe           = num_moe,
    universe_est  = den_est,
    universe_moe  = den_moe,
    pct           = pct,
    pct_moe       = pct_moe
  )
}

# ============================================================
# 4) Choose one cousub or multiple cousubs (combined)
# ============================================================

# Example lookup (uncomment to search by name):
# find_cousub(acs_cousub, "Merion")

# Option A: single cousub GEOID
one_geoids <- c("4209179136")  # <- replace
out_one <- aggregate_cousub(
  df      = acs_cousub,
  geoids  = one_geoids,
  label   = "Single cousub selection",
  num_col = numerator_name,
  den_col = universe_name
)

# Option B: multiple cousub GEOIDs (combined)
multi_geoids <- c("4209179136", "4209144976")  # <- replace
out_combined <- aggregate_cousub(
  df      = acs_cousub,
  geoids  = multi_geoids,
  label   = "Combined cousubs",
  num_col = numerator_name,
  den_col = universe_name
)

# ============================================================
# 5) EXPORT
# ============================================================
path_of_folder <- "enter/path/here"
name_of_output <- "cousub_vehicle_summary"

if (!dir.exists(path_of_folder)) {
  dir.create(path_of_folder, recursive = TRUE)
}

write.csv(
  out_combined, #change to out_one if needed
  file      = file.path(path_of_folder, paste0(name_of_output, ".csv")),
  row.names = FALSE
)

