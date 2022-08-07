library(plyr)
library(purrr)
library(dplyr)
library(tidyverse)
library(lubridate)

setwd('./Data/')
trend_data <- list.files(pattern = 'trends_up_to_', full.names = TRUE) %>%
           map_df(read_csv) %>%
           bind_rows()

scorecard_dict <- read_csv('./CollegeScorecardDataDictionary-09-08-2015.csv')
id_name_link <- read_csv('./id_name_link.csv')
most_recent_cohorts <- read_csv('./Most+Recent+Cohorts+(Scorecard+Elements).csv')

trend_data$monthorweek <- str_sub(trend_data$monthorweek,1,10) %>%
                          ymd() %>%
                          floor_date(unit= 'month')
colnames(trend_data)[5] <- "month"

trend_data <- trend_data %>% group_by(schname,keyword) %>%
              mutate(standard_index = (index - mean(index))/sd(index))

id_name_link <- group_by(id_name_link,schname) %>%
                mutate(n = n()) %>%
                filter(n <= 1)
id_name_link <- id_name_link[,-4]
      
trend_data <- inner_join(trend_data,id_name_link,by= "schname")
trend_data <- inner_join(trend_data,most_recent_cohorts,by= c("unitid"="UNITID","opeid"="OPEID"))
            
