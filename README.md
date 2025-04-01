# 🌲 NEON LiDAR Forest Monitoring with R

This repository analyzes multi-temporal **Canopy Height Model (CHM)** data from the **National Ecological Observatory Network (NEON)** to detect forest structural changes over time at the **Bartlett Experimental Forest (BART)** site.

We use **processed CHM raster tiles** from 2019 and 2022 to assess **tree height change**, **canopy cover**, and **forest disturbance or recovery**.

---

##  What is LiDAR?

**LiDAR (Light Detection and Ranging)** is a remote sensing technique that uses laser pulses to generate 3D information about the Earth's surface.

NEON collects LiDAR data via aircraft and processes it into several products:
- **Point cloud (.LAZ)** – raw 3D laser returns
- **DTM (Digital Terrain Model)** – ground elevation
- **DSM (Digital Surface Model)** – top-of-everything elevation
- **CHM (Canopy Height Model)** – vegetation height above ground

---

##  Dataset Description

- **Dataset**: Ecosystem Structure – Canopy Height Model (CHM)  
- **Product ID**: `DP3.30015.001`  
- **Format**: Raster GeoTIFF (.tif)  
- **Resolution**: 1-meter  
- **Tile Size**: 1 km × 1 km  
- **Years Used**: 2019 and 2022  
- **Site**: BART (Bartlett Experimental Forest)  
- **Source**: [NEON Data Portal](https://data.neonscience.org)

> 🔁 Each CHM pixel represents **tree height (in meters)** above bare earth, calculated as:
>
> ```text
> CHM = DSM - DTM
> ```
> 
>** What are the CHM tiles?**
Each .tif file (like NEON_D01_BART_DP3_312000_4873000_CHM.tif) is a 1 km × 1 km raster tile of the Canopy Height Model for that location.
NEON's AOP (Airborne Observation Platform) flies over a site and collects data tile by tile.
Each tile has:
 - Spatial extent (xmin, xmax, ymin, ymax)
 - 1-meter resolution (i.e., 1000x1000 pixels)
 - Tree height values at each pixel
 - A coordinate reference system (UTM, usually)

---

## 🎯 Project Objectives

1. **Visualize Canopy Height Models** for 2019 and 2022
2. **Estimate Canopy Cover** (% of area with vegetation taller than threshold)
3. **Detect Forest Change** over time (growth or loss)
4. **Visualize Spatial Patterns** of canopy change
5. **Quantify Areas** with significant forest recovery or disturbance

---

## 🛠️ R Packages Used

- `neonUtilities` – download NEON AOP data
- `raster`, `terra` – raster data handling
- `lidR` – tree detection from CHM
- `ggplot2` – visualizations
- `rasterVis` – advanced raster plots
- `sf` – spatial data support

---

- **Dark Green** = Short vegetation or bare ground  
- **Yellow to Light Green** = Medium-height trees  
- **Brown/Pink** = Tall trees (30m+) 
<img width="678" alt="Screenshot 2025-02-24 at 19 44 30" src="https://github.com/user-attachments/assets/ea34a5ac-8ae1-4b9a-b662-3c4fbb96e6dd" />
<img width="686" alt="Screenshot 2025-02-24 at 19 40 09" src="https://github.com/user-attachments/assets/ae7a0b11-f062-4d03-82bd-59910706da23" />
 
 Tree Height distribution of the same plot
 
 <img width="618" alt="Screenshot 2025-02-24 at 19 45 51" src="https://github.com/user-attachments/assets/4a06b515-339a-4c9d-85d2-c1a249289972" />

## Canopy Cover Analysis
- **Canopy Cover in 2019:** 67.61%  
- **Canopy Cover in 2022:** 74.48%  

**Interpretation:**
- If Canopy Cover > 70%, it is classified as dense forest.  
- If Canopy Cover < 40%, it is classified as a fragmented forest or open woodland.
 
 <img width="685" alt="Screenshot 2025-02-24 at 19 50 43" src="https://github.com/user-attachments/assets/e195f678-08da-483f-a7f8-f92438fac7a0" />

# Project 1: Multi-Year Forest Change Detection (Before & After Analysis)
This analysis compares CHM data from different years to detect forest growth and loss.

## Steps:
1. Download CHM dataset for multiple years (e.g., 2019 & 2022).  
2. Load both CHM datasets into R.  
3. Compute forest height changes.  
4. Visualize and analyze forest gain & loss.

<img width="683" alt="Screenshot 2025-02-24 at 22 11 07" src="https://github.com/user-attachments/assets/c28c2656-1b45-4c8a-be16-76b136b46db9" />

## Forest Height Change (2019-2022)
Key Observations:
- **Mostly Yellow Areas** → Little to no change in tree height  
- **Green Areas** → Decrease in height (deforestation, storm damage, logging)  
- **Pink/Brown Areas** → Increase in height (regrowth, new tree growth)
  
<img width="360" alt="Screenshot 2025-02-24 at 22 15 57" src="https://github.com/user-attachments/assets/1b1242a3-1103-4c12-951d-8c98177bbba5" />

## Overall Change Statistics
- **Average Canopy Height Change:** 1.08 m  
- **Maximum Height Increase:** 41.95 m  
- **Maximum Height Decrease:** -43.71 m  
- **Canopy Cover in 2019:** 67.61%  
- **Canopy Cover in 2022:** 74.48%  
- **Forest Growth Area:** 2.8%  
- **Forest Loss Area:** 0.73%


## Forest Gain vs. Loss
- **Green (-30m to -10m):** Canopy height decrease (deforestation, storm damage, human activity)  
- **Yellow (~0m):** No significant change in forest height  
- **Brown/Beige (10m to 30m):** Tree growth  


<img width="503" alt="Screenshot 2025-02-24 at 22 42 47" src="https://github.com/user-attachments/assets/7d8e94e8-7a64-46bd-8fc0-ca196bd9b1bf" />

This visualization highlights areas with significant changes in canopy height between 2019 and 2022.


- The majority of the area remains yellow (~0m change), indicating stable canopy height.
- Scattered green patches show tree height reductions (possible deforestation).
- Scattered brown areas indicate tree height increases (regrowth or afforestation).
- Sharp dips in the waveform align with deforested patches.
- Peaks in the graph correspond to regions of high variation in forest height.

### 1. Download the NEON Data
The following R script is for downloading the required NEON LiDAR datasets:

```r
library(neonUtilities)

# Download CHM data for 2019 & 2022
byFileAOP(
  dpID = "DP3.30015.001",
  site = "BART",
  year = "2019",
  savepath = "NEON_CHM_2019/",
  check.size = FALSE
)

byFileAOP(
  dpID = "DP3.30015.001",
  site = "BART",
  year = "2022",
  savepath = "NEON_CHM_2022/",
  check.size = FALSE
)
