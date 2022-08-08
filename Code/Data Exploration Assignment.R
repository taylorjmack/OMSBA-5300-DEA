library(plyr)
library(purrr)
library(dplyr)
library(tidyverse)
library(lubridate)
library(fixest)

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

trend_data <- trend_data %>% group_by(schname,keyword,month) %>%
               mutate(n = n()) %>%
               mutate(year = year(month)) %>%
               mutate(month_number = month(month)) %>%
               mutate(year_month = format(month,"%Y-%m")) %>%
               mutate(median_salary = `md_earn_wne_p10-REPORTED-EARNINGS`) %>%
               mutate(scorecard_live = case_when
               (year_month < '2015-09'~ 0,
                year_month >= '2015-09' ~ 1)) %>%
               filter(!is.na(as.numeric(median_salary))) %>%
               mutate(income_category = case_when
               (median_salary <= 30000 ~ "low",
                median_salary > 30000 &
                median_salary < 75000 ~ "medium",
                median_salary >= 75000 ~ "high")) %>%
               filter(is.na(median_salary) == FALSE)


trend_data %>% group_by(month,schname,keyword,income_category) %>%
               summarize(std_dev_activity = sd(n)) %>%  
               ggplot(mapping = aes(x = month,y= std_dev_activity, group= income_category)) +
              geom_line(aes(color=income_category)) + geom_point() 


trend_data %>% group_by(income_category,month) %>%
  summarize(avg_std_index = mean(standard_index)) %>%  
  ggplot(mapping = aes(x = month,y= avg_std_index, group= income_category)) +
  geom_line(aes(color=income_category)) + geom_point() 


trend_data %>% group_by(month,schname,keyword,income_category) %>%
  summarize(total_search_activity = sum(n)) %>%
  ggplot(mapping = aes(x = month,y= total_search_activity, group= income_category)) +
  geom_line(aes(color=income_category)) + geom_point() 

reg  <- feols(data= trend_data,log(n)~income_category*scorecard_live+standard_index + region)
etable(reg)

         

