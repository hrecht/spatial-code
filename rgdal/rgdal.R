library(rgdal)
library(dplyr)

# Download counties shapefile and unzip
download.file("ftp://ftp2.census.gov/geo/tiger/TIGER2016/COUNTY/tl_2016_us_county.zip", "tl_2016_us_county.zip")
unzip("tl_2016_us_county.zip", exdir = "tl_2016_us_county/")

# Read in file as SpatialPolygonsDataFrame
counties <- readOGR("tl_2016_us_county/", "tl_2016_us_county")

# List attributes
colnames(counties@data)

# Get starbucks data (from 2012)
starbucks <- read.csv(url("https://opendata.socrata.com/api/views/txu4-fsic/rows.csv?accessType=DOWNLOAD"), stringsAsFactors = F)

# Make a spatial data frame
coordinates(starbucks) <- starbucks[c("Longitude", "Latitude")]
# Need to use same CRS for spatial join
starbucks@proj4string <- counties@proj4string

# Spatial join points to polygons
temp <- over(starbucks, counties[,"GEOID"])
starbucks$GEOID <- temp$GEOID
starbucks <- starbucks@data

# Calculate number of starbucks per county
sbcty <- starbucks %>% group_by(GEOID) %>%
	summarize(starbucks = n())

# Join to counties shapefile
counties <- merge(counties, sbcty, by="GEOID", sort = FALSE, all.x = TRUE)

# Subset counties to DC, MD, VA
dmv <- counties[(counties@data$STATEFP %in% c(11, 24, 51)),]

# New column - state name
dmv@data <- dmv@data %>% mutate(STATENAME = ifelse(STATEFP == "11", "District of Columbia", 
																									 ifelse(STATEFP == "24", "Maryland",
																									 			 ifelse(STATEFP == "51", "Virginia",
																									 			 				""))))

# Export
writeOGR(dmv, dsn="rgdal/shp/", layer="dmv", driver="ESRI Shapefile", overwrite_layer = T)