library(tidycensus)
library(dplyr)
library(stringr)

# census_api_key("YOUR_API_KEY", install = FALSE)  # run once per session if needed

# ---- DVRPC geography lists ----
dvrpc_states   <- c("NJ", "PA")
dvrpc_counties <- c('^34005|^34007|^34015|^34021|^42017|^42029|^42045|^42091|^42101')

# ---- Params to tweak ----
year_selected <- 2023      # add year
geo_level     <- "tract"
survey_type   <- "acs5"

# ---- Requested variables ----
vars_list <- c(
  tot_hh            = "B08201_001",
  no_veh            = "B08201_002",
  one_veh           = "B08201_003",
  two_veh           = "B08201_004",
  three_veh         = "B08201_005",
  four_or_more_veh  = "B08201_006"
)

# ---- Pull ACS → wide → DVRPC counties only → tidy column names ----
dvrpc_acs_wide <- get_acs(
  geography = geo_level,
  variables = vars_list,
  year      = year_selected,
  state     = dvrpc_states,   # all tracts in NJ + PA
  survey    = survey_type,
  output    = "wide"
) %>%
  filter(str_detect(GEOID, dvrpc_counties)) %>%  # keep only DVRPC tracts
  select(-NAME) %>%
  rename_with(~ str_replace(.x, "E$", ""), ends_with("E")) %>%
  rename_with(~ str_replace(.x, "M$", "_MOE"), ends_with("M"))

# ---- Lower Merion (incl. Narberth) tract list ----
muni_name <- "Lower Merion (incl. Narberth), PA" #modify to the requested area
muni_tracts <- c(
  "42091205502","42091205402","42091205401","42091204500","42091204702",
  "42091205000","42091205503","42091205600","42091205300","42091205100",
  "42091205200","42091205501","42091204400","42091204600","42091204900",
  "42091204300","42091204800","42091204701"
) #modify to the requested area GEOID codes

# ---- Subset to those tracts ----
lm_df <- dvrpc_acs_wide %>%
  filter(GEOID %in% muni_tracts)

# ---- Aggregate: sum estimates + sum MOEs correctly ----
lm_sum <- lm_df %>%
  summarise(
    across(all_of(names(vars_list)), ~ sum(.x, na.rm = TRUE)),
    across(paste0(names(vars_list), "_MOE"), ~ moe_sum(.x, na.rm = TRUE))
  ) %>%
  mutate(municipality = muni_name, .before = 1)
