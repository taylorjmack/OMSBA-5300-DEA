library(plyr)
library(purrr)
library(dplyr)
library(tidyverse)
setwd('./Data/')
trend_data <- list.files(pattern = 'trends_up_to_') %>%
           map(read_csv) %>%
           bind_rows()

scorecard_dict <- read_csv('./CollegeScorecardDataDictionary-09-08-2015.csv')
id_name_link <- read_csv('./id_name_link.csv')
most_recent_cohorts <- read_csv('./Most+Recent+Cohorts+(Scorecard+Elements).csv')

data <- ldply('./Data/'+f_list, read.csv)