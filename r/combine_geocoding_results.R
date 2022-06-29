#GOAL: Combine all of the address data sets into one.


# Set Up ------------------------------------------------------------------

# load libraries

# working directory
setwd("D:\\Graves_Endocrine_Surgery\\data\\address")

# load data

addresses<-read.csv("geocoded_addresses_geocodio_2022-06-16.csv", encoding= "Latin-1", sep=",", strip.white = TRUE)
parkinglots<-read.csv("geocoded_parking_lot_addresses_geocodio2022-06-28.csv", encoding= "Latin-1", sep=",", strip.white = TRUE)
google<-read.csv("addresses_locations_from_google_maps_2022-06-28.csv", encoding= "Latin-1", sep=",", strip.white = TRUE)


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
  print(paste("i=", i, "name_index =", name_index, sep=" "))
  addresses<-addresses[-name_index,]
}

addresses<-rbind(addresses, parkinglots)

for (i in google$full_name){
  name_index<-which(addresses$full_name == i)
  print(paste("i=", i, "name_index =", name_index, sep=" "))
  addresses<-addresses[-name_index,]
}

addresses<-rbind(addresses, google)

#gsub(pattern="\xa0", replacement="", addresses[which(addresses$state != addresses$State), 1])
for (j in c(1:3,7)){
  addresses[,j]<-gsub(pattern="\xa0", replacement="", addresses[,j])
}



#remove duplicate for Grace Lee is a duplicate record and row 257 geocoded to the wrong state; the other rows are duplicates with similar addresses and I kept the one that had a higher geocode rating. Other doctors appear to have two office locations, so the name is duplicated but the office isn't so those remain as-is in the data set.
which(duplicated(addresses$full_name))
addresses[which(duplicated(addresses$full_name)), c(1,4:7)]
addresses<-addresses[-c(217,427,257),]


#did any records get geocoded to a different state than we gave Geocodio?
#Note that Michael Sim's address was listed in "Indianapolis, MI", but Geocodio corrected it to Indiana, which I think is correct because MI doesn't have an Indianapolis and the medical center name is Indiana University.
addresses[which(addresses$state != addresses$State), c(1,7,18)]


#construct the file name
date_time<-Sys.time()
date_time<-gsub(" ", "_", date_time)
date_time<-gsub(":", "", date_time)

file_name<-paste0("geocoded_addresses_", date_time, ".csv")
#Write the file to disk
write.csv(addresses, file=file_name)
