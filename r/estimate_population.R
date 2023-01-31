# Packages used
library(sf)
sf_use_s2(FALSE)
library(dplyr)
library(stringr)
library(tidycensus)
library(tidyverse)

census_api_key("API KEY", install = TRUE)
load_variables(2020, "acs5", cache=TRUE)
load_variables(2020, "pl")

##### Tidycensus section
# Function to read csv of census variables and search population data of the census variables in tidycensus 
# Removed geometry to decrease run time 
read_census_variable_csv <- function(x) {
  
  census_var <- read.csv(x) # Read csv
  
  # Create a vector with the census variable code used in querying data below (+ its name for better readability)
  var <- census_var %>%
    pull(census_variable, column_name) 
  
  # Create df
  census_df <- data.frame()
  
  # Vector of all states
  all_fips <- c(1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 
                31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 72) #72 is PR
  
  for (i in 1:nrow(census_var)) {
    
    # Our variables come from 2 different source so we need to use different functions to get the variables
    # Decennial census variables
    if (census_var$Source[i] == "decennial census") {
      
      # Pull interest variables from decennial census using for loop one at a time and attaching it to a new df 
      dec_census <- get_decennial(
        geography = 'tract', # tract level
        variables = var[i], 
        year = 2020,
        geometry = F,
        cache_table = F,
        state = all_fips)
      
      census_df <- rbind(census_df, dec_census) 
      
      # ACS 5 census variables
    } else {
      
      # Pull interest variables from ACS 5 census using for loop one at a time and attaching it to a new df 
      acs_census <-get_acs(
        geography="tract", # tract level
        survey="acs5",
        year = 2020,
        variable=var[i],
        state=all_fips,
        geometry= F)
      
      # Format ACS 5 table to GEOID, NAME, variable, value (="estimate" in ACS table) so its the same format as 
      # the decennial table so it can bind to census_df
      acs_census <- data.frame(GEOID = acs_census$GEOID, 
                               NAME = acs_census$NAME, 
                               variable = acs_census$variable,
                               value = acs_census$estimate)
      census_df <- rbind(census_df, acs_census)
    }
  }
  return(census_df)
}

# Set working directory
setwd("~/git/graves-endocrine_surgeons")

# Use function to pull population data from the tidycensus package
csv <- "docs/census_variables.csv"
census_df <- read_census_variable_csv(csv) 

# Read chosen census variable from csv to create vector for arranging the final table in order 
census_var <- read.csv(csv)
var <- census_var %>%
  pull(census_variable, column_name)
var_order <- names(var)

##### Isochrone section
# List isochrone files from directory
files <- list.files("data/gpkg/", pattern="*.gpkg", full.names=TRUE)

# Format attribute table from each isochrone file to its own data frame within a large list 'ldf'
ldf <- lapply(files, st_read) # read files to ldf 
ldf <- lapply(ldf, st_drop_geometry) # Remove geometry to decrease run time

# Filename saved to to name future data frames within a list 
filenames <- list.files("data/gpkg/", pattern="*.gpkg", full.names=FALSE)

# Left join census income table to tracts table where each isochrone (inside & ouside) is a list within the join_list
join_list <- list()
for (i in 1:length(ldf)){
  
  # Merge the census variable table to our isochrone table by the key 'GEOID'
  join_variables <- merge(x=ldf[i], y=census_df,
                          by="GEOID", all.x=TRUE) 
  name <- filenames[[i]]
  join_list[[name]] <- join_variables
}

# Calculate and add variable_population_estimate for each variable groups for each isochrone within the list
# This list can be joined with another dataset with geometry to be used to create maps with information on each tract (key = GEOID)
estimate_list <- list()
for (i in 1:length(join_list)){
  
  # Subset out important columns from the join_list data frames 
  variable_tract <- data.frame(GEOID = join_list[[i]]$GEOID, # tract ID 
                               variable = join_list[[i]]$variable.y, # name of census variable
                               variable_population_estimate = join_list[[i]][,8]*join_list[[i]]$value)
  name <- filenames[[i]]
  estimate_list[[name]] <- variable_tract
}

# Group all the variable groups into one for each sublist and sum the population estimate within each variable group
group_list <- list()
for (i in 1:length(estimate_list)) {
  
  # Group variables in each list and sum the population estimates in each group
  # NA values are removed 
  group_variable <- estimate_list[[i]] %>% group_by(variable) %>% 
    summarise(total_variable_estimate = sum(variable_population_estimate, na.rm = TRUE),
              .groups = 'drop')
  
  name <- filenames[[i]]
  group_list[[name]] <- group_variable
}

# Create df for each type of isochrone (60, 90, 120 minutes)
# Dataframe will ouput sum of inside and outside population for each variable 
isochrone_60 <- data.frame(as.data.frame(group_list[[1]][,1]))
isochrone_90 <- data.frame(as.data.frame(group_list[[1]][,1]))
isochrone_120 <- data.frame(as.data.frame(group_list[[1]][,1]))

for (i in 1:length(group_list)){
  
  # if 120 in name of list then separate columns into inside and outside, and sum & group variable groups together
  if (str_detect(names(group_list[i]), "120")){
    
    # Add list to isochrone_120
    name = names(group_list[i])
    print(name)
    isochrone_120[paste0("population_",name)] <- group_list[[i]][,2]
  }
  
  if (str_detect(names(group_list[i]), "90")){
    
    # Add list to isochrone_90
    name = names(group_list[i])
    print(name)
    isochrone_90[paste0("population_",name)] <- group_list[[i]][,2]
  }
  
  if (str_detect(names(group_list[i]), "60")){
    
    # Add list to isochrone_60
    name = names(group_list[i])
    print(name)
    isochrone_60[paste0("population_",name)] <- group_list[[i]][,2]
  }
}

# Order groups by variables listed in the census_variable.csv
isochrone_120 <- isochrone_120 %>% 
  arrange(factor(variable, levels = var_order))

isochrone_90 <- isochrone_90 %>% 
  arrange(factor(variable, levels = var_order))

isochrone_60 <- isochrone_60 %>% 
  arrange(factor(variable, levels = var_order))

### FINAL TABLES
isochrone_120
isochrone_90
isochrone_60

