#GOAL: how many people in each isochrone are considered rural?


# Set Up ------------------------------------------------------------------

# Libraries
library(tidycensus)
library(readxl)
library(dplyr)
library(sf)
#library(qgisprocess)


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
all_fips<-c(1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 72) #72 is PR

# download the tract geometries with the population (because we need to pick some variable to get the geometries)
# note that the TIGER Census site does not have the 2010 tract geometries to download for the whole county, so we're getting them from tidycensus.

# load the data the first time
# tract_data<-get_acs(
#   geography="tract",
#   survey="acs5",
#   year = 2010,
#   variable=c(population ="B01003_001"),
#   key=api_key,
#   state=all_fips,
#   geometry= TRUE)
# 
# saveRDS(object=tract_data, file="./data/tracts_2010.rds")

# load saved data
tract_data<-readRDS(file="./data/tracts_2010.rds")

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

# dissolve the polygons to make regions that are rural and not rural instead of all the census tracts
#NOTE: the dplyr approach of usingpolygon_data %>% group_by() %>% summarise() is too computationally intensive and crashes computers with all of the census data.
#NOTE: nothing worked. It all bogs down the computer and crashes it. SO! The solution is to write the tract_data to a file, open it in QGIS, then dissolve it based on the rural_tract column. R is just not set up to do this kind of work yet.

# rural_polygons<-tract_data[which(tract_data$rural_tract==1),]
# 
# dissolved_rural<-st_union(rural_polygons)
# 
# dissolved_not_rural<-st_union(tract_data[which(tract_data$rural_tract==0),])

st_write(tract_data, "./data/rural_areas_2010.gpkg", append=FALSE) #append=FALSE allows overwriting any exisiting file

tract_data<-st_read("./data/rural_areas_2010.gpkg") %>% 
  st_cast("POLYGON")

# plot it to see the result
plot(
  tract_data["rural_tract"], border="transparent"
  # xlim = st_bbox(usa)[c(1,3)], 
  # ylim = st_bbox(usa)[c(2,4)]
)


# Define the Non-Rural Areas ----------------------------------------------------------------

#isolate the non-rural polygons, pick a better projection, buffer them, then dissolve them

#proj4_albers<-"+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs" #USGS's Albers Equal Area projection for North America

nonrural<-tract_data %>% 
  subset(rural_tract==0) %>% #get the non-rural polygons
  st_transform(crs="EPSG:5070") %>%  #reproject it 
  #st_union() still crashes R even with fewer polygons
  mutate(tract_area=st_area(geom))  %>%  
  filter(tract_area > units::set_units(0, "m^2")) %>% #remove the polygons with an area of zero = empty geometries  
  st_union() %>%  #dissolve the adjacent tracts into one polygon
  st_as_sf() %>% 
  mutate(rural_class="nonrural")

rural<-tract_data %>% 
  subset(rural_tract==1) %>% #get the non-rural polygons
  st_transform(crs="EPSG:5070") %>%  #reproject it 
  #st_union() still crashes R even with fewer polygons
  mutate(tract_area=st_area(geom))  %>%  
  filter(tract_area > units::set_units(0, "m^2")) %>% #remove the polygons with an area of zero = empty geometries  
  st_union() %>%  #dissolve the adjacent tracts into one polygon
  st_as_sf() %>% 
  mutate(rural_class="nonrural")




# Spatial Analysis --------------------------------------------------------
# Where do the isochrones coincide with the rural areas?

# make a list of files to process
data_files<-list.files(
  path="./data/isochrones_tracts", 
  pattern=".gpkg",
  full.names = TRUE
  )


# a function to run the analysis
rurality_analysis <- function(file_list){ 
  
  results_table<-data.frame() #make an empty dataframe to hold the results
  
  #split the files into a list of inside & outside the isochrone files
  inside_list<-data_files[grep(pattern="inside", x=data_files)]
  outside_list<-data_files[grep(pattern="outside", x=data_files)]
  
  #make a list of isochrone distances
  isochrone_list <- inside_list %>% 
    strsplit("_") %>% 
    unlist() %>% 
    grep(pattern=".gpkg", value = TRUE) %>% 
    gsub(pattern=".gpkg", replacement="")
  
  for (i in 1:length(isochrone_list)){ #loop through the list of isochrone distances and perform the anlysis on each one
    
    isochrone_time<-isochrone_list[i] #set the isochrone we're working with in this stage of the loop
    print(isochrone_time) #print the current distance to the console (helpful for knowing what stage the process is at)
    
    inside<- st_read(inside_list[i]) %>%  #work with the data inside the isochrone
      mutate(in_out = "inside") #add a column to indicate if it is inside or outside
    names(inside)[7:9]<-c("part_area_meters", "part_percent", "part_pop") #add the column names
    
    outside<- st_read(outside_list[i]) %>% 
      mutate(in_out = "outside")
    names(outside)[7:9]<-c("part_area_meters", "part_percent", "part_pop")
    
    iso_tracts<-rbind(inside, outside) #put the inside and outside datasets together
    
    iso_tracts<-iso_tracts %>% mutate(tract_area=st_area(geom))  %>%  #calculate the area of each polygon and add it to the table
      filter(tract_area > units::set_units(0, "m^2")) %>% #remove the polygons with no area
      st_cast("POLYGON") #cast all the multipolygons to polygons
    
    
    inside_iso_nonrural<-st_difference(iso_tracts[,-2], rural) #find the tracts that are not rural (using difference to exclude the rural areas because st_intersect is not working as expected)
    inside_iso_nonrural$rural_class<-"nonrural" #make a column to indicate the rural class
    
    outside_iso_nonrural<-st_difference(iso_tracts[,-2], nonrural)
    outside_iso_nonrural$rural_class<-"rural"


    iso_nonrural<-rbind(inside_iso_nonrural, outside_iso_nonrural) #combine the datasets
    
    
    union_polys<-iso_nonrural[which(st_geometry_type(iso_nonrural) %in% c("POLYGON", "MULTIPOLYGON")),] %>% #only keep the rows that are polygons or multipolygons
      mutate(pct_rurality_area_meters = st_area(geom)/tract_area_meters) %>%  #calculate the percent area of the new shapes created in the difference process
      mutate(rurality_pop = pct_rurality_area_meters*estimate) %>%  #multiply the area percent by the original population of the census tracts
      mutate(iso_rural_class = paste(in_out, rural_class, sep="_")) #make a column to hold the indication of if the row is in or out of the isochrone and rural or not
    
    file_to_write<-paste0("rurality_analysis_", isochrone_time, ".gpkg") #create a file name
    
    st_write(union_polys, file_to_write, delete_dsn=TRUE) #write the spatial data to a file
    
    
    summarize_polys<-union_polys %>% #make a summary of the spatial data
      as.data.frame() %>% #make it a dataframe (remove the geometries)
      group_by(iso_rural_class) %>% #group the summary by the isochrone and rurality status
      summarise(population = sum(rurality_pop)) %>% #sum the population from the rurality analysis
      mutate(isochrone = isochrone_time) #add a column for the isochrone we processed in this step
    
    results_table <- rbind(results_table, summarize_polys) #add the new rows to the results table
  } #end of isochrone for-loop
  
  names(results_table)<-c("iso_rural_class","population","isochrone") #assign the columnn names
  
  return(results_table) #return the results table so we can use it
  
} #end of rurality_analysis() function

start_time<-Sys.time() #log the start time

results_rurality_analysis<-rurality_analysis(data_files)

(run_duration<-Sys.time()-start_time) #print to the console how long the process took

write.csv(results_rurality_analysis, "rurality_analysis_2023-03-08.csv") #write the summary table to a csv file


#---------------










