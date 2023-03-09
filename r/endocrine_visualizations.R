
# Setup -------------------------------------------------------------------

#libraries
library("sf")
library("ggplot2")
library("leaflet")
library("tibble")
library('rio')
library('janitor')
library('tidyverse')

#File loading
setwd('~/data_lab/endocrine') #setting working directory to the location of the files

path<-"./census_analysis_summary_by_variable.xlsx" #path to the file 

list_xlsx_sheets<-import_list(path) #retrieves the data from the different sheets in the 
# xlsx file and creates list of the three sheets using the rio package

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

nu<- c("isochrone_60","isochrone_90", "isochrone_120")

for (i in 1:length(nu)){
  col_name<-c("variable", "value")
  inside<-list_xlsx_sheets[[i]][-75,1:2]%>% as.data.frame
  colnames(inside)<-col_name
  inside<-inside %>% mutate(isochrone= paste0('inside_',nu[i]))%>%data.frame()
  
  outside<-list_xlsx_sheets[[i]][-75,c(1,3)]%>% as.data.frame
  colnames(outside)<-col_name
  outside<-outside %>% mutate(isochrone= paste0('outside_',nu[i]))%>%data.frame()
  
  df<-do.call(rbind, list(inside,outside))
  assign(nu[i],df)
}
all_data<-rbind(isochrone_60,isochrone_90,isochrone_120)
all_data$value<-sapply(all_data$value,as.integer)
all_data <- all_data%>% arrange(variable)%>% arrange(match(variable,unique(variable)))


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


sex_plot<-ggplot(all_data[sex,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
sex_plot

citizenship_plot<-ggplot(all_data[citizenship,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
citizenship_plot

education_plot<-ggplot(all_data[education,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
education_plot

employment_plot<-ggplot(all_data[employment,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
employment_plot

hispanic_plot<-ggplot(all_data[hispanic,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
hispanic_plot

income_plot<-ggplot(all_data[income,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
income_plot

poverty_line_plot<-ggplot(all_data[poverty_line,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
poverty_line_plot

race_plot<-ggplot(all_data[race,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
race_plot

transportation_plot<-ggplot(all_data[transportation,], aes(fill=isochrone, y=value, x=variable)) + 
  geom_bar(position="stack", stat="identity")+
  theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1))
transportation_plot

