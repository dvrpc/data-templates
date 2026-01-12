# Tidycensus
This folder contains R query templates for using the Tidycensus package in DVRPC. It focuses solely on ACS queries.

## API key
Before starting to work with Tidycensus, users need to request and receive an API code. Request a free API key here.

After receiving the unique key in an email, run this code
```
# Once you receive your key (usually by email), run:
census_api_key("YOUR_KEY_HERE", install = TRUE) #only need to install once

# Restart your R session or reload environment variables:
readRenviron("~/.Renviron")
```

> [!NOTE]
> You only need to install the API key once, not every time you work with tidycensus.

### Templates in repository
1. search-acs-variables: using Tidycensus functions to review the different ACS variables by keywords and/or table code
2. get-acs-variables-for-dvrpc-region: Export a wide-format table of multiple requested variables for the entire DVRPC region
3. aggregate-an-area: grab variables AND aggregate a specific area (multiple geographic units) into one
4. by-muni: get variables for municipality (county subdivision) level for either one municipality or combined municipalities (by unique geoid code). 
