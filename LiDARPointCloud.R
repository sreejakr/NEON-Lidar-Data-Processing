# Install required packages
install.packages(c("lidR", "rlas", "ggplot2", "raster", "terra", "rgl","neonUtilities"))
install.packages("gstat")  # Install only once
library(gstat)   
library(lidR)
library(raster)
library(terra)
library(ggplot2)
library(sf)
library(rgl)

# Loading a Classified .LAZ File
las_file <- "~/NEON_lidar-point-cloud-line/NEON.D01.HARV.DP1.30003.001.2019-08.basic.20250401T065524Z.RELEASE-2025/NEON_D01_HARV_DP1_737000_4715000_classified_point_cloud_colorized.laz"  

las <- readLAS(las_file)

summary(las)
plot(las, color = "Z")
table(las$Classification)

# Classification Code	Class Description
# 1	Unclassified
# 2	Ground
# 5	High Vegetation
# 6	Building
# 7	Low Point (Noise)

#Description:  
#   class        : LAS (v1.3 format 3)
# memory       : 211.4 Mb 
# extent       : 737000, 737764, 4715000, 4716000 (xmin, xmax, ymin, ymax)
# coord. ref.  : WGS 84 / UTM zone 18N 
# area         : 0.61 km²
# points       : 2.77 million points
# density      : 4.58 points/m²
# density      : 3.75 pulses/m²

ground <- filter_poi(las, Classification == 2)
trees  <- filter_poi(las, Classification == 5)

plot(trees, color = "Z", main = "Tree Points by Elevation")
plot(ground, main = "Ground Points")


#Creating Digital Terrain Model (DTM) Safely
dtm <- rasterize_terrain(las, res = 1, algorithm = tin())

if (!is.null(dtm)) {
  plot(dtm, main = "Digital Terrain Model (DTM)", col = terrain.colors(25))
}

# Creating a Digital Surface Model (DSM)
dsm <- rasterize_canopy(las, res = 1, algorithm = p2r(subcircle = 0.2)) #elevation of the tallest object
plot(dsm, main = "Digital Surface Model (DSM)")


# Canopy Height Model (CHM = DSM - DTM)
chm <- dsm - dtm
plot(chm, main = "Canopy Height Model (CHM)", col = terrain.colors(25))

# Tree Detection from CHM
trees <- locate_trees(chm, lmf(ws = 5))  # Local Max Filter with 5m window
plot(chm, main = "Detected Trees")
points(trees, col = "red", pch = 20, cex = 0.5)

