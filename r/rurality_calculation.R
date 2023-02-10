#GOAL: how many people in each isochrone are considered rural?


# Set Up ------------------------------------------------------------------

# Libraries
library(tidycensus)
library(readxl)
library(sf)
library(dplyr)


# API Access
api_key<-readLines("census_API_key.txt")
census_api_key(api_key)

# Prepare Data -----------------------------------------------------------

#read the FORHP rural designations table - identifies tracts that are designated as rural
FORHP_rural_designation<-read_xlsx("./data/non-metro-counties-cts.xlsx")

#if you want to see all the variables available from the census
# vars_2010<-load_variables(
#   year = 2010, 
#   "pl", 
#   cache = TRUE
# )

# The FIPS codes for the states' data we want to download = all US + PR
all_fips<-c(1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 72) #72 is PR

# download the tract geometries with the population (because we need to pick some variable to get the geometries)
# note that the TIGER Census site does not have the 2010 tract geometries to download for the whole county, so we're getting them from tidycensus.
tract_data<-get_acs(
  geography="tract", 
  survey="acs5", 
  year = 2010,
  variable=c(population ="B01003_001"), 
  key=api_key, 
  state=all_fips,
  geometry= TRUE)


# Match the Tracts Listed as Rural ----------------------------------------
# when a specific tract (CT) is listed, mark that in the tracts vector data
# when only a county (CTY FIPS) is listed, mark every census tract that starts with that FIPS code

# an example of getting all the tracts that start with the county FIPS code for Baldwin County, AL
#grep(pattern="^01003", x=tract_data$GEOID)


# add a column to the tract data to hold the rural designation.
# 0 = not rural
# 1 = rural
tract_data$rural_tract<-0

for (i in 1:length(FORHP_rural_designation$CT)){
  
  #print(FORHP_rural_designation$CT[i])
  if (is.na(FORHP_rural_designation$CT[i])==FALSE){ #if the CT column has something in it...
    tract_index<-which(tract_data$GEOID==FORHP_rural_designation$CT[i])
    tract_data$rural_tract[tract_index]<-1 #put a 1 in the rural_tract column (i.e. it's a rural tract)
    
  }else{ #if the CT column is empty (has an NA), then...
    #NOTE: the US Territories like Guam and American Samoa have NA in both columns
    search_FIPS<-paste0("^", FORHP_rural_designation$`CTY FIPS`[i]) #^ in front of the FIPS code means it should match the GEOIDS with that set of numbers at the front (not anywhere)
    tract_data$rural_tract[grep(pattern=search_FIPS, x=tract_data$GEOID)]<-1 #put a 1 in the rural_tract column if the GEOID starts with the country FIPS code we want
    }
}

dissolved_rural<-st_union(tract_data[which(tract_data$rural_tract==1)])

dissolved_not_rural<-st_union(tract_data[which(tract_data$rural_tract==0)])

st_write(tract_data, "./data/rural_areas_2010.gpkg", append=FALSE) #append=FALSE allows overwriting any exisiting file

plot(
  tract_data["rural_tract"], border="transparent"
  # xlim = st_bbox(usa)[c(1,3)], 
  # ylim = st_bbox(usa)[c(2,4)]
)





