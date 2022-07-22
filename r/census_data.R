#GOAL: get census/ACS data at the tract level for the US and join it to the tract geometries


# Set Up ------------------------------------------------------------------

# libraries
#install.packages("tidycensus")
library(tidycensus)

# working directory
setwd("D:\\Graves_Endocrine_Surgery\\data")

# load data

# load the API key from a local file
con<-file("D:\\Graves_Endocrine_Surgery\\census_API_key.txt")
api_key<-readLines(con)
close(con)



# Analysis ----------------------------------------------------------------

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

# get data for CA

population<-get_acs(
  geography="tract", 
  survey="acs5", 
  variable=c(population ="B01003_001"), 
  key=api_key, 
  state=c(06, 04),
  geometry= TRUE)

pop_sacramento<-get_acs(
  geography="tract", 
  survey="acs5", 
  variable=c(population ="B01003_001"), 
  key=api_key, 
  state="CA",
  county = "Sacramento",
  geometry= TRUE) #geometry parameter turns the table into an sf object
 
plot(pop_sacramento["estimate"])




all_fips<-c(1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 72) #72 is PR

tract_data<-get_acs(
  geography="tract", 
  survey="acs5", 
  year = 2020,
  variable=c(population ="B01003_001"), 
  key=api_key, 
  state=all_fips,
  geometry= TRUE)

saveRDS(tract_data, file="./census/tract_population.rds")

plot(tract_data["estimate"], 
     xlim=c(-125,-64.4),  
     ylim=c(25,50),
     breaks="quantile",
     border=FALSE)
