#GOAL: demonstrate the results of different distance metric options so the team can decide which is the best method to answer the question at hand.


# Setup -------------------------------------------------------------------

# Libraries
library(sf)
library(httr)
library(geojsonsf)
#library(jsonlite)

# Load Data

# Address Data
addresses_raw<-read.csv(
  file="D:/Graves_Endocrine_Surgery/data/address/geocoded_addresses_geocodio_2022-06-16.csv",
  header=T,
  sep=",",
  stringsAsFactors=F
)

# Road Data - for visualization (not routing)
roads<-st_read('C:\\Users\\mmtobias\\Box\\D Drive\\GIS_Data\\NaturalEarth\\ne_10m_roads\\ne_10m_roads.shp')


# Isochrone ----------------------------------------------------------------
# This code uses the Valhalla Isochrone API. Valhalla is running in a local Docker container.

# just UCD Medical Center
ucd<-addresses_raw[which(addresses_raw$last_name == 'Graves'),]

address_lat<-ucd$Latitude

address_lon<-ucd$Longitude

url<-paste0(
  'http://localhost:8002/isochrone?json={"locations":[{"lat":',
  address_lat,
  ',"lon":',
  address_lon,
  '}],"costing":"auto","contours":[{"time":100,"color":"ff0000"}]}&id=UCDHealth}')

api_response<-GET(url)

isochrone<-geojson_sf(rawToChar(api_response$content))

# plot it to prove it
ucd_point<-st_as_sf(ucd, coords = c("Longitude", "Latitude"), crs = 4326)


# Isoline (Buffer) --------------------------------------------------------
# compare isochrone with isoline (buffer)

# first, all the data needs to be in projected coordinate system
ucd_point_3310<-st_transform(ucd_point, 3310)
isochrone_3310<-st_transform(isochrone, 3310)

# calculate the buffer in meters, the native units of the coordinate system
ucd_100<-st_buffer(ucd_point_3310, 160934) #buffer of ~100 miles


# Plots -------------------------------------------------------------------

roads_3310<-st_transform(roads, 3310)


# plot with base R
plot(ucd_100$geometry, border='darkorange', lwd=2)
plot(roads_3310$geometry, add=TRUE)
plot(isochrone_3310$geometry, add=TRUE, col='darkgreen', lwd=2)
plot(ucd_point_3310$geometry, add=TRUE, pch = 15)
