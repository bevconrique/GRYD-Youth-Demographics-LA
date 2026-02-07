# -------------------------------------------
# Interactive Map with TOGGLEABLE LAYERS
# Switch between % youth and total counts on same map
# -------------------------------------------

library(tidyverse)
library(sf)
library(leaflet)
library(htmltools)
library(viridis)

# -------------------------------------------
# Load the spatial data with full demographics
# -------------------------------------------
gryd_demo_sf <- st_read("gryd_demo_sf_FULL_with_percentages_new.gpkg")
gryd_demo_sf <- st_transform(gryd_demo_sf, 4326)

# -------------------------------------------
# Create color palettes
# -------------------------------------------
pal_pct <- colorNumeric(
  palette = "YlOrRd",
  domain = gryd_demo_sf$pct_youth_total
)

pal_counts <- colorNumeric(
  palette = "viridis",
  domain = gryd_demo_sf$total_youth
)

pal_gender <- colorNumeric(
  palette = "RdBu",
  domain = c(45, 55),
  reverse = TRUE
)

# Calculate gender metric if not already there
if(!"pct_male_of_youth" %in% names(gryd_demo_sf)) {
  gryd_demo_sf <- gryd_demo_sf %>%
    mutate(
      total_male_youth = male_10_15 + male_16_24,
      pct_male_of_youth = (total_male_youth / total_youth) * 100
    )
}

# -------------------------------------------
# Create detailed popup labels
# -------------------------------------------
labels <- sprintf(
  "<strong style='font-size:14px;'>%s</strong><br/>
  <hr style='margin:8px 0; border-top:2px solid #666;'>
  
  <table style='width:100%%; border-collapse:collapse;'>
    <tr style='background-color:#f0f0f0;'>
      <td colspan='3' style='padding:4px; font-weight:bold;'>POPULATION OVERVIEW</td>
    </tr>
    <tr>
      <td style='padding:4px;'>Total Population:</td>
      <td style='padding:4px; text-align:right;'><strong>%s</strong></td>
      <td></td>
    </tr>
    <tr>
      <td style='padding:4px;'>Youth (10-24):</td>
      <td style='padding:4px; text-align:right;'><strong>%s</strong></td>
      <td style='padding:4px; text-align:right; color:#d73027; font-weight:bold;'>%.1f%%</td>
    </tr>
  </table>
  
  <hr style='margin:8px 0; border-top:1px solid #ccc;'>
  
  <table style='width:100%%; border-collapse:collapse;'>
    <tr style='background-color:#D5E8F0;'>
      <td colspan='3' style='padding:4px; font-weight:bold;'>AGES 10-15</td>
    </tr>
    <tr>
      <td style='padding:4px;'>Male:</td>
      <td style='padding:4px; text-align:right;'>%s</td>
      <td style='padding:4px; text-align:right; color:#4575b4;'>%.1f%%</td>
    </tr>
    <tr>
      <td style='padding:4px;'>Female:</td>
      <td style='padding:4px; text-align:right;'>%s</td>
      <td style='padding:4px; text-align:right; color:#d73027;'>%.1f%%</td>
    </tr>
    <tr style='background-color:#f5f5f5;'>
      <td style='padding:4px;'><strong>Total 10-15:</strong></td>
      <td style='padding:4px; text-align:right;'><strong>%s</strong></td>
      <td style='padding:4px; text-align:right;'><strong>%.1f%%</strong></td>
    </tr>
  </table>
  
  <hr style='margin:8px 0; border-top:1px solid #ccc;'>
  
  <table style='width:100%%; border-collapse:collapse;'>
    <tr style='background-color:#FFE6D5;'>
      <td colspan='3' style='padding:4px; font-weight:bold;'>AGES 16-24</td>
    </tr>
    <tr>
      <td style='padding:4px;'>Male:</td>
      <td style='padding:4px; text-align:right;'>%s</td>
      <td style='padding:4px; text-align:right; color:#4575b4;'>%.1f%%</td>
    </tr>
    <tr>
      <td style='padding:4px;'>Female:</td>
      <td style='padding:4px; text-align:right;'>%s</td>
      <td style='padding:4px; text-align:right; color:#d73027;'>%.1f%%</td>
    </tr>
    <tr style='background-color:#f5f5f5;'>
      <td style='padding:4px;'><strong>Total 16-24:</strong></td>
      <td style='padding:4px; text-align:right;'><strong>%s</strong></td>
      <td style='padding:4px; text-align:right;'><strong>%.1f%%</strong></td>
    </tr>
  </table>",
  
  gryd_demo_sf$NAME,
  format(gryd_demo_sf$total_pop, big.mark = ","),
  format(gryd_demo_sf$total_youth, big.mark = ","),
  gryd_demo_sf$pct_youth_total,
  format(round(gryd_demo_sf$male_10_15), big.mark = ","),
  gryd_demo_sf$pct_male_10_15,
  format(round(gryd_demo_sf$female_10_15), big.mark = ","),
  gryd_demo_sf$pct_female_10_15,
  format(gryd_demo_sf$total_10_15, big.mark = ","),
  gryd_demo_sf$pct_10_15,
  format(round(gryd_demo_sf$male_16_24), big.mark = ","),
  gryd_demo_sf$pct_male_16_24,
  format(round(gryd_demo_sf$female_16_24), big.mark = ","),
  gryd_demo_sf$pct_female_16_24,
  format(gryd_demo_sf$total_16_24, big.mark = ","),
  gryd_demo_sf$pct_16_24
) %>% 
  lapply(htmltools::HTML)

# -------------------------------------------
# Create ONE map with LAYER CONTROLS
# -------------------------------------------
map_combined <- leaflet(gryd_demo_sf) %>%
  addProviderTiles(providers$CartoDB.Positron, group = "Base Map") %>%
  
  # LAYER 1: Youth as % of population (default visible)
  addPolygons(
    fillColor = ~pal_pct(pct_youth_total),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7,
    group = "Youth % (Concentration)",
    highlightOptions = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "8px"),
      textsize = "12px",
      direction = "auto"
    )
  ) %>%
  
  # LAYER 2: Total youth counts
  addPolygons(
    fillColor = ~pal_counts(total_youth),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7,
    group = "Youth Count (Total Numbers)",
    highlightOptions = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "8px"),
      textsize = "12px",
      direction = "auto"
    )
  ) %>%
  
  # LAYER 3: Gender balance
  addPolygons(
    fillColor = ~pal_gender(pct_male_of_youth),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7,
    group = "Gender Balance",
    highlightOptions = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "8px"),
      textsize = "12px",
      direction = "auto"
    )
  ) %>%
  
  # Add layer control widget FIRST (before legends)
  addLayersControl(
    baseGroups = c("Youth % (Concentration)", "Youth Count (Total Numbers)", "Gender Balance"),
    options = layersControlOptions(collapsed = FALSE),
    position = "topleft"
  ) %>%
  
  # Add legends WITHOUT layerId - we'll use position/order instead
  addLegend(
    pal = pal_pct,
    values = ~pct_youth_total,
    opacity = 0.7,
    title = "Youth as %<br/>of Total Pop",
    position = "bottomright",
    labFormat = labelFormat(suffix = "%"),
    className = "legend-youth-pct"
  ) %>%
  
  addLegend(
    pal = pal_counts,
    values = ~total_youth,
    opacity = 0.7,
    title = "Total Youth<br/>(Ages 10-24)",
    position = "bottomright",
    labFormat = labelFormat(big.mark = ","),
    className = "legend-youth-counts"
  ) %>%
  
  addLegend(
    pal = pal_gender,
    values = ~pct_male_of_youth,
    opacity = 0.7,
    title = "Male %<br/>of Youth",
    position = "bottomright",
    labFormat = labelFormat(suffix = "%"),
    className = "legend-gender"
  ) %>%
  
  # Add title
  addControl(
    html = "<div style='background-color:white; padding:12px; border-radius:5px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);'>
            <h4 style='margin:0 0 8px 0;'>GRYD Zones: Youth Demographics</h4>
            <p style='margin:0; font-size:12px; color:#666;'>
            👈 Use the layer selector to switch views<br/>
            Click zones for detailed breakdown</p>
            </div>",
    position = "topright"
  ) %>%
  
  # Control legend visibility based on active layer
  htmlwidgets::onRender("
    function(el, x) {
      var map = this;
      
      // Function to show only the appropriate legend
      function updateLegends(layerName) {
        // Get legends by their custom class names
        var legendPct = document.querySelector('.legend-youth-pct');
        var legendCounts = document.querySelector('.legend-youth-counts');
        var legendGender = document.querySelector('.legend-gender');
        
        // Hide all legends first
        if (legendPct) legendPct.style.display = 'none';
        if (legendCounts) legendCounts.style.display = 'none';
        if (legendGender) legendGender.style.display = 'none';
        
        // Show the appropriate legend based on layer name
        if (layerName === 'Youth % (Concentration)' && legendPct) {
          legendPct.style.display = 'block';
          console.log('Showing Youth % legend');
        } else if (layerName === 'Youth Count (Total Numbers)' && legendCounts) {
          legendCounts.style.display = 'block';
          console.log('Showing Youth Count legend');
        } else if (layerName === 'Gender Balance' && legendGender) {
          legendGender.style.display = 'block';
          console.log('Showing Gender legend');
        }
      }
      
      // Set initial state after DOM loads
      setTimeout(function() {
        console.log('Initializing legends...');
        updateLegends('Youth % (Concentration)');
      }, 500);
      
      // Listen for layer changes
      map.on('baselayerchange', function(e) {
        console.log('Layer changed to: ' + e.name);
        updateLegends(e.name);
      });
    }
  ")

# Display the map
map_combined

# Save it
library(htmlwidgets)
saveWidget(map_combined, "gryd_youth_COMBINED_map.html", selfcontained = TRUE)

cat("\n=== SUCCESS ===\n\n")
cat("Created: gryd_youth_COMBINED_map.html\n\n")
cat("This single map includes:\n")
cat("  ✓ Youth % (concentration) - DEFAULT VIEW\n")
cat("  ✓ Youth Count (total numbers)\n")
cat("  ✓ Gender Balance\n\n")
cat("Use the layer selector in the top-left corner to switch between views!\n")
cat("The legend automatically updates to match the active layer.\n\n")
cat("Open gryd_youth_COMBINED_map.html in your browser to explore.\n")
