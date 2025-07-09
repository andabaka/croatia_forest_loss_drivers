# Croatia Forest Loss Drivers (2001-2022)


![](croatia_forest_drivers_with_author.png)

<br>

This repository contains R code for analyzing and visualizing the dominant drivers of forest loss across Croatia using the WRI/Google DeepMind Global Drivers of Forest Loss dataset - a 1km resolution global map that classifies the direct causes of tree cover loss from 2001-2022.

## Overview

The Global Drivers of Forest Loss dataset represents a major advancement in understanding deforestation patterns worldwide. This project creates a detailed 3D visualization of Croatia's forest loss drivers using:

- **Google Earth Engine** for accessing the global drivers dataset
- **WRI/Google DeepMind classification** providing AI-powered driver attribution at 1km resolution
- **R & Rayshader** for statistical analysis and 3D terrain visualization
- **High-resolution elevation data** for realistic topographic representation

## Key Features

- **Comprehensive Driver Analysis**: Seven distinct categories of forest loss causes
- **High Spatial Resolution**: 1km grid cells providing detailed landscape patterns
- **3D Terrain Visualization**: Elevation-enhanced maps showing geographic context
- **Quantitative Results**: Area calculations and statistical summaries for each driver

## WRI/Google DeepMind Dataset

The Global Drivers of Forest Loss dataset classifies tree cover loss into seven categories based on interpretation of nearly 6,959 reference samples and training of a global neural network model. The classification achieves an overall accuracy of **90.5% ± 1.4%** globally, with **93.8% ± 3.1%** accuracy for Europe.

### Forest Loss Driver Categories

The analysis uses seven driver classifications representing the **dominant cause** of tree cover loss within each 1km grid cell:

1. **Permanent Agriculture** - Long-term conversion to crops, pasture, or tree plantations
2. **Hard Commodities** - Mining, energy infrastructure, and hydroelectric projects
3. **Shifting Cultivation** - Temporary clearing followed by forest regrowth
4. **Logging** - Forest management and timber harvesting operations
5. **Wildfire** - Fire-related tree cover loss (natural or human-caused)
6. **Settlements & Infrastructure** - Urban expansion and road development
7. **Other Natural Disturbances** - Storms, floods, landslides, and insect outbreaks

**Learn more:** [Global Forest Watch](https://www.globalforestwatch.org/) | [Research Paper](https://doi.org/10.1088/1748-9326/add606)

## Methodology

### 1. Data Acquisition
```r
# Load the global drivers dataset from Google Earth Engine
drivers_dataset <- ee$Image("projects/landandcarbon/assets/wri_gdm_drivers_forest_loss_1km/v1_2001_2022")

# Select classification band and clip to Croatia
drivers_classification <- drivers_dataset$select("classification")
drivers_croatia <- drivers_classification$clip(croatia)
2. Spatial Processing
r# Align elevation data with drivers grid
drivers_croatia_aligned <- terra::resample(
    x = drivers_croatia_cropped,
    y = dem_raw,
    method = "near"
)
3. 3D Visualization
r# Create main visualization layer
main_map <- ggplot(drivers_df, aes(x = x, y = y, fill = driver_label)) +
    geom_raster(interpolate = TRUE) +
    scale_fill_manual(values = driver_colors, na.value = "transparent")

# Generate 3D terrain visualization
rayshader::plot_gg(
    ggobj = main_map,
    ggobj_height = dem_map,
    scale = 250,
    shadow = TRUE
)
Quick Start
Prerequisites

Google Earth Engine account (Sign up here)
R with required packages: rgee, terra, sf, rayshader, ggplot2

Installation & Setup
r# Install packages
install.packages(c("rgee", "terra", "sf", "geodata", "elevatr",
                   "ggplot2", "rayshader", "magick", "dplyr"))

# Initialize Google Earth Engine
library(rgee)
ee_Initialize()
Run Analysis
r# Source the main script
source("croatia_forest_drivers_analysis.R")

# Execute complete workflow (export → process → visualize)
export_drivers_data()  # Export from GEE
# ... download file manually ...
# Run visualization pipeline


## Key Findings (2001-2022)

| Driver Category | Area Coverage |
|----------------|---------------|
| **Logging** | **70.6%** |
| **Settlements & Infrastructure** | **10.3%** |
| **Wildfire** | **7.2%** |
| **Permanent Agriculture** | **5.7%** |
| **Hard Commodities** | **1.5%** |
| **Other Natural Disturbances** | **0.4%** |

Regional Context
Croatia's forest loss pattern differs significantly from the global average, where permanent agriculture dominates (34.8% globally). The predominance of logging (70.6%) reflects Croatia's active forest management sector and sustainable forestry practices.
Technical Details
Data Sources

Forest Loss Drivers: projects/landandcarbon/assets/wri_gdm_drivers_forest_loss_1km/v1_2001_2022
Administrative Boundaries: USDOS/LSIB_SIMPLE/2017
Elevation Data: FABDEM via elevatr package
Base Forest Data: Hansen et al. Global Forest Change v1.10

Processing Specifications

Analysis Resolution: 1km (native dataset resolution)
Temporal Coverage: 2001-2022 (22-year cumulative analysis)
Geographic Extent: Croatia national boundary
Output Resolution: 3200x3200 pixels for publication

Workflow Overview

Initialize Google Earth Engine and define Croatia boundary
Export driver classification from GEE to Google Drive
Download and process raster data with administrative boundaries
Align spatial data between drivers and elevation datasets
Create color-coded visualization with distinct driver categories
Generate 3D terrain map using rayshader with professional lighting
Compose final output with legend and attribution

Data Limitations

Temporal scope: Represents cumulative forest loss from 2001-2022
Spatial resolution: 1km grid cells may not capture small-scale disturbances
Dominant driver only: Shows the primary cause of loss within each cell
Forest definition: Based on Hansen et al. tree cover product (>5m height threshold)

Contributing
Contributions welcome! Please feel free to submit issues, fork the repository, and create pull requests.
Citations
Primary Dataset: Sims, M.J., Stanimirova, R., Raichuk, A., et al. (2025). Global drivers of forest loss at 1 km resolution. Environmental Research Letters, 20, 074027.
Base Forest Data: Hansen, M.C., et al. (2013). High-resolution global maps of 21st-century forest cover change. Science, 342, 850-853.
License
MIT License - see LICENSE file for details.
Contact
Author: Marijana Andabaka
Email: marijana@andalytics.com
Website: andalytics.com
LinkedIn: marijana-andabaka

Need Advanced Forest Data Science?
I help research organizations transform their data workflows from manual to automated, providing comprehensive services from statistical analysis and modeling to spatial data integration and advanced visualizations. If you're spending days on data collection and processing instead of focusing on analysis and insights, let's talk about how custom R solutions can streamline your research pipeline.
My clients typically see:

90% reduction in data processing time
Improved accuracy through automated workflows
Rigorous statistical insights that strengthen research conclusions
Reproducible analyses that scale across projects
