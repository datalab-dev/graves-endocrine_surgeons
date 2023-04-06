
# Setup -------------------------------------------------------------------

#libraries
library("sf")
library("ggplot2")
library("leaflet")
library("tibble")
library('rio')
library('janitor')
library('tidyverse')
library('scales')
#File loading
setwd('~/data_lab/endocrine') #setting working directory to the location of the files

path<-"./census_analysis_summary_by_variable.xlsx" #path to the file 

list_xlsx_sheets<-import_list(path) #retrieves the data from the different sheets in the 
# xlsx file and creates list of the three sheets using the rio package
options(scipen=1000000) # this makes sure that scientific notation is only used for numbers higher than 1000000
census_variables<- read.csv('./census_variables.csv')
census_variables<-census_variables[,c(3,6)]#the file with the simple names for the variable labels in the graphs

# Transportation Visualizations ----------------------------------------------------------

# i_sixty<-myfiles[[1]][["all"]] %>% as.integer() %>% na.omit() %>% sum()
# # i_sixty adds up all of the population numbers from the tracts sixty minute drive data, 
# # the code converts to integers, omits empty numbers and sums the numbers
# i_ninety<-myfiles[[2]][["all"]] %>% as.integer() %>% na.omit() %>% sum()#refer to i_sixty comments, same with 90 min drive
# i_hundredtwenty<-myfiles[[3]][["all"]] %>% as.integer() %>% na.omit() %>% sum() #refer to i_sixty comments, same with 120 min drive
# 
# x<-c("60","90","120")
# timedrive_df<-data.frame(i_sixty, i_ninety, i_hundredtwenty) %>% t() %>% as.data.frame()
# row.names(timedrive_df)<-x
# timedrive_df<-rownames_to_column(timedrive_df)
# colnames(timedrive_df)<- c("drive_time","population")
# ## Bar Graph for each driving population ##
# ggplot(data = timedrive_df, aes(x=drive_time, y=population)) + geom_bar(stat="identity") 

## The code above was ruled out since it works with the isochromes data directly and leads to some nas being added.



# Cleaning the sheets for ggplot ------------------------------------------

nu<- c("isochrone_120","isochrone_90", "isochrone_60") #names the three df, one for each isochrone

for (i in 1:length(nu)){
  col_name<-c("variable", "value") #column names
  inside<-list_xlsx_sheets[[i]][-75,1:2]%>% as.data.frame#select the correct data subset from the exel sheet
  colnames(inside)<-col_name #change column names
  inside<-inside %>% mutate(isochrone= paste0(nu[i],'_inside'))%>%data.frame()#column that indicates all of the rows here are inside
  inside$label<-census_variables$simple_name#changes the names to the human readable form from the census_variables.csv
  
  outside<-list_xlsx_sheets[[i]][-75,c(1,3)]%>% as.data.frame
  colnames(outside)<-col_name
  outside<-outside %>% mutate(isochrone= paste0(nu[i],'_outside'))%>%data.frame()
  outside$label<-census_variables$simple_name
  
  df<-do.call(rbind, list(inside,outside)) #binds both df
  assign(nu[i],df) #renames the df after its corresponding isochrone
}
all_data<-rbind(isochrone_120,isochrone_90,isochrone_60) #binds the three isochrone dfs
all_data$value<-sapply(all_data$value,as.integer) #values as integers, sanity check, might not be required
all_data <- all_data%>% arrange(variable)%>% arrange(match(variable,unique(variable))) #rearrange the df by repetitions and order
all_data$value<- as.integer(all_data$value)

isocrone_names<-c('isochrone_120_inside'= '120 Inside','isochrone_120_outside'= '120 Outside',
                  'isochrone_90_inside'= '90 Inside','isochrone_90_outside'= '90 Outside',
                  'isochrone_60_inside'= '60 Inside','isochrone_60_outside'= '60 Outside') 
#display names for the isochrones are added
all_data$isochrone <- str_replace_all(all_data$isochrone, isocrone_names)
# colnames(census_variables)[1] <- "variable"
# all_data<-merge(x=all_data, y=census_variables, by='variable')


# Visualizations ----------------------------------------------------------

sex<-7:18
citizenship<-19:48
education<-49:186
employment<-187:240
hispanic<-241:252
income<-253:348
poverty_line<-349:360
race<-361:408
transportation<-409:444
#rows corresponding to each variable


sex_plot<-ggplot(all_data[sex,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
sex_plot #plot that stacks the census variables with two bars per isochrone (inside and outside)

citizenship_plot<-ggplot(all_data[citizenship,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
citizenship_plot

education_plot<-ggplot(all_data[education,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
education_plot

employment_plot<-ggplot(all_data[employment,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
employment_plot

hispanic_plot<-ggplot(all_data[hispanic,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
hispanic_plot

income_plot<-ggplot(all_data[income,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
income_plot

poverty_line_plot<-ggplot(all_data[poverty_line,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
poverty_line_plot

race_plot<-ggplot(all_data[race,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
race_plot

transportation_plot<-ggplot(all_data[transportation,], aes(fill=label, y=value, x=isochrone)) + 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
transportation_plot
