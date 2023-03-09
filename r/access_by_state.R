#GOAL: summarize the isochrone analysis by state


# setup -------------------------------------------------------------------

#libraries
library(sf)
library(dplyr)

#load the data

state_fips<-read.csv("./data/state_fips.txt", sep="|")

# process the data --------------------------------------------------------

# make a list of files to process
data_files<-list.files(
  path="./data/isochrones_tracts", 
  pattern=".gpkg",
  full.names = TRUE
)

state_summary <- function(file_list){ 
  
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
      st_cast("POLYGON") %>%  #cast all the multipolygons to polygons
      mutate(state_fips=substr(GEOID, start=1, stop=2)) #make a column and put the first two characters from the GEOID column in it
    
    summarize_states<-iso_tracts %>% 
      as.data.frame() %>% #make it a dataframe (remove the geometries)
      group_by(state_fips, in_out) %>% #group by the state code and the status in or out of the isochrone
      summarise(state_population=sum(part_pop)) %>%  #summarize the table with the sum of the population estimated for each census tract piece
      mutate(isochrone = isochrone_time)
    
    results_table<-rbind(results_table, summarize_states)
    
    
    
  } #end of the loop
  
  return(results_table)

} #end of the function

state_table<-state_summary(data_files) 

summary_state<-state_table%>% #start with the state_table summary
  mutate(STATE=as.numeric(state_fips)) %>% #make a column that contains the fips codes as numbers
  left_join(state_fips) %>%  #join the state_fips code table - it will default to the STATE column since both datasets have this column
  select(-c(STATE, STATENS)) #remove the columns we don't need

write.csv(summary_state, "./data/access_summary_by_state_isochrone.csv")




# analysis ----------------------------------------------------------------

#add a column for the state fips code


#summarize by state fips code


#join a list of states by fips code
