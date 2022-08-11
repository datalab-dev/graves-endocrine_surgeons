#GOAL: calculate who has access to endocrine surgeons. Inputs are the census tracts with population data and the isochrones for various travel times from each surgeon's office address.


# Set Up ------------------------------------------------------------------

# Libraries
#remotes::install_github("paleolimbot/qgisprocess") #https://paleolimbot.github.io/qgisprocess/

library(sf)
library(qgisprocess) 
#library(geojsonsf)


# Custom Functions
calc_access<-function(tracts, isochrones, crs=5070, tempdirectory="./data/temporary" ){
  
  # Process the Isochrones
  #isochrones<-st_cast(isochrones, to="POLYGON" ) #cast the linestring to a polygon
  
  # Check for invalid geometries (repeated vertexes)
  
  #   Test for valid polygons
  valid_test<-st_is_valid(isochrones)
  #   If any invalid polygons are found, fix them; report back in either case
  if (FALSE %in% valid_test){
    print("One or more polygons was invalid. Using st_make_valid() to fix errors.")
    isochrones<-st_make_valid(isochrones)
  }else{
    print("No invalid polygons detected.")
  }
  
  
  # Coordinate Reference System
  # Default Coordinate Reference System = EPSG 5070 is USA Contiguous Albers Equal Area Conic
  # transform the data into the same CRS
  tracts<-st_transform(tracts, crs)
  isochrones<-st_transform(isochrones, crs)
  
  
  
  # Put all the polygons into one layer - QGIS' dissolve does this
  #   sf's st_union() has odd, nested results that aren't helpful
  
  
  ifelse(!dir.exists(file.path(tempdirectory)), dir.create(file.path(tempdirectory)), FALSE)
  
  write_sf(isochrones, paste0(tempdirectory,"isochrones.gpkg"))
  output_file<-file.path(paste0(tempdirectory,"dissolve_output.gpkg"))
  input_file<-file.path(paste0(tempdirectory,"isochrones.gpkg"))
  
  qgis_run_algorithm(
    "native:dissolve",
    INPUT = input_file,
    FIELD = "[]",
    OUTPUT = output_file
  )
  
  

  
  #calculate the area of each tract
  tracts$tract_area_meters<-st_area(tracts)
  
  #intersect the tracts with the isochrone
  #not sure which tool is the right one 
  #   - SF's st_intersect and st_union aren't right
  #   - terra's union isn't right
  #   - sfhelpers st_or() didn't work either
  # 2 step process with SF? st_difference + st_intersection - https://stackoverflow.com/questions/54710574/how-to-do-a-full-union-with-the-r-package-sf 
  
  inside<-st_intersection(tracts, isochrones)
  outside<-st_difference(tracts, isochrones)
  
  #calculate the area of each piece
  inside$inside_area_meters<-st_area(inside)
  outside$outside_area_meters<-st_area(outside)
  
  #calclulate the percent area of the new/old areas
  inside$inside_percent<-as.numeric(inside$inside_area_meters)/as.numeric(inside$tract_area_meters)
  outside$outside_percent<-as.numeric(outside$outside_area_meters)/as.numeric(outside$tract_area_meters)
  
  #how many people are in each census tract piece?
  inside$inside_pop<-inside$inside_percent*inside$estimate
  outside$outside_pop<-outside$outside_percent*outside$estimate
  
  #how many people are inside vs. outside the isochrone?
  has_access<-sum(inside$inside_pop)
  no_access<-sum(outside$outside_pop)
  
  access_results<-as.data.frame(
    matrix(
      data=c(has_access, no_access), 
      nrow = 1, 
      ncol = 2, 
      byrow= TRUE,
      dimnames=list(c(NULL), c("has_access", "no_access")) #row then col names
      ), 
    )
  
  return(access_results)
}

# Load Data
tracts<- readRDS("./data/tract_population.rds")

#   !!! Change this path when we calculate all the isochrones !!!
#   !!! This is the test file from the demo to start the coding process !!!
#       ./data/isocrhones_90_min.rds 
#       ./data/isochrones_120_min.rds

#isochrones<-geojson_sf(geojson="D:\\Graves_Endocrine_Surgery\\data\\isochrones\\isochrone_ucdhealth_100minutes.json")

#isochrones<- readRDS("C:\\Users\\mmtobias\\Downloads\\isochrones_90_min.rds")


# Get the list of isochrone data files
iso_list<-list.files("./data", pattern="^isochrones", full.names = TRUE)

# Run the Calculation
for (i in iso_list){
  print(i)
  isochrone<-readRDS(i)
  print("RDS read")
  access_numbers<-calc_access(tracts, isochrone)
  print(access_numbers)
}


# can terra union/dissove/merge the isochrone vectors without causing an invalid geometry?
library(terra)
iso_merge<-merge(isochrones)


