# Packages used
library(sf)
sf_use_s2(FALSE)
library(dplyr)
library(stringr)
library(tidycensus)
library(tidyverse)

# list files from directory
files <- list.files("~/Downloads/endocrine access projecgt gpkg/", pattern="*.gpkg", full.names=TRUE)
ldf <- lapply(files, st_read)
ldf <- lapply(ldf, st_drop_geometry) # Remove geometry to decrease run time
filenames <- list.files("~/Downloads/endocrine access projecgt gpkg/", pattern="*.gpkg", full.names=FALSE)

# Load ACS census 2020 variables
vars_acs <- load_variables(2020, "acs5", cache=TRUE)

# All states
all_fips <- c(1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 72) #72 is PR

# Income variable
income_var <- c(income_10k="B19001_002",
                income_10_15k="B19001_003",
                income_15_20k="B19001_004",
                income_20_25k="B19001_005",
                income_25_30k="B19001_006",
                income_30_35k="B19001_007",
                income_35_40k="B19001_008",
                income_40_45k="B19001_009",
                income_45_50k="B19001_010",
                income_50_60k="B19001_011",
                income_60_75k="B19001_012",
                income_75_100k="B19001_013",
                income_100_125k="B19001_014",
                income_125_150k="B19001_015",
                income_150_200k="B19001_016",
                income_200k="B19001_017")

# vector used to arrange the final table
income_order <- c("income_10k",
                  "income_10_15k",
                  "income_15_20k",
                  "income_20_25k",
                  "income_25_30k",
                  "income_30_35k",
                  "income_35_40k",
                  "income_40_45k",
                  "income_45_50k",
                  "income_50_60k",
                  "income_60_75k",
                  "income_75_100k",
                  "income_100_125k",
                  "income_125_150k",
                  "income_150_200k",
                  "income_200k")

income <-get_acs(
  geography="tract", 
  survey="acs5", 
  year = 2020,
  variable=income_var, 
  state=all_fips,
  geometry= F)

# Left join census income table to tracts table where each isochrone (inside & ouside) is a list within the join_income_list
join_income_list <- list()

for (i in 1:length(ldf)){
  join_income <- merge(x=ldf[i], y=income, 
                       by="GEOID", all.x=TRUE)
  name <- filenames[[i]]
  join_income_list[[name]] <- join_income
}

# Calculate and add income_estimate for each income groups for each isochrone within the list
income_estimate_list <- list()

for (i in 1:length(join_income_list)){
  income_tract <- data.frame(income = join_income_list[[i]]$variable.y, 
                             income_estimate = join_income_list[[i]][,8]*join_income_list[[i]]$estimate.y)
  name <- filenames[[i]]
  income_estimate_list[[name]] <- income_tract
}

# Group all the income groups to one for each sublist
group_income_list <- list()

for (i in 1:length(income_estimate_list)) {
  group_income <- income_estimate_list[[i]] %>% group_by(income) %>% 
    summarise(total_income_estimate = sum(income_estimate),
              .groups = 'drop') 
  name <- filenames[[i]]
  group_income_list[[name]] <- group_income
}

# if 60 in name then separate columns into inside and outside, and sum & group income groups together
isochrone_60 <- data.frame(as.data.frame(group_income_list[[1]][,1]))
isochrone_90 <- data.frame(as.data.frame(group_income_list[[1]][,1]))
isochrone_120 <- data.frame(as.data.frame(group_income_list[[1]][,1]))

for (i in 1:length(group_income_list)){
  if (str_detect(names(group_income_list[i]), "120")){
    
    # add list to isochrone_120
    name = names(group_income_list[i])
    print(name)
    isochrone_120[paste0("population_",name)] <- group_income_list[[i]][,2]
    
    # order groups
    income_factor <- factor(isochrone_120$income, levels = income_order, ordered = TRUE)
    isochrone_120 <- isochrone_120 %>% 
      arrange(factor(income_factor))
  }
  if (str_detect(names(group_income_list[i]), "90")){
    
    # add list to isochrone_90
    name = names(group_income_list[i])
    print(name)
    isochrone_90[paste0("population_",name)] <- group_income_list[[i]][,2]
    
    # order groups
    income_factor <- factor(isochrone_90$income, levels = income_order, ordered = TRUE)
    isochrone_90 <- isochrone_90 %>% 
      arrange(factor(income_factor))
  }
  if (str_detect(names(group_income_list[i]), "60")){
    
    # add list to isochrone_60
    name = names(group_income_list[i])
    print(name)
    isochrone_60[paste0("population_",name)] <- group_income_list[[i]][,2]
    
    # order groups
    income_factor <- factor(isochrone_60$income, levels = income_order, ordered = TRUE)
    isochrone_60 <- isochrone_60 %>% 
      arrange(factor(income_factor))
  }
}

isochrone_120
isochrone_90
isochrone_60




