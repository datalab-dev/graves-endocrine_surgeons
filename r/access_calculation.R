#GOAL: calculate who has access to endocrine surgeons. Inputs are the census tracts with population data and the isochrones for various travel times from each surgeon's office address.


# Set Up ------------------------------------------------------------------

# Libraries
library(sf)
library(geojsonsf)

# Load Data
tracts<- readRDS("data/tract_population.rds")

#   !!! Change this path when we calculate all the isochrones !!!
#   !!! This is the test file from the demo to start the coding process !!!
isochrones<-("D:\Graves_Endocrine_Surgery\data\isochrones\isochrone_ucdhealth_100minutes.json")

#ucd_point<-st_as_sf(ucd, coords = c("Longitude", "Latitude"), crs = 4326)


