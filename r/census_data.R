#GOAL: get census/ACS data at the tract level for the US and join it to the tract geometries


# Set Up ------------------------------------------------------------------

# libraries
#install.packages("tidycensus")
library(tidycensus)

# working directory


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

population<-get_acs(geography="tract", survey="acs5", variable="B01003_001", key=api_key, state="CA")
