#GOAL: get census/ACS data at the tract level for the US and join it to the tract geometries


# Set Up ------------------------------------------------------------------

# libraries
#install.packages("tidycensus")
library(tidycensus)
library(reshape)
library(sf)

# working directory
setwd("D:\\Graves_Endocrine_Surgery\\data")

# load data

# get the list of isochrone data
isochrone_files<-list.files(".\\isochrones_tracts")

inside_60<-read_sf(".\\isochrones_tracts\\inside_tracts_60.gpkg")

# load the API key from a local file
con<-file("D:\\Graves_Endocrine_Surgery\\census_API_key.txt")
api_key<-readLines(con)
close(con)




# Searching Variables -----------------------------------------------------

# search for variables
vars_pl_2020<-load_variables(2020, "pl")
View(vars_pl_2020)

# SF1 isn't available for 2020 yet
vars_sf1<-load_variables(year=2010, dataset="sf1")

# ACS1 isn't available for 2020 in tidycensus
vars_acs<-load_variables(2020, "acs5")
View(vars_acs)

vars_acs_profile<-load_variables(2020, "acs5/profile")
View(vars_acs_profile)


# Analysis ----------------------------------------------------------------

# List the FIPS codes for the states for which you want to get data
all_fips<-c(1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 72) #72 is PR



# Race Analysis -----------------------------------------------------------

# variables to download
race_vars = c(
  all = "P2_001N", # All
  hisp = "P2_002N", # Hispanic
  white = "P2_005N", # White
  baa = "P2_006N", # Black or African American
  amin = "P2_007N", # American Indian
  asian = "P2_008N", # Asian
  nhopi = "P2_009N", # Native Hawaiian or Pacific Islander
  other = "P2_010N", # Some Other Race
  multi = "P2_011N" # Two or More Races
)

# get the data
race <- get_decennial(
  geography = 'tract',
  variables = race_vars,
  year = 2020,
  geometry = F,
  cache_table = TRUE,
  key = api_key,
  state = all_fips
)

# reshape the table into one column per variable
race_wide<-cast(race, GEOID~variable, mean)

# calculate the estimated number of people from each category in each partial census polygon

#   Join isochrone data - by GEOID






# # get data for CA
# 
# population<-get_acs(
#   geography="tract", 
#   survey="acs5", 
#   variable=c(population ="B01003_001"), 
#   key=api_key, 
#   state=c(06, 04),
#   geometry= TRUE)
# 
# pop_sacramento<-get_acs(
#   geography="tract", 
#   survey="acs5", 
#   variable=c(population ="B01003_001"), 
#   key=api_key, 
#   state="CA",
#   county = "Sacramento",
#   geometry= TRUE) #geometry parameter turns the table into an sf object
# 
# plot(pop_sacramento["estimate"])
# tract_data<-get_acs(
#   geography="tract", 
#   survey="acs5", 
#   year = 2020,
#   variable=c(population ="B01003_001"), 
#   key=api_key, 
#   state=all_fips,
#   geometry= TRUE)
# 
# saveRDS(tract_data, file="./data/tract_population.rds")
# 
# plot(tract_data["estimate"], 
#      xlim=c(-125,-64.4),  
#      ylim=c(25,50),
#      breaks="quantile",
#      border=FALSE)
