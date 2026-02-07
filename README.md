# GRYD Youth Demographics Analysis

Interactive demographic analysis of youth population (ages 10-24) across Gang Reduction and Youth Development (GRYD) zones in Los Angeles, California.

## Overview

This project provides spatial demographic analysis of youth populations across GRYD service zones using U.S. Census data. It generates interactive maps and comprehensive reports showing both absolute counts and concentration rates to support program planning and resource allocation decisions.

## Key Features

- **Interactive Web Maps** with toggleable layers showing:
  - Youth population counts (absolute numbers)
  - Youth concentration (% of total population)
  - Gender balance across zones
  
- **Detailed Demographic Breakdowns** by:
  - Age groups (10-15 and 16-24)
  - Gender (male and female)
  - Geographic zone (23 GRYD zones)

- **Dual Perspective Analysis**:
  - Raw population counts for capacity planning
  - Percentage metrics for concentration analysis

## Repository Contents

```
├── final demos code.R    # Main analysis script
├── final map code.R                   # Combined interactive map (recommended)
├── gryd_youth_COMBINED_map.html                 # Interactive map output
└── README.md                                     # This file
```

## Quick Start

### Prerequisites

```r
# Required R packages
install.packages(c(
  "tidyverse",
  "sf",
  "tidycensus",
  "leaflet",
  "htmltools",
  "viridis",
  "htmlwidgets"
))
```

### Setup

1. **Get a Census API Key** (free):
   - Register at https://api.census.gov/data/key_signup.html
   - Add to your R environment or update the key in the script

2. **Run the Analysis**:
   ```r
   source("final demos code.R")
   ```
   This will:
   - Pull census data for LA County
   - Aggregate to GRYD zones using area-weighted interpolation
   - Calculate counts and percentages
   - Generate output files (.csv and .gpkg)

3. **Create the Interactive Map**:
   ```r
   source("final map code.R")
   ```
   Opens `gryd_youth_COMBINED_map.html` in your browser

## Data Sources

- **Census Data**: U.S. Census Bureau, American Community Survey (ACS) 5-Year Estimates, 2018-2022
  - Geography: Census tracts, Los Angeles County, California
  - Variables: Table B01001 (Sex by Age)

- **GRYD Zone Boundaries**: City of Los Angeles GRYD program
  - Source: ArcGIS FeatureServer (gryd116)
  - URL: https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/gryd116/FeatureServer/0

##  Using the Interactive Map

### Accessing the Map
Open `gryd_youth_COMBINED_map.html` in any modern web browser (Chrome, Firefox, Safari, Edge).

### Map Controls

**Layer Selector (Top Left)**
- **Youth % (Concentration)** - Shows zones by youth concentration (% of total population)
- **Youth Count (Total Numbers)** - Shows zones by absolute youth population
- **Gender Balance** - Shows male/female distribution

**Click Any Zone** to see detailed popup with:
- Total population and youth count
- Youth as percentage of total population
- Age breakdown (10-15 and 16-24) with counts and percentages
- Gender breakdown by age group

**Legend (Bottom Right)**
- Automatically updates based on selected layer
- Shows color scale for the active metric

### When to Use Each View

**Count View** → Answers:
- Where should we deploy the most staff?
- Which zones need the greatest program capacity?
- Where are the absolute numbers highest?

**Percentage View** → Answers:
- Which zones have the highest youth density?
- Where do youth make up the largest share of the population?
- Which zones might need more intensive per-capita services?

## Output Files

### CSV Files
- `gryd_demographics_FULL_with_percentages_acs5_2022_new.csv` - Complete dataset with all metrics
- `gryd_demographics_FULL_REPORT_with_percentages_new.csv` - Sorted by total youth (highest to lowest)

### Spatial Data
- `gryd_demo_sf_FULL_with_percentages_new.gpkg` - GeoPackage with zone boundaries and demographics (for GIS software)

### Interactive Map
- `gryd_youth_COMBINED_map.html` - Single map with toggleable layers (recommended)

## Methodology

### Age Group Construction

Census age categories are aggregated into two custom groups:

**Ages 10-15:**
- All individuals aged 10-14
- Approximately 1/3 of individuals aged 15-17

**Ages 16-24:**
- Approximately 2/3 of individuals aged 15-17
- All individuals aged 18-19, 20, 21, and 22-24

### Spatial Aggregation

Census tract data is aggregated to GRYD zones using area-weighted interpolation:

1. Census tracts are spatially intersected with GRYD zone boundaries
2. For each tract-zone overlap, a weight is calculated: `weight = (overlap area) / (total tract area)`
3. Population counts are allocated proportionally: `zone population = Σ (tract population × weight)`

**Assumption**: Population is evenly distributed within census tracts.

### Percentage Calculations

All percentages represent demographic groups as a proportion of total zone population:

```
% Youth = (youth count / total population) × 100
```

This allows comparison of youth concentration across zones of different sizes.

## Limitations

- **Margins of Error**: ACS estimates include uncertainty not reflected in point estimates
- **Spatial Assumptions**: Area-weighting assumes uniform population distribution within tracts
- **Age Approximation**: Splitting 15-17 age group assumes equal representation
- **Temporal Coverage**: 2018-2022 data represents a five-year average
- **Small Populations**: Zones with small populations may show larger percentage variations

## Key Findings

- **Population Range**: Youth populations range from ~7,500 (77th3) to ~26,300 (Harbor)
- **Concentration Variation**: Youth concentration varies from 22.1% to 25.6% across zones
- **Age Distribution**: 16-24 year-olds outnumber 10-15 year-olds in all zones (average ratio ~2:1)
- **Gender Balance**: Males and females are approximately evenly distributed (50/50) across all zones

## Customization

### Update Census Year
```r
# In final demos code.R
year_acs <- 2023  # Change to desired year
```

### Modify GRYD Zone Source
```r
# In final demos code.R
gryd_url <- "your_custom_url_here"
```

### Change Map Color Schemes
```r
# In final map code.R
pal_pct <- colorNumeric(
  palette = "YlOrRd",  # Change to desired palette
  domain = gryd_demo_sf$pct_youth_total
)
```

Available palettes: `viridis`, `magma`, `inferno`, `plasma`, `Blues`, `Greens`, `Reds`, `YlOrRd`, `RdYlBu`, etc.

## Citation

If you use this code or methodology, please cite:

```
Youth Demographics Analysis for GRYD Zones, Los Angeles
Data: U.S. Census Bureau, American Community Survey 5-Year Estimates (2018-2022)
GRYD Zones: City of Los Angeles Gang Reduction and Youth Development Program
```

## Contributing

Contributions are welcome! Areas for improvement:

- Add additional demographic variables (race/ethnicity, income, education)
- Incorporate school enrollment data for validation
- Add temporal analysis (trend over multiple ACS years)
- Include confidence intervals from ACS margins of error
- Add statistical significance testing for zone comparisons

## Contact

Questions or feedback? Open an issue in this repository.

## License

This code is provided for public use. Census data is public domain. GRYD zone boundaries are provided by the City of Los Angeles.

## Acknowledgments

- U.S. Census Bureau for ACS data via the `tidycensus` package
- City of Los Angeles GRYD program for zone boundary data
- R for excellent geospatial and visualization packages

---

**Note**: This analysis is for planning and research purposes. Population estimates include uncertainty and should be used in conjunction with other data sources for decision-making.
