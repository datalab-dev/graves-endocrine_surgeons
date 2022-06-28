#GOAL: Combine all of the address datasets into one.


# Set Up ------------------------------------------------------------------

# load libraries

# working directory
setwd("D:\\Graves_Endocrine_Surgery\\data\\address")

# load data

addresses<-read.csv("geocoded_addresses_geocodio_2022-06-16.csv")
parkinglots<-read.csv("geocoded_parking_lot_addresses_geocodio2022-06-28.csv")
google<-read.csv("addresses_locations_from_google_maps_2022-06-28.csv")


# Custom Functions ---------------------------------------------------------------

# FUNCTION: name_key()
# INPUTS: 
#       address_table = the table containing the geocoding results from Geocodio; assumes the first two columns contain the first_name and last_name of the doctor
# OUTPUTS: the address_table with the concatenation of the first_name and last_name columns (called full_name) in the first column of the table

name_key<-function(address_table){
  full_name<-paste(address_table[,1], address_table[,2], sep=" ")
  new_table<-cbind.data.frame(full_name, address_table)
  return(new_table)
}


# Analysis ----------------------------------------------------------------

# add the name key column so it's easier to identify the right row to replace
addresses<-name_key(addresses)
parkinglots<-name_key(parkinglots)
google<-name_key(google)

# replace addresses data with the parkinglots data
#       https://astrostatistics.psu.edu/su07/R/html/base/html/Extract.data.frame.html


#TO DO: remove special characters from all of the files.

for (i in parkinglots$full_name){
  name_index<-which(addresses$full_name == i)
  print(name_index)
}
which(addresses$full_name == parkinglots$full_name[1])


