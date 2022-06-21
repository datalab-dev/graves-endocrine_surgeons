#GOAL: demonstrate the results of different distance metric options so the team can decide which is the best method to answer the question at hand.


# Setup -------------------------------------------------------------------

# Libraries
library(sf)
library(httr)
library(geojsonsf)
#library(jsonlite)

# Load Data
addresses_raw<-read.csv(
  file="D:/Graves_Endocrine_Surgery/data/address/geocoded_addresses_geocodio_2022-06-16.csv",
  header=T,
  sep=",",
  stringsAsFactors=F
)



# Analysis ----------------------------------------------------------------

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
ucd_point<-st_as_sf(ucd, coords = c("Longitude", "Latitude"), 
                    crs = 4326)
plot(isochrone$geometry)
plot(ucd_point, add=TRUE)


# compare isochrone with isoline (buffer)

ucd_point_3310<-st_transform(ucd_point, 3310)
isochrone_3310<-st_transform(isochrone, 3310)
ucd_100<-st_buffer(ucd_point_3310, 160934) #buffer of ~100 miles

# plot with base R
plot(ucd_100$geometry)
plot(isochrone_3310$geometry, add=TRUE)
plot(ucd_point_3310$geometry, add=TRUE, pch = 15)
