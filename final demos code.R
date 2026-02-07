# -------------------------------------------
# Pull age x sex census counts (ACS 5-year)
# and summarize to GRYD zones (FeatureServer)
# WITH TOTAL POPULATION AND DETAILED PERCENTAGES BY AGE/GENDER
# -------------------------------------------

library(tidyverse)
library(sf)
library(tidycensus)

# -------------------------------------------
# 1) Census API key 
# -------------------------------------------
census_api_key("1ca10c48e1c5a38a06315a33c0a2bcc977d9fc48", install = TRUE)
readRenviron("~/.Renviron")

# -------------------------------------------
# 2) Read GRYD zones DIRECTLY from FeatureServer
# -------------------------------------------
gryd_url <- "https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/gryd116/FeatureServer/0/query?where=1%3D1&outFields=*&f=geojson"

gryd <- st_read(gryd_url, quiet = TRUE) %>%
  st_transform(4326)

# -------------------------------------------
# 3) Pull tract-level age by sex AND TOTAL POPULATION
# -------------------------------------------
year_acs <- 2022

vars <- load_variables(year_acs, "acs5", cache = TRUE)

# Age variables (same as before)
age_vars <- vars %>%
  filter(name %in% c(
    # ---- MALE ----
    "B01001_006", # Male: 10-14
    "B01001_007", # Male: 15-17
    "B01001_008", # Male: 18-19
    "B01001_009", # Male: 20
    "B01001_010", # Male: 21
    "B01001_011", # Male: 22-24
    
    # ---- FEMALE ----
    "B01001_030", # Female: 10-14
    "B01001_031", # Female: 15-17
    "B01001_032", # Female: 18-19
    "B01001_033", # Female: 20
    "B01001_034", # Female: 21
    "B01001_035", # Female: 22-24
    
    # ---- TOTAL POPULATION ----
    "B01001_001"  # Total population
  ))

# -------------------------------------------
# 4) Get census tracts for LA County (with geometry)
# -------------------------------------------
la_tracts <- get_acs(
  geography = "tract",
  variables = age_vars$name,
  year = year_acs,
  state = "CA",
  county = "Los Angeles",
  geometry = TRUE,
  output = "wide"
)

# -------------------------------------------
# 5) Build two age groups by sex AND capture total population
# -------------------------------------------
tract_age <- la_tracts %>%
  transmute(
    GEOID,
    geometry,
    
    # Total population
    total_pop = B01001_001E,
    
    # 10–15 = (10–14) + ~1/3 of (15–17)
    male_10_15 =
      B01001_006E +
      round(B01001_007E * (1/3)),
    
    # 16–24 = ~2/3 of (15–17) + (18–19) + 20 + 21 + (22–24)
    male_16_24 =
      round(B01001_007E * (2/3)) +
      B01001_008E +
      B01001_009E +
      B01001_010E +
      B01001_011E,
    
    female_10_15 =
      B01001_030E +
      round(B01001_031E * (1/3)),
    
    female_16_24 =
      round(B01001_031E * (2/3)) +
      B01001_032E +
      B01001_033E +
      B01001_034E +
      B01001_035E
  )

# -------------------------------------------
# 6) Make sure both layers share CRS
# -------------------------------------------
tract_age <- st_transform(tract_age, st_crs(gryd))

# -------------------------------------------
# 7) Intersect tracts with GRYD zones
# -------------------------------------------
tract_split <- st_intersection(tract_age, gryd)

# -------------------------------------------
# 8) Area-weight the counts (tract TO tract-piece)
# -------------------------------------------
tract_areas <- tract_age %>%
  mutate(tract_area = st_area(geometry)) %>%
  st_drop_geometry() %>%
  select(GEOID, tract_area)

tract_split <- tract_split %>%
  mutate(piece_area = st_area(geometry)) %>%
  left_join(tract_areas, by = "GEOID") %>%
  mutate(
    weight = as.numeric(piece_area / tract_area),
    
    total_pop_w      = total_pop * weight,
    male_10_15_w     = male_10_15 * weight,
    male_16_24_w     = male_16_24 * weight,
    female_10_15_w   = female_10_15 * weight,
    female_16_24_w   = female_16_24 * weight
  )

# -------------------------------------------
# 9) Summarize to GRYD zone with TOTAL POPULATION AND ALL PERCENTAGES
# -------------------------------------------
gryd_demo <- tract_split %>%
  st_drop_geometry() %>%
  group_by(GRZ807_ID, NAME) %>%
  summarise(
    total_pop    = sum(total_pop_w, na.rm = TRUE),
    male_10_15   = sum(male_10_15_w, na.rm = TRUE),
    male_16_24   = sum(male_16_24_w, na.rm = TRUE),
    female_10_15 = sum(female_10_15_w, na.rm = TRUE),
    female_16_24 = sum(female_16_24_w, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # Calculate totals
    total_10_15 = male_10_15 + female_10_15,
    total_16_24 = male_16_24 + female_16_24,
    total_youth = total_10_15 + total_16_24,
    
    # CALCULATE ALL PERCENTAGES (each demographic group as % of total population)
    pct_male_10_15   = (male_10_15 / total_pop) * 100,
    pct_male_16_24   = (male_16_24 / total_pop) * 100,
    pct_female_10_15 = (female_10_15 / total_pop) * 100,
    pct_female_16_24 = (female_16_24 / total_pop) * 100,
    pct_10_15        = (total_10_15 / total_pop) * 100,
    pct_16_24        = (total_16_24 / total_pop) * 100,
    pct_youth_total  = (total_youth / total_pop) * 100
  ) %>%
  # Round for clean reporting
  mutate(
    across(
      c(total_pop, male_10_15, male_16_24,
        female_10_15, female_16_24,
        total_10_15, total_16_24, total_youth),
      ~ round(.x)
    ),
    across(
      c(pct_male_10_15, pct_male_16_24, pct_female_10_15, pct_female_16_24,
        pct_10_15, pct_16_24, pct_youth_total),
      ~ round(.x, 1)
    )
  ) %>%
  arrange(NAME)

# -------------------------------------------
# 10) Join back to GRYD polygons for mapping
# -------------------------------------------
gryd_demo_sf <- gryd %>%
  left_join(gryd_demo, by = c("GRZ807_ID", "NAME"))

# -------------------------------------------
# 11) Saving outputs
# -------------------------------------------
write.csv(gryd_demo, 
          "gryd_demographics_FULL_with_percentages_acs5_2022_new.csv", 
          row.names = FALSE)

st_write(gryd_demo_sf, 
         "gryd_demo_sf_FULL_with_percentages_new.gpkg", 
         delete_dsn = TRUE)

# -------------------------------------------
# 12) View final table
# -------------------------------------------
gryd_demo

# -------------------------------------------
# 13) Create comprehensive summary table for reporting
# -------------------------------------------
gryd_demo_report <- gryd_demo %>%
  select(
    NAME, 
    total_pop,
    
    # Counts
    male_10_15, male_16_24,
    female_10_15, female_16_24,
    total_10_15, total_16_24, total_youth,
    
    # Percentages
    pct_male_10_15, pct_male_16_24,
    pct_female_10_15, pct_female_16_24,
    pct_10_15, pct_16_24, pct_youth_total
  ) %>%
  arrange(desc(total_youth))

gryd_demo_report

# Save comprehensive report version
write.csv(gryd_demo_report, 
          "gryd_demographics_FULL_REPORT_with_percentages_new.csv", 
          row.names = FALSE)

# -------------------------------------------
# 14) Print summary statistics
# -------------------------------------------
cat("\n=== SUMMARY STATISTICS ===\n\n")

cat("Total population across all GRYD zones:", 
    format(sum(gryd_demo$total_pop), big.mark = ","), "\n")

cat("Total youth (10-24) across all GRYD zones:", 
    format(sum(gryd_demo$total_youth), big.mark = ","), "\n")

cat("Overall % youth:", 
    round((sum(gryd_demo$total_youth) / sum(gryd_demo$total_pop)) * 100, 1), "%\n\n")

cat("Range of % youth across zones:\n")
cat("  Minimum:", round(min(gryd_demo$pct_youth_total), 1), "% (", 
    gryd_demo$NAME[which.min(gryd_demo$pct_youth_total)], ")\n")
cat("  Maximum:", round(max(gryd_demo$pct_youth_total), 1), "% (", 
    gryd_demo$NAME[which.max(gryd_demo$pct_youth_total)], ")\n")
cat("  Mean:", round(mean(gryd_demo$pct_youth_total), 1), "%\n")
cat("  Median:", round(median(gryd_demo$pct_youth_total), 1), "%\n\n")

cat("Gender distribution (overall):\n")
cat("  Male 10-15:", round((sum(gryd_demo$male_10_15) / sum(gryd_demo$total_10_15)) * 100, 1), "%\n")
cat("  Female 10-15:", round((sum(gryd_demo$female_10_15) / sum(gryd_demo$total_10_15)) * 100, 1), "%\n")
cat("  Male 16-24:", round((sum(gryd_demo$male_16_24) / sum(gryd_demo$total_16_24)) * 100, 1), "%\n")
cat("  Female 16-24:", round((sum(gryd_demo$female_16_24) / sum(gryd_demo$total_16_24)) * 100, 1), "%\n")

cat("\n=== FILES CREATED ===\n")
cat("1. gryd_demographics_FULL_with_percentages_acs5_2022_new.csv\n")
cat("2. gryd_demo_sf_FULL_with_percentages_new.gpkg\n")
cat("3. gryd_demographics_FULL_REPORT_with_percentages_new.csv\n")
