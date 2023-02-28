
# Setup -------------------------------------------------------------------

#libraries
library("sf")
library("ggplot2")
library("leaflet")
library("tibble")
#File loading
setwd('~/data_lab/endocrine') #setting working directory to the location of the files
temp = list.files(pattern="*.gpkg") #temp as a temporal list of the gpkg files
myfiles = lapply(temp,st_read) #reading the temp list


# Transportation Visualizations ----------------------------------------------------------

i_sixty<-myfiles[[1]][["all"]] %>% as.integer() %>% na.omit() %>% sum()
# i_sixty adds up all of the population numbers from the tracts sixty minute drive data, 
# the code converts to integers, omits empty numbers and sums the numbers
i_ninety<-myfiles[[2]][["all"]] %>% as.integer() %>% na.omit() %>% sum()#refer to i_sixty comments, same with 90 min drive
i_hundredtwenty<-myfiles[[3]][["all"]] %>% as.integer() %>% na.omit() %>% sum() #refer to i_sixty comments, same with 120 min drive

x<-c("60","90","120")
timedrive_df<-data.frame(i_sixty, i_ninety, i_hundredtwenty) %>% t() %>% as.data.frame()
row.names(timedrive_df)<-x
timedrive_df<-rownames_to_column(timedrive_df)
colnames(timedrive_df)<- c("drive_time","population")
## Bar Graph for each driving population ##
ggplot(data = timedrive_df, aes(x=drive_time, y=population)) + geom_bar(stat="identity") 
