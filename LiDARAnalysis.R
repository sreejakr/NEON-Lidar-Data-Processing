# Install and Load Packages
install.packages(c("neonUtilities", "lidR", "raster", "terra", "ggplot2", "sf", "rasterVis", "jsonlite"))

library(neonUtilities)
library(lidR)
library(raster)
library(terra)
library(sf)
library(ggplot2)
library(rasterVis)
library(jsonlite)

# Download Metadata
sites_metadata <- fromJSON("https://data.neonscience.org/api/v0/sites")

# Get CHM product site availability
chm_api_url <- "https://data.neonscience.org/api/v0/products/DP3.30015.001"
chm_data <- fromJSON(chm_api_url)
available_sites <- chm_data$data$siteCodes

# Download CHM Data for BART site for 2019 and 2022
site_code <- "BART"

years <- c("2019", "2022")
save_paths <- c("NEON_Processed_Data_2019/", "NEON_Processed_Data_2022/")

for (i in seq_along(years)) {
  byFileAOP(
    dpID = "DP3.30015.001",
    site = site_code,
    year = years[i],
    savepath = save_paths[i],
    check.size = FALSE
  )
}

# Load and Inspect a Sample CHM File
sample_tile_path <- list.files(
  path = paste0(save_paths[1], "DP3.30015.001/neon-aop-products/2019/FullSite/D01/2019_BART_5/L3/DiscreteLidar/CanopyHeightModelGtif/"),
  pattern = "\\.tif$", full.names = TRUE
)[1]

chm <- raster(sample_tile_path)
print(chm)

#class      : RasterLayer 
#dimensions : 1000, 1000, 1e+06  (nrow, ncol, ncell)
#resolution : 1, 1  (x, y) - Each pixel represents 1 meter × 1 meter in the real world.
#extent     : 312000, 313000, 4873000, 4874000  (xmin, xmax, ymin, ymax)
#crs        : +proj=utm +zone=19 +datum=WGS84 +units=m +no_defs - coordinate reference system
#source     : NEON_D01_BART_DP3_312000_4873000_CHM.tif 
#names      : NEON_D01_BART_DP3_312000_4873000_CHM 

# Visualize CHM 
plot(chm, main = "Sample CHM Tile", col = terrain.colors(25))

chm_df <- as.data.frame(rasterToPoints(chm))
colnames(chm_df) <- c("x", "y", "height")

View(chm_df)

ggplot(chm_df, aes(x = x, y = y, fill = height)) +
  geom_raster() +
  scale_fill_viridis_c(option = "D") +
  labs(title = "Canopy Height Model (CHM)", x = "Longitude", y = "Latitude", fill = "Tree Height (m)") +
  theme_minimal()

hist(values(chm), breaks = 30, main = "Tree Height Distribution", xlab = "Height (m)", col = "forestgreen")

# Canopy Cover for Sample Tile
canopy_threshold <- 2
canopy_cover <- sum(values(chm) > canopy_threshold, na.rm = TRUE) / length(values(chm)) * 100
print(paste("Sample Tile Canopy Cover:", round(canopy_cover, 2), "%"))

# Tree Detection
tree_crowns <- locate_trees(chm, lmf(15)) #the algorithm will scan a 15×15 meter area and find the highest pixel — treating it as a potential tree top.
plot(chm, main = "Detected Trees")
points(tree_crowns, col = "red", pch = 20)

# Multi-Year Forest Change Analysis 
load_chm_rasters <- function(folder_path) {
  tif_files <- list.files(folder_path, pattern = "\\.tif$", full.names = TRUE)
  raster_list <- lapply(tif_files, raster)
  return(do.call(merge, raster_list)) #raster lib function - merges based on metadata of chm file.
}

chm_2019_path <- "NEON_Processed_Data_2019/DP3.30015.001/neon-aop-products/2019/FullSite/D01/2019_BART_5/L3/DiscreteLidar/CanopyHeightModelGtif/"
chm_2022_path <- "NEON_Processed_Data_2022/DP3.30015.001/neon-aop-products/2022/FullSite/D01/2022_BART_6/L3/DiscreteLidar/CanopyHeightModelGtif/"

chm_2019_merged <- load_chm_rasters(chm_2019_path)
chm_2022_merged <- load_chm_rasters(chm_2022_path)

writeRaster(chm_2019_merged, "NEON_Processed_Data_2019/merged_CHM_2019.tif", format = "GTiff")
writeRaster(chm_2022_merged, "NEON_Processed_Data_2019/merged_CHM_2022.tif", format = "GTiff")

# Visualization of Merged CHM
par(mfrow = c(1, 2))
plot(chm_2019_merged, main = "Merged CHM 2019", col = terrain.colors(25))
plot(chm_2022_merged, main = "Merged CHM 2022", col = terrain.colors(25)). #raster pack

levelplot(chm_2019_merged, 
          margin = FALSE,
          main = "CHM - 2019 Merged",
          col.regions = terrain.colors(100)) 
levelplot(chm_2022_merged, 
          margin = FALSE,
          main = "CHM - 2022 Merged",
          col.regions = terrain.colors(100)) #rasterVis pack

# Height Change Analysis
height_change <- chm_2022_merged - chm_2019_merged #height_change[x, y] = chm_2022_merged[x, y] - chm_2019_merged[x, y]
plot(height_change, main = "Forest Height Change (2019-2022)", col = terrain.colors(25))

mean_change <- cellStats(height_change, stat = "mean", na.rm = TRUE)
max_change <- cellStats(height_change, stat = "max", na.rm = TRUE)
min_change <- cellStats(height_change, stat = "min", na.rm = TRUE)

print(paste("Avg Change:", round(mean_change, 2), "m"))
print(paste("Max Increase:", round(max_change, 2), "m"))
print(paste("Max Decrease:", round(min_change, 2), "m"))

# Forest Growth and Loss Area
growth <- height_change > 5
loss <- height_change < -5
growth_area <- sum(values(growth), na.rm = TRUE) / length(values(height_change)) * 100
loss_area <- sum(values(loss), na.rm = TRUE) / length(values(height_change)) * 100

print(paste("Forest Growth Area:", round(growth_area, 2), "%"))
print(paste("Forest Loss Area:", round(loss_area, 2), "%"))

# Significant Change Map
significant_change <- height_change
significant_change[height_change > -5 & height_change < 5] <- NA
levelplot(significant_change, main = "Significant Forest Change (2019-2022)", col.regions = terrain.colors(25))


# Canopy Cover Change (Entire Site) 
canopy_2019 <- chm_2019_merged > 5
canopy_2022 <- chm_2022_merged > 5
cover_2019 <- sum(values(canopy_2019), na.rm = TRUE) / length(values(chm_2019_merged)) * 100
cover_2022 <- sum(values(canopy_2022), na.rm = TRUE) / length(values(chm_2022_merged)) * 100

print(paste("Canopy Cover in 2019:", round(cover_2019, 2), "%"))
print(paste("Canopy Cover in 2022:", round(cover_2022, 2), "%"))



