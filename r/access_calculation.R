#GOAL: calculate who has access to endocrine surgeons. Inputs are the census tracts with population data and the isochrones for various travel times from each surgeon's office address.


# Set Up ------------------------------------------------------------------

# Libraries
#remotes::install_github("paleolimbot/qgisprocess") #https://paleolimbot.github.io/qgisprocess/

library(sf)
library(qgisprocess) 
#library(geojsonsf)


# Custom Functions

# fix invalid polygons
fix_invalid<-function(polygons){
  
  #test to see if any polygons are invalid
  valid_test<-st_is_valid(polygons)
  
  #   If any invalid polygons are found, fix them; report back in either case
  if (FALSE %in% valid_test){
    print("One or more polygons was invalid. Using st_make_valid() to fix errors.")
    polygons<-st_make_valid(polygons)
  }else{
    print("No invalid polygons detected.")
  }
  
  return(polygons)
}



calc_access<-function(tracts, isochrones, crs=5070, distance_label="___", save_directory="./data/isochrones_tracts" ){
  
  #make a temporary directory to hold the files, if it doesn't already exist
  ifelse(
    !dir.exists(file.path(save_directory)), 
    dir.create(file.path(save_directory)), 
    FALSE) 
  
  #remove the files in the temporary directory
  #do.call(file.remove, list(list.files(save_directory, full.names = TRUE)))
  

  # Check for invalid geometries (repeated vertexes)
  isochrones<-fix_invalid(isochrones)
  tracts<-fix_invalid(tracts)
  

  
  
  # Coordinate Reference System
  # Default Coordinate Reference System = EPSG 5070 is USA Contiguous Albers Equal Area Conic
  # transform the data into the same CRS
  tracts<-st_transform(tracts, crs)
  isochrones<-st_transform(isochrones, crs)
  
  
  
  # Put all the polygons into one layer - QGIS' dissolve does this
  #   sf's st_union() has odd, nested results that aren't helpful
  

  
  #reduce the number of unnecessary attributes
  isochrones<-isochrones[,8]
  
  # #write the isochrones files to the temporary file
  # st_write(isochrones, paste0(save_directory,"/isochrones.gpkg"), driver= "GPKG")
  # 
  # 
  # #define the input and output files
  # dissolved_file<-file.path(paste0(save_directory,"/dissolve_output.gpkg"))
  # isochrone_file<-file.path(paste0(save_directory,"/isochrones.gpkg"))
  # dissolved_multi<-file.path(paste0(save_directory,"/dissolve_multi.gpkg"))

  # Dissolve the isochrones into one multipolygon, then explode it into it's component polygons
  #this is making too big of polygons on the east coast
  # qgis_run_algorithm(
  #   "native:dissolve",
  #   INPUT = isochrone_file,
  #   FIELD = "[]",
  #   OUTPUT = dissolved_file
  # )
  # 
  # qgis_run_algorithm( 
  #   "native:multiparttosingleparts",
  #   INPUT = dissolved_file,
  #   OUTPUT = dissolved_multi
  # )
  
  #dissolve the isochrones into one big polygon - becomes a "Large sfc_MULTIPOLYGON"
  isochrones_dissolved<-st_union(isochrones)
  
  #isochrones_dissolved<-st_read(dissolved_multi)
  # isochrones_dissolved<-isochrones
  # isochrones_dissolved$inside<-1
  # isochrones_dissolved_minimal<-isochrones_dissolved[,10]
  

  #calculate the area of each tract
  tracts$tract_area_meters<-st_area(tracts)
  
  #union the tracts and isochrones
  inside<-st_intersection(tracts, isochrones_dissolved)
  outside<-st_difference(tracts, isochrones_dissolved)
  
  #write the tract to a file
  #st_write(tracts, paste0(save_directory,"/tracts.gpkg"), driver= "GPKG")  
  
    
  # # Union (QGIS) the tracts with the isochrone
  # tracts_file<-file.path(paste0(save_directory,"/tracts.gpkg"))
  # union_input<-file.path(paste0(save_directory,"/tracts.gpkg"))
  # 
  # 
  # #seed the union file with the tracts to start
  # #st_write(tracts, paste0(save_directory,"/union.gpkg"), driver= "GPKG")
  # 
  # for (i in 1:length(isochrones_dissolved_minimal$geom)){
  #   print(i)
  #   
  #   (dissolved_file_i<-file.path(paste0(save_directory,"/dissolved_", i,".gpkg")))
  #   (union_output<-file.path(paste0(save_directory,"/union_", i, ".gpkg")))
  #   
  #   #write the i-th isochrone to the disc
  #   st_write(isochrones_dissolved_minimal[i,], dissolved_file_i, driver="GPKG")
  #   
  #   #qgis_show_help("native:union")
  #   
  #   qgis_run_algorithm(
  #     "native:union",
  #     INPUT = union_input,
  #     OVERLAY = dissolved_file_i,
  #     FIELD = "[]",
  #     OUTPUT = union_output
  #   )
  #   
  #   union_input<-union_output
  #   
  #   #remove unnecessary files
  #   file.remove(dissolved_file_i)
  #   
  #   ifelse(
  #     file.exists(file.path(paste0(save_directory,"/union_", i-1, ".gpkg"))), 
  #     file.remove(file.path(paste0(save_directory,"/union_", i-1, ".gpkg"))), 
  #     FALSE) 
  # 
  #   ifelse(
  #     file.exists(file.path(paste0(save_directory,"/union_", i-1, ".gpkg"))), 
  #     file.remove(file.path(paste0(save_directory,"/dissolved_", i-1,".gpkg"))), 
  #     FALSE)     
  # 
  # }

  # 
  # everything<-st_read(union_output)
  # everything<-fix_invalid(everything)
  # 
  # inside_cols<-as.data.frame(everything)
  # inside_cols<-inside_cols[,grep("inside", names(everything))]
  # inside_cols<-rowSums(inside_cols, na.rm = TRUE)
  # 
  # everything$inside_iso<-inside_cols
  # 
  # #calculate the area of each piece
  # #   Inside: fid_2 != NULL
  # #   Outside: fid_2 = NULL
  # #inside$inside_area_meters<-st_area(inside)
  # #outside$outside_area_meters<-st_area(outside)
  # 
  # 
  # # inside<-subset(everything, is.na(fid_2)==FALSE )
  # # outside<-subset(everything, is.na(fid_2)==TRUE )
  # 
  # inside<-subset(everything, inside_iso==1)
  # outside<-subset(everything, inside_iso==0)
  
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
  
  plot(inside$geometry)

  #write the inside and outside polygons to a file, overwriting existing files with the same name
  st_write(inside, file.path(paste0(save_directory,"/inside_tracts_", distance_label, ".gpkg")), driver="GPKG", delete_dsn=TRUE)
  
  st_write(outside, file.path(paste0(save_directory,"/outside_tracts_", distance_label, ".gpkg")), driver="GPKG", delete_dsn=TRUE)

  #return the results
  return(access_results)
}

# Load Data
tracts<- readRDS("./data/tract_population.rds")

# Get the list of isochrone data files
iso_list<-list.files("./data", pattern="^isochrones", full.names = TRUE)

access_table<-as.data.frame(matrix(nrow=0, ncol=3))

start_time<-Sys.time()

# Run the Calculation
for (i in iso_list){
  print(i)
  iso_dist<-as.list(unlist(strsplit(i, "_")))[[2]] #get the distance number
  isochrone<-readRDS(i)
  print("RDS read")
  access_numbers<-calc_access(tracts, isochrone, distance_label = iso_dist)
  access_numbers$isochrone<-i
  access_table<-rbind(access_table, access_numbers)
  print(access_table)
}

finish_time<-Sys.time()
(time_elapsed<-finish_time-start_time)




