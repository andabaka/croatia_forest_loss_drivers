# ========================================================================================
# CROATIA FOREST LOSS DRIVERS - WRI/Google DeepMind Global Drivers of Forest Loss dataset
# ========================================================================================

# 1. PACKAGE SETUP
# ================
library(rgee)
library(terra)
library(sf)
library(geodata)
library(elevatr)
library(ggplot2)
library(rayshader)
library(magick)
library(dplyr)

main_dir <- getwd()

# 2. INITIALIZE GOOGLE EARTH ENGINE
# =================================
ee_Initialize()

# Define Croatia boundary
croatia <- ee$FeatureCollection("USDOS/LSIB_SIMPLE/2017")$
    filter(ee$Filter$eq("country_na", "Croatia"))

# 3. FOREST LOSS DRIVERS DATA EXTRACTION
# ======================================

# Load the drivers dataset
drivers_dataset <- ee$Image("projects/landandcarbon/assets/wri_gdm_drivers_forest_loss_1km/v1_2001_2022")

# Select classification band
drivers_classification <- drivers_dataset$select("classification")

# Clip to Croatia boundaries
drivers_croatia <- drivers_classification$clip(croatia)


# 4. EXPORT DATA
# ==============
export_drivers_data <- function() {
    # Export drivers classification
    task <- ee$batch$Export$image$toDrive(
        image = drivers_croatia,
        description = "croatia_forest_drivers_2001_2022",
        folder = "Earth_Engine_Exports",
        fileNamePrefix = "croatia_drivers_classification",
        scale = 1000,  # 1km resolution
        region = croatia$geometry()$bounds(),
        maxPixels = 1e9
    )
    task$start()

}

# Run export
export_drivers_data()

# Monitor at: https://code.earthengine.google.com/tasks
# Download the file and place it in your working directory as 'croatia_drivers_classification.tif


# 5. LOAD AND PREPARE DATA (AFTER DOWNLOAD)
# =========================================
# Run this section after downloading from Google Drive

# Load the drivers classification
drivers_raster <- rast("croatia_drivers_classification.tif")
plot(drivers_raster)


# 6. ADMINISTRATIVE BOUNDARIES AND ELEVATION DATA
# ===============================================

# Get Croatia administrative boundaries
croatia_sf <- geodata::gadm(
    country = "HRV",
    level = 0,
    path = main_dir
) |> sf::st_as_sf()

# Use WGS84 geographic coordinate system
target_crs <- "EPSG:4326"

# Obtain high-resolution elevation data
dem_raw <- elevatr::get_elev_raster(
    locations = croatia_sf,
    z = 9,
    clip = "locations"
) |>
    terra::rast() |>
    terra::crop(croatia_sf, mask = TRUE) |>
    terra::project(target_crs)



# 7. ACHIEVING SPATIAL ALIGNMENT
# ==============================

# Crop drivers data to Croatia boundaries first
drivers_croatia_cropped <- terra::crop(drivers_raster, croatia_sf, mask = TRUE)

# Resample DEM to match drivers grid
# This preserves the 1km resolution of drivers dataset
drivers_croatia_aligned <- terra::resample(
    x = drivers_croatia_cropped,
    y = dem_raw,
    method = "near"
) |> terra::project(target_crs)



# 8. TRANSFORM DATA FOR VISUALIZATION
# ===================================

# Transform forest drivers data into dataframe
drivers_df <- as.data.frame(
    drivers_croatia_aligned,
    xy = TRUE,
    na.rm = TRUE
)
names(drivers_df)[3] <- "driver_type"


# Create labels for driver categories
drivers_df$driver_label <- factor(
    drivers_df$driver_type,
    levels = c(0, 1, 2, 3, 4, 5, 6, 7),
    labels = c("No Loss","Permanent Agriculture", "Hard Commodities", "Shifting Cultivation",
               "Logging", "Wildfire", "Settlements & Infrastructure", "Other Natural Disturbances")
)

# Prepare elevation data for height mapping
dem_df <- dem_raw |>
    as.data.frame(xy = TRUE, na.rm = TRUE)
names(dem_df)[3] <- "elevation"



# 9. DEFINE COLORS FOR DRIVER CATEGORIES
# ======================================

# Colors for forest loss drivers (categories 1-7 only)
driver_colors <- c(
    "No Loss" = "#E6D7C3",
    "Permanent Agriculture" = "#E39D29",
    "Hard Commodities" = "#E58074",
    "Shifting Cultivation" = "#E9D700",
    "Logging" = "#51A44E",
    "Wildfire" = "#895128",
    "Settlements & Infrastructure" = "#A354A0",
    "Other Natural Disturbances" = "#3A209A"
)

# 10. CREATE MAPS
# ===============

# Main drivers map for 3D visualization
main_map <- ggplot(drivers_df, aes(x = x, y = y, fill = driver_label)) +
    geom_raster(interpolate = TRUE) +
    scale_fill_manual(values = driver_colors, na.value = "transparent") +
    coord_sf(crs = target_crs, expand = FALSE) +
    theme_void() +
    theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        legend.position = "none",
        plot.margin = unit(c(0, 0, 0, 0), "lines")
    )

# Elevation map for height mapping
dem_map <- ggplot(dem_df, aes(x = x, y = y, fill = elevation)) +
    geom_raster(interpolate = TRUE) +
    scale_fill_gradientn(colors = "white") +
    guides(fill = "none") +
    coord_sf(crs = target_crs, expand = FALSE) +
    theme_void() +
    theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        legend.position = "none"
    )



# 11. CREATE 3D VISUALIZATION
# ===========================

options(rgl.useNULL = FALSE)

rayshader::plot_gg(
    ggobj = main_map,
    ggobj_height = dem_map,
    width = 9,
    height = 9,
    windowsize = c(900, 900),
    scale = 250,
    shadow = TRUE,
    shadow_intensity = 0.7,
    phi = 87,
    theta = 0,
    zoom = 0.6,
    multicore = TRUE,
    background = "white"
)



# 12. DOWNLOAD LIGHTING
# =====================
hdri_url <- "https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/4k/brown_photostudio_02_4k.hdr"
hdri_file <- "lighting.hdr"

if (!file.exists(hdri_file)) {
    try(download.file(
        url = hdri_url,
        destfile = hdri_file,
        mode = "wb"
    ))
}

# 13. RENDER HIGH-QUALITY IMAGE
# =============================


rayshader::render_highquality(
    filename = "croatia_forest_drivers.png",
    preview = FALSE,
    light = FALSE,
    environment_light = hdri_file,
    intensity = 1,
    rotate_env = 90,
    parallel = TRUE,
    width = 3200,
    height = 3200,
    samples = 200,
    interactive = FALSE
)


# 14. CREATE LEGEND
# =================

dummy_data <- data.frame(
    x = 1:7,
    y = 1,
    category = factor(
        c("Settlements & Infrastructure", "Other Natural Disturbances", "Permanent Agriculture",
          "Hard Commodities", "Shifting Cultivation", "Logging", "Wildfire"),
        levels = c("Settlements & Infrastructure", "Other Natural Disturbances", "Permanent Agriculture",
                   "Hard Commodities", "Shifting Cultivation", "Logging", "Wildfire")
    )
)

legend_plot <- ggplot(dummy_data, aes(x = x, y = y, fill = category)) +
    geom_tile() +
    scale_fill_manual(
        values = driver_colors,
        name = "Forest Loss Drivers"
    ) +
    theme_void() +
    theme(
        legend.position = "left",
        legend.title = element_text(size = 18, face = "bold"),
        legend.text = element_text(size = 13),
        legend.key.size = unit(1, "cm"),
        plot.background = element_rect(fill = NA, color = NA),
        panel.background = element_rect(fill = NA, color = NA),
        legend.background = element_rect(fill = NA, color = NA),
        plot.margin = margin(20, 20, 20, 20)
    ) +
    guides(fill = guide_legend(
        title.position = "top",
        title.hjust = 0.5,
        ncol = 1
    )) +
    xlim(0, 0) + ylim(0, 0)

# Save legend
ggsave("drivers_legend.png", plot = legend_plot, width = 6, height = 8, dpi = 300, bg = "transparent")


# 15. CREATE TITLE
# ================

title_plot <- ggplot() +
    theme_void() +
    theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(30, 30, 30, 30)
    ) +
    annotate(
        "text", x = 0.5, y = 0.75,
        label = "Croatia Forest Loss Drivers (2001-2022)",
        size = 13,
        fontface = "bold",
        color = "grey15",
        hjust = 0.5
    ) +
    annotate(
        "text", x = 0.5, y = 0.25,
        label = "WRI/Google DeepMind • 1km Resolution",
        size = 8,
        color = "grey35",
        hjust = 0.5
    ) +
    xlim(0, 1) + ylim(0, 1)

# Save title
ggsave("drivers_title.png", plot = title_plot, width = 10.67, height = 2, dpi = 300, bg = "white")

# 16. FINAL COMPOSITION
# =====================

# Load all components
main_img <- magick::image_read("croatia_forest_drivers.png")
legend_img <- magick::image_read("drivers_legend.png")
title_img <- magick::image_read("drivers_title.png")

# Resize legend
legend_resized <- magick::image_resize(legend_img, "1800x2000")

# Combine title with main image
img_with_title <- magick::image_append(c(title_img, main_img), stack = TRUE)

# Calculate positioning for legend
total_height <- 3200
legend_x <- 3200 - 1200
legend_y <- (total_height - 1000) / 2 + 180

# Create final composite
final_composite <- magick::image_composite(
    img_with_title,
    legend_resized,
    offset = paste0("+", legend_x, "+", legend_y),
    operator = "over"
)

# Save final result
magick::image_write(final_composite, "croatia_forest_drivers_final.png", quality = 200)

main_img <- magick::image_read("croatia_forest_drivers_final.png")


main_img_with_author <- magick::image_annotate(
    main_img,
    text = "Author: Marijana Andabaka, marijana@andalytics.com",
    size = 45,
    color = "grey25",
    weight = 400,
    gravity = "southwest",
    location = "+80+80"
)


magick::image_write(main_img_with_author, "croatia_forest_drivers_with_author.png", quality = 200)



# 17. Calculate Forest Loss Driver Statistics
# =======================================

# Extract driver values from raster
driver_values <- terra::values(drivers_croatia_aligned, na.rm = TRUE)
driver_counts <- table(driver_values)

# Separate no-data (category 0) from actual drivers (categories 1-7)
no_data_count <- if("0" %in% names(driver_counts)) driver_counts["0"] else 0
driver_counts_clean <- driver_counts[names(driver_counts) != "0"]

# Calculate pixel totals
total_pixels <- length(driver_values)
total_loss_pixels <- sum(driver_counts_clean)

# Calculate coverage percentages
no_data_pct <- round((no_data_count / total_pixels) * 100, 1)
loss_coverage_pct <- round((total_loss_pixels / total_pixels) * 100, 1)

# Define driver labels
driver_labels <- c(
    "1" = "Permanent Agriculture",
    "2" = "Hard Commodities",
    "3" = "Shifting Cultivation",
    "4" = "Logging",
    "5" = "Wildfire",
    "6" = "Settlements & Infrastructure",
    "7" = "Other Natural Disturbances"
)

# Calculate relative percentages within forest loss areas
driver_percentages <- numeric(7)
names(driver_percentages) <- 1:7

for(i in 1:7) {
    driver_key <- as.character(i)
    if(driver_key %in% names(driver_counts_clean)) {
        driver_percentages[i] <- round((driver_counts_clean[driver_key] / total_loss_pixels) * 100, 1)
    } else {
        driver_percentages[i] <- 0
    }
}

# Extract key driver percentages
logging_pct <- driver_percentages[4]
agriculture_pct <- driver_percentages[1]
wildfire_pct <- driver_percentages[5]
infrastructure_pct <- driver_percentages[6]
commodities_pct <- driver_percentages[2]
cultivation_pct <- driver_percentages[3]
other_pct <- driver_percentages[7]
