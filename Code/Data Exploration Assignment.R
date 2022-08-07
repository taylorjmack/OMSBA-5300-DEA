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
trend_data$'md_earn_wne_p10-REPORTED-EARNINGS' <- as.numeric(trend_data$'md_earn_wne_p10-REPORTED-EARNINGS')

trend_data <- trend_data %>% group_by(schname,year(month)) %>%
               mutate(n = n()) %>%
               mutate(year = year(month)) %>%
               mutate(median_salary = `md_earn_wne_p10-REPORTED-EARNINGS`) %>%
               mutate(income_category = case_when
               (median_salary <= 30000 ~ "low",
                median_salary > 30000 &
                median_salary < 75000 ~ "medium",
                median_salary >= 75000 ~ "high")) %>%
               filter(is.na(median_salary) == FALSE)

trend_data %>% group_by(income_category) %>%
               summarize(avg_students = mean(n)) %>%  
               ggplot(mapping = aes(x = income_category,y= avg_students)) +
              geom_point()



trend_data %>% group_by(schname) %>%
               summarize(std_index = mean(standard_index)) %>%
         

