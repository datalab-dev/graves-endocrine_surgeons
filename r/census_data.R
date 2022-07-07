#GOAL: get census/ACS data at the tract level for the US and join it to the tract geometries


# Set Up ------------------------------------------------------------------

# libraries
#install.packages("tidycensus")
library(tidycensus)

# load data

# load the API key from a local file
con<-file("D:\\Graves_Endocrine_Surgery\\census_API_key.txt")
api_key<-readLines(con)
close(con)



# Analysis ----------------------------------------------------------------


