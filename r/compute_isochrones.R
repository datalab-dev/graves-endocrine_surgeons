# Read in geocoded addresses and compute the isochrones

library("httr")
library("stringr")
library("jsonlite")
library("pbapply")  
library("geojsonsf")

build_req_str = function(lat, lon, id, time_limit, server, port) {
  locations = data.frame("lat" = lat, "lon" = lon)
  costing = "auto"
  contours = data.frame("time" = time_limit, "color" = "ff0000")
  json = toJSON(list("locations" = locations, "costing" = unbox(costing), 
		     "contours" = contours))
  url_string = str_glue("{server}:{port}/isochrone?json={json}&id={id}")
}

submit_req = function(request) {
    api_response = GET(request)
    response = rawToChar(api_response$content)
    isochrone = geojson_sf(response)
    isochrone = st_cast(isochrone, to="POLYGON")
    isochrone$ID =fromJSON(response)["id"]
    isochrone
}

# if using datasci.library.ucdavis.edu as the server, make sure you are 
# on the staff vpn
server = "http://datasci.library.ucdavis.edu"
port = 8002
address_df = read.csv("../data/geocoded_addresses_2022-06-29_144609.csv")
time_limits = c(90, 120)

for (time_limit in time_limits) {
    # construct a vector of the request strings from the data
    requests = mapply(build_req_str, address_df$Latitude, address_df$Longitude, 
		  address_df$X, time_limit, server, port)

    # actually submit the requests to the server with valhalla
    isochrones = pblapply(requests, submit_req)
    isochrones = do.call(rbind, isochrones)
    
    # save the results
    saveRDS(isochrones, str_glue("../data/isochrones_{time_limit}_min.rds"))
}
