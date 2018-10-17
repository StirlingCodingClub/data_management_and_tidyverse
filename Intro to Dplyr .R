# 16/10/2018
# MG
# Intro to Dplyr for SCC

# Install tidyverse 
install.packages("tidyverse")

#load tidyverse
require(tidyverse)
# this is an "umbrella-package" including tidyr, dplyr, ggplot2, tibble, etc. that share interfaces and data structure to allow data anlysis to flow easily from one task to another.

# working though example from datacarpentry (https://datacarpentry.org/R-ecology-lesson/03-dplyr.html)

#downloaded data sets and saved them to my desktop 
setwd("C:/Users/mg57/Box Sync/Coding club/tidyverse eg/1314459")
setwd("C:/Users/Owner/Box Sync/Coding club/tidyverse eg/1314459")

# load data using read_csv() function, from the tidyverse package readr, instead of  read.csv()
surveys <- read_csv("combined.csv")

# inspect the data
str(surveys)

# use print() finction to view tibble in console. 
print(surveys)

# in readr::read_csv() data frames are automatically read in as tbl_df ("tibbles")
# main differences:

# Displays the data type of each column under its name: 
  # int - integer
  # dbl - real numbers
  # chr - character 
  # dttm - date-times 

# it only prints the first few rows of data and only as many columns as fit on one screen.
# Columns of class character are never converted into factors.



#### Using Dply functions to start manipulating data in R  ####

# there are 6 key verbs that will solve the majoriy of data mainpulation problems:

# select(): subset columns
# filter(): subset rows on conditions
# mutate(): create new columns by using information from other columns
# group_by() and summarize(): create summary statisitcs on grouped data
# arrange(): sort results

# all functions work in the same way:

# verb(data frame, variables)
# build on this to acheive more complex results...

# Start off with selecting columns and filtering rows 

select(surveys, # data frame
       plot_id, species_id, weight # vaiables
       ) 

filter(surveys, year == 1995)

#### Intro to pipes ####

# Piping allows you to easily nest functions to stop your workspace becoming too cluttered  but still makes the code readable. You can read the pipe like the word "then"

# Pipes in R look like  %>% and are made available via the magrittr package (in the tidyverse). If you use RStudio, you can type the pipe with Ctrl + Shift + M if you have a PC or Cmd + Shift + M if you have a Mac.

# we have to change the verb-data frame-variable rule above to data frame-verb-variable:

surveys_sml <- surveys %>%
  filter(weight < 5) %>%
  select(species_id, sex, weight)

# in the above example, we took the data frame surveys, then we filtered for rows with weight < 5, then we selected columns species_id,  sex, and weight and made a new data frame: surveys_sml 

surveys_sml

# you can also use pipes with non-dplyr functions
# eg. if you want to just see the first couple of linkes of the tbl

surveys %>%
  filter(weight < 5) %>%
  select(species_id, sex, weight) %>%
  head()

#### Mutate #### 

# Use mutate to create a new column based on the values of exisitng columns for example changing units or finding the ratio between columns 

surveys %>%
  mutate(weight_kg                                # new column name
         = weight / 1000                          # create values 
         )

# You can also create a second new column based on the values in the 1st new column using a single line of code 

surveys %>%
  mutate(weight_kg = weight / 1000,
         weight_kg2 = weight_kg * 2)

# Using the piping we can build on this to make the function more complex. 
# If we wanted to create a new table with the NAs removed we can use the filter fuction (is.na function to selected the NAs and the ! to select everything that is not an NA) 

surveys %>%
  filter(!is.na(weight)) %>%
  mutate(weight_kg = weight / 1000)

#### Group_by() and summerize() ####

# We often want to group data get a summary statistic for the group and then recombine into a single new data frame for plotting. 
# If we wanted to know how mean weight differed between sexes.

surveys %>%
  group_by(sex) %>%                                  # specifies the groups i.e. the new rows
  summarize(mean_weight = mean(weight, na.rm = T))   # like mutate will create a new column based on previous data fraom vailues (from weight)

# We can also group by multiple columns for example if we wanting to include information on sepcies
surveys %>%
  group_by(sex, species_id) %>%                       # this time the specific row information is split over two columns
  summarize(mean_weight = mean(weight, na.rm = TRUE))

# when we do this we have a load of data at the bottom of the tbl that contains NaN (not a number) because the individuals were id'd but not sexed or weighed:
surveys %>%
  group_by(sex, species_id) %>%
  summarize(mean_weight = mean(weight, na.rm = TRUE)) %>%
  tail()

# again we can use filter to remove these NA before we make the new data frame

surveys %>%
  filter(!is.na(weight)) %>%
  group_by(sex, species_id) %>%
  summarize(mean_weight = mean(weight)) %>%
  print(n =64)

surveys %>%
  filter(!is.na(weight)) %>%
  group_by(sex, species_id) %>%
  summarize(mean_weight = mean(weight)) %>%
  tail()

# We can also get more calculate a number or variables... so if you wanted additional summary statistics:

surveys %>%
  filter(!is.na(weight)) %>%
  group_by(sex, species_id) %>%
  summarize(mean_weight = mean(weight),
            sd_weight = sd(weight),
            se_weight = sd_weight/sqrt(n()))

# and we can pipe in additional functions such as arrange()

surveys %>%
  filter(!is.na(weight)) %>%
  group_by(sex, species_id) %>%
  summarize(mean_weight = mean(weight),
            sd_weight = sd(weight),
            se_weight = sd_weight/sqrt(n())) %>%
  arrange(desc(mean_weight))

### data visualisation ####

# you can then pipe in ggplot at the end for rapid flexible data visualization  
  
surveys %>%
  filter(!is.na(weight)) %>%
  group_by(sex, species_id) %>%
  summarize(mean_weight = mean(weight),
            sd_weight = sd(weight),
            se_weight = sd_weight/sqrt(n())) %>%
  arrange(desc(mean_weight)) %>%
  ggplot(aes(x=species_id, y=mean_weight, colour = sex)) +
  geom_errorbar(aes(ymin=mean_weight - se_weight, ymax= mean_weight +se_weight), width=.1) +
  geom_point()


### Reshaping data with gather and spread ####

# The surveys data frame is in a tidy format, the rows contain the values variables (sex, weight etc) associated with each record (observation). But if instead of comparing records, we wanted to compare the different mean weight of each species between plots? 

# Now our obervation needs to become the plot and the variables the mean weight of each species associated with that plot (still tidy data just our observation has changed)

# we can use the spread() function to acheive this 
  
# spread() takes three principal arguments:
  
  # the data
  # the key column variable whose values will become new column names.
  # the value column variable whose values will fill the new column variables.

# use group_by() and summerise() to create data frame of mean weights (as above)

surveys_gw <- surveys %>%
  filter(!is.na(weight)) %>%
  group_by(genus, plot_id) %>%
  summarize(mean_weight = mean(weight))

surveys_gw                 #the observations for each plot are spread across a number of rows 

# use spread to get a single row per plot 
surveys_spread <- surveys_gw %>%                # the data 
  spread(key = genus,                           # the key column variable that becomes new column names 
         value = mean_weight,                   # the value column that will fill the new column variables 
        fill = 0,                               # this is an additional agument which can be set... in this case we want to set mean weight to 0 because that species was not recorded in the plot
  )
         
surveys_spread

# Gather will do the oppostie 














