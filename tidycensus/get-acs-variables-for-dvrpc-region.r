library(tidycensus)
library(dplyr)
library(stringr)

# census_api_key("YOUR_API_KEY", install = FALSE)  # run once per session if needed

# DVRPC geography lists (do not modify if you need the entire DVRPC region)
dvrpc_states   <- c("NJ", "PA")
dvrpc_counties <- c('^34005|^34007|^34015|^34021|^42017|^42029|^42045|^42091|^42101')

# Params to tweak
year_selected <- 2023        # Change to requested year
geo_level     <- "tract"          # "tract", "county", "place", etc.
survey_type   <- "acs5"

# Requested variables list
# replace with whatever table(s) or codes you need
vars_list <- c(
  tot_hh          = "B08201_001",
  no_veh          = "B08201_002",
  one_veh         = "B08201_003",
  two_veh         = "B08201_004",
  three_veh       = "B08201_005",
  four_or_more_veh= "B08201_006"
)

# Pull ACS → wide → filter to DVRPC counties → tidy names
dvrpc_acs_wide <- get_acs(
  geography = geo_level,
  variables = vars_list,
  year      = year_selected,
  state     = dvrpc_states,   # all geos in both states
  survey    = survey_type,
  output    = "wide"
) %>%
  filter(str_detect(GEOID, dvrpc_counties)) %>%  # keep only DVRPC geo
  select(-NAME) %>%
  # *_E → drop suffix; *_M → *_MOE
  rename_with(~ str_replace(.x, "E$", ""), ends_with("E")) %>%
  rename_with(~ str_replace(.x, "M$", "_MOE"), ends_with("M"))
