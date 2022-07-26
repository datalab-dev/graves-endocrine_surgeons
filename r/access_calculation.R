#GOAL: calculate who has access to endocrine surgeons. Inputs are the census tracts with population data and the isochrones for various travel times from each surgeon's office address.


# Set Up ------------------------------------------------------------------

# Libraries
library(sf)
library(geojsonsf)

# Load Data
tracts<- readRDS("./data/tract_population.rds")

#   !!! Change this path when we calculate all the isochrones !!!
#   !!! This is the test file from the demo to start the coding process !!!
#       ./data/isocrhones_90_min.rds 
#       ./data/isochrones_120_min.rds
isochrones<-geojson_sf(geojson="D:\\Graves_Endocrine_Surgery\\data\\isochrones\\isochrone_ucdhealth_100minutes.json")
isochrones<-st_cast(isochrones, to="POLYGON" ) #cast the linestring to a polygon

# Coordinate Reference System
# EPSG 5070 is USA Contiguous Albers Equal Area Conic

tracts<-st_transform(tracts, crs=5070)
isochrones<-st_transform(isochrones, crs=5070)

# Analysis ----------------------------------------------------------------

#calculate the area of each tract
tracts$tract_area_meters<-st_area(tracts)

#intersect the tracts with the isochrone
#not sure which tool is the right one - intersect and union aren't right
#tract_union<-st_union(x=tracts, y=isochrones)

#calculate the area of each piece

#calclulate the percent area of the new/old areas

#how many people are in each census tract piece?

#how many people are inside vs. outside the isochrone?
