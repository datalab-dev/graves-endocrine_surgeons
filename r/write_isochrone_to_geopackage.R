#GOAL: convert rds files to a spatial format for cartography


# Set Up ------------------------------------------------------------------

# Libraries
library(sf)

# Working directory
setwd("C:\\Users\\mmtobias\\Documents\\GitHub\\graves-endocrine_surgeons")

# Analysis ----------------------------------------------------------------

iso_list<-list.files("./data", pattern="^isochrones", full.names = TRUE)

iso_name<-gsub(pattern='.rds', replacement='', list.files("./data", pattern="^isochrones"))

for (i in 1:length(iso_list)){
  print(i)
  iso_data<-readRDS(iso_list[i])
  iso_data<-iso_data[, -which(names(iso_data)=='ID')]
  
  st_write(iso_data,dsn="./data/isochrones.gpkg", layer=iso_name[i], driver="GPKG")
}
