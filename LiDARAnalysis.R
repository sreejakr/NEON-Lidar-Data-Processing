install.packages(c("neonUtilities", "lidR", "raster", "terra", "ggplot2", "sf"))
install.packages("rasterVis")
library(lidR)    
library(raster)   
library(terra)    
library(sf)       
library(ggplot2)
library(neonUtilities)  # For downloading NEON data

install.packages("jsonlite")
library(jsonlite)

### Download the data ###

sites_metadata <- fromJSON("https://data.neonscience.org/api/v0/sites")

library(jsonlite)

chm_api_url <- "https://data.neonscience.org/api/v0/products/DP3.30015.001"
chm_data <- fromJSON(chm_api_url)
available_sites <- chm_data$data$siteCodes
str(chm_data$data$siteCodes)

# Display available years for the BART site - 2016-09, 2017-09, 2019-08, 2020-08, 2022-06
subset(chm_availability, site == "BART")

#Data for 2019
library(neonUtilities)

site_code <- "BART"  # Bartlett Experimental Forest
year <- "2019" 

# Download CHM (Pre-classified tree height model)
byFileAOP(
  dpID = "DP3.30015.001",
  site = site_code,  
  year = year,
  savepath = "NEON_Processed_Data_1/",
  check.size = FALSE
)

library(neonUtilities)
year_new <- "2022"

byFileAOP(
  dpID = "DP3.30015.001", 
  site = "BART",  
  year = year_new,
  savepath = "NEON_Processed_Data_2022/",
  check.size = FALSE,
)

library(raster)
library(ggplot2)

neon_folder <- "NEON_Processed_Data_1/DP3.30015.001/neon-aop-products/2019/FullSite/D01/2019_BART_5/L3/DiscreteLidar/CanopyHeightModelGtif/"

# List all downloaded LiDAR files
neon_files <- list.files(neon_folder, pattern = "\\.tif$", full.names = TRUE)

# Load CHM
chm <- raster(neon_files[1])

# Check raster metadata
print(chm)

# class      : RasterLayer 
# dimensions : 1000, 1000, 1e+06  (nrow, ncol, ncell)
# resolution : 1, 1  (x, y)
# extent     : 312000, 313000, 4873000, 4874000  (xmin, xmax, ymin, ymax)
# crs        : +proj=utm +zone=19 +datum=WGS84 +units=m +no_defs 
# source     : NEON_D01_BART_DP3_312000_4873000_CHM.tif 
# names      : NEON_D01_BART_DP3_312000_4873000_CHM 

### ANALYSIS ###

# Plot of CHM
plot(chm, main="Canopy Height Model (CHM)", col=terrain.colors(25))
chm_df <- as.data.frame(rasterToPoints(chm))
colnames(chm_df) <- c("x", "y", "height")

ggplot(chm_df, aes(x=x, y=y, fill=height)) +
  geom_raster() +
  scale_fill_viridis_c(option = "D") + 
  labs(title="Canopy Height Model (CHM)", x="Longitude", y="Latitude", fill="Tree Height (m)") +
  theme_minimal()

# Histogram of tree heights
hist(values(chm), breaks=30, main="Tree Height Distribution", xlab="Height (m)", col="forestgreen")

# Canopy cover threshold -  Trees taller than 2m are considered canopy
canopy_threshold <- 2  
canopy_cover <- sum(values(chm) > canopy_threshold, na.rm=TRUE) / length(values(chm)) * 100
print(paste("Canopy Cover Percentage:", round(canopy_cover, 2), "%"))

library(lidR)

# Detect tree crowns
tree_crowns <- locate_trees(chm, lmf(15))
plot(chm, main="Detected Trees")
points(tree_crowns, col="red", pch=20)


#  Multi-Year Forest Change Detection (Before & After Analysis) - 2019 vs 2024
#Analyze how tree heights have changed before and after a disturbance event (e.g., wildfire, logging, storm damage) using multi-year LiDAR data.

#Merge All CHM Tiles into a Single Raster

library(raster)

# Define file paths
chm_2019_folder <- "NEON_Processed_Data_1/DP3.30015.001/neon-aop-products/2019/FullSite/D01/2019_BART_5/L3/DiscreteLidar/CanopyHeightModelGtif/"
chm_2022_folder <- "NEON_Processed_Data_2022/DP3.30015.001/neon-aop-products/2022/FullSite/D01/2022_BART_6/L3/DiscreteLidar/CanopyHeightModelGtif/"

# List all CHM `.tif` files for 2019 and 2022
chm_2019_files <- list.files(chm_2019_folder, pattern = "\\.tif$", full.names = TRUE)
chm_2022_files <- list.files(chm_2022_folder, pattern = "\\.tif$", full.names = TRUE)

print(paste("Found", length(chm_2019_files), "CHM files for 2019")) #135
print(paste("Found", length(chm_2022_files), "CHM files for 2022")) #156


chm_2019_list <- lapply(chm_2019_files, raster)
chm_2022_list <- lapply(chm_2022_files, raster)

# Merge all CHM tiles for 2019 and 2022 - Run this only the first time
chm_2019_merged <- do.call(merge, chm_2019_list)
chm_2022_merged <- do.call(merge, chm_2022_list)
par(mfrow=c(1,2))
writeRaster(chm_2019_merged, "NEON_Processed_Data_1/merged_CHM_2019.tif", format="GTiff")
writeRaster(chm_2022_merged, "NEON_Processed_Data_1/merged_CHM_2022.tif", format="GTiff")

# Load merged CHM files
chm_2019_merged <- raster("NEON_Processed_Data_1/merged_CHM_2019.tif")
chm_2022_merged <- raster("NEON_Processed_Data_1/merged_CHM_2022.tif")
par(mfrow=c(1,2))
plot(chm_2019_merged, main="Merged CHM 2019", col=terrain.colors(25))
plot(chm_2022_merged, main="Merged CHM 2022", col=terrain.colors(25))


# Subtract the 2019 CHM from the 2022 CHM to find areas where tree height increased or decreased.
height_change <- chm_2022_merged - chm_2019_merged
plot(height_change, main="Forest Height Change (2019-2022)", col=terrain.colors(25))


# Compute statistics for forest height change
mean_change <- cellStats(height_change, stat="mean", na.rm=TRUE)
max_change <- cellStats(height_change, stat="max", na.rm=TRUE)
min_change <- cellStats(height_change, stat="min", na.rm=TRUE)

print(paste("Average Canopy Height Change:", round(mean_change, 2), "m"))
print(paste("Maximum Height Increase:", round(max_change, 2), "m"))
print(paste("Maximum Height Decrease:", round(min_change, 2), "m"))

# Area of Forest Growth vs. Loss
growth_threshold <- 5   # Trees grew more than 5m
loss_threshold <- -5    # Trees lost more than 5m
growth <- height_change > growth_threshold
loss <- height_change < loss_threshold
growth_area <- sum(values(growth), na.rm=TRUE) / length(values(height_change)) * 100
loss_area <- sum(values(loss), na.rm=TRUE) / length(values(height_change)) * 100

print(paste("Forest Growth Area:", round(growth_area, 2), "%"))
print(paste("Forest Loss Area:", round(loss_area, 2), "%"))

# Since the detection map is mostly uniform, let’s filter only the areas with significant change for a clearer visualization.
library(rasterVis)
significant_change <- height_change
significant_change[height_change > -5 & height_change < 5] <- NA  
# Plot significant changes only
levelplot(significant_change, main="Significant Forest Change (2019-2022)", col.regions=terrain.colors(25))


# Compute % canopy cover
canopy_2019 <- chm_2019_merged > 5
canopy_2022 <- chm_2022_merged > 5
cover_2019 <- sum(values(canopy_2019), na.rm=TRUE) / length(values(chm_2019_merged)) * 100
cover_2022 <- sum(values(canopy_2022), na.rm=TRUE) / length(values(chm_2022_merged)) * 100

print(paste("Canopy Cover in 2019:", round(cover_2019, 2), "%"))
print(paste("Canopy Cover in 2022:", round(cover_2022, 2), "%"))



