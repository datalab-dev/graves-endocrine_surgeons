#GOAL: calculate who has access to endocrine surgeons. Inputs are the census tracts with population data and the isochrones for various travel times from each surgeon's office address.


# Set Up ------------------------------------------------------------------

# Libraries
#remotes::install_github("paleolimbot/qgisprocess") #https://paleolimbot.github.io/qgisprocess/

library(sf)
library(qgisprocess) 
#library(geojsonsf)


# Custom Functions
calc_access<-function(tracts, isochrones, crs=5070, tempdirectory="./data/temporary" ){
  
  #remove the files in the temporary directory
  do.call(file.remove, list(list.files(tempdirectory, full.names = TRUE)))
  

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
  
  #make a temporary directory to hold the files, if it doesn't already exist
  ifelse(
    !dir.exists(file.path(tempdirectory)), 
    dir.create(file.path(tempdirectory)), 
    FALSE) 
  
  #remove the ID column because it's a list and causing problems
  isochrones<-isochrones[,-9]
  
  #write the isochrones files to the temporary file
  st_write(isochrones, paste0(tempdirectory,"/isochrones.gpkg"), driver= "GPKG")

  
  #define the input and output files
  dissolved_file<-file.path(paste0(tempdirectory,"/dissolve_output.gpkg"))
  isochrone_file<-file.path(paste0(tempdirectory,"/isochrones.gpkg"))
  
  qgis_run_algorithm(
    "native:dissolve",
    INPUT = isochrone_file,
    FIELD = "[]",
    OUTPUT = dissolved_file
  )
  
  #isochrones_dissolved<-st_read(output_file)

  
  #calculate the area of each tract
  tracts$tract_area_meters<-st_area(tracts)
  
  #write the tract to a file
  st_write(tracts, paste0(tempdirectory,"/tracts.gpkg"), driver= "GPKG")  
  
    
  # Union (QGIS) the tracts with the isochrone
  tracts_file<-file.path(paste0(tempdirectory,"/tracts.gpkg"))
  union_file<-file.path(paste0(tempdirectory,"/union.gpkg"))
  
  qgis_run_algorithm(
    "native:union",
    INPUT = tracts_file,
    OVERLAY = dissolved_file,
    FIELD = "[]",
    OUTPUT = union_file
  )
  
  everything<-st_read(union_file)
  
  
  #calculate the area of each piece
  #   Inside: fid_2 != NULL
  #   Outside: fid_2 = NULL
  #inside$inside_area_meters<-st_area(inside)
  #outside$outside_area_meters<-st_area(outside)
  
  
  inside<-subset(everything, is.na(fid_2)==FALSE )
  outside<-subset(everything, is.na(fid_2)==TRUE )
  
  inside$inside_area_meters<-st_area(inside)
  outside$outside_area_meters<-st_area(outside)
  
  #calclulate the percent area of the new/old areas
  inside$inside_percent<-as.numeric(inside$inside_area_meters)/as.numeric(inside$tract_area_meters)
  outside$outside_percent<-as.numeric(outside$outside_area_meters)/as.numeric(outside$tract_area_meters)
  
  #how many people are in each census tract piece?
  inside$inside_pop<-inside$inside_percent*inside$estimate
  outside$outside_pop<-outside$outside_percent*outside$estimate
  
  #how many people are inside vs. outside the isochrone?
  has_access<-sum(inside$inside_pop, na.rm = TRUE)
  no_access<-sum(outside$outside_pop, na.rm = TRUE)
  
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

# Get the list of isochrone data files
iso_list<-list.files("./data", pattern="^isochrones", full.names = TRUE)

access_table<-as.data.frame(matrix(nrow=0, ncol=2))

# Run the Calculation
for (i in iso_list){
  print(i)
  isochrone<-readRDS(i)
  print("RDS read")
  access_numbers<-calc_access(tracts, isochrone)
  access_table<-rbind(access_table, access_numbers)
  print(access_table)
}




