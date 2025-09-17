library(tidycensus)
library(dplyr)
library(stringr)

# --- Set up Census API key ---
# Replace "YOUR_API_KEY" with your actual key from https://api.census.gov/data/key_signup.html
census_api_key("YOUR_API_KEY", install = TRUE)

# Load ACS variables for a given year and dataset
vars_acs <- load_variables(
  year = 2022,          # Change year if needed
  dataset = "acs5",     # Change to "acs1" or other datasets if needed
  cache = TRUE
)

# Search by keywords or codes
search_vars_by_keyword <- function(vars_df, keywords) {
  pattern <- paste(keywords, collapse = "|")  # join with OR
  vars_df %>%
    filter(
      str_detect(label, regex(pattern, ignore_case = TRUE)) |
        str_detect(concept, regex(pattern, ignore_case = TRUE)) |
        str_detect(name, regex(pattern, ignore_case = TRUE))    # now also checks variable codes
    )
}

# Example: search for transportation-related terms
vehicle_vars <- search_vars_by_keyword(vars_acs, c("vehicle", "car", "automobile")) #replace with search words

# Define a function to search by table prefix (e.g., B08201)
search_vars_by_prefix <- function(vars_df, prefix) {
  vars_df %>%
    filter(str_detect(name, paste0("^", prefix)))
}

# search for selected variables in table 
selected_vars <- search_vars_by_prefix(vars_acs, "B08201") #e.g. B08201 (vehicles available)
