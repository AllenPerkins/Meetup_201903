#------------------------------------------------------------------------------
# Author: Allen Perkins
# Date:   2019-01-29
# Obj:    Gather numeric trend data for some economic indicators from the
#         Federal Reserve. Use the government provided API to obtain the raw
#         data, shape the data as needed, and save it to a database.
# 
#------------------------------------------------------------------------------
# How to execute this script from the command line:
#
# This script is not intended to be run from a command prompt.
# It is for demonstration purposes.
# 
#------------------------------------------------------------------------------
#   Revision history:
# 
# Date        Author          Purpose                                     Tag
#------------------------------------------------------------------------------
# 2019-01-29  Allen Perkins   Original (001.000 .000)
# 
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

library(jsonlite)       # JSON parser for web API.
library(tibble)         # Tool for working with data frames.
library(dplyr)          # Tool for shaping data.

library(odbc)           # An ODBC database driver.
library(DBI)            # A library of handy database functions.

Sys.setenv(TZ = 'GMT')  # Set timezone

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# "https://fred.stlouisfed.org/"
# 528,000 times series datasets from 87 data sources.

# "https://research.stlouisfed.org/docs/api/"
# Developer API

# Federal Reserve API to search available time series datasets.
URL <- "https://api.stlouisfed.org/fred/series/search"
Search <- "?search_text=unemployment+rate"
APIKey <- "&api_key=388a780377573cc93d8b35242af581f6"
Offset <- "&offset=0"
Filter <- "&filter_variable=frequency&filter_value=Monthly"
ReturnType <- "&file_type=json"
WebRequest <- paste(
  URL, Search, APIKey, Offset, Filter, ReturnType, sep = ""
)
SearchResults <- fromJSON(WebRequest)
# Call the endpoint.
str(SearchResults)
# Examine structure of result.
SearchResults[[10]][1:3, 1:4]
# Subset list 10, pull columns 1 through 4, of items 1 through 3.
SearchResults$seriess[1:3, 1:4]
# Subset list 10, pull columns 1 through 4, of items 1 through 3.
SearchResults[[10]][1:2, c(1, 4)]
# Subset list 10, pull columns 1 and 4, of items 1 through 2.

# The monthly, seasonally adjusted, unemployment series = UNRATE
# The monthly, seasonally adjusted, consumer price series = CPIAUCSL
# The monthly, federal funds rate = FEDFUNDS
# The monthly, seasonly adjusted, hours worked = M08154USM065NNBR


# Federal Reserve API to pull data series requires several parts in its
# URL. The following parts are concatenated in a loop (see below) and
# then the endpoint is called.
URL <- "https://api.stlouisfed.org/fred/series/observations"
SeriesPrefix <- "?series_id="
  # For example: Series <- "?series_id=UNRATE"
Series <- "UNRATE"
  # We will concatenate the SeriesPrefix and a Series name in a loop
  # since we have multiple series.
APIKey <- "&api_key=388a780377573cc93d8b35242af581f6"
  # Sign up on the developer website for one of these; they are free.
ObservationStart <- "&observation_start=2009-01-01"
  # Get the last ten years of data.
ReturnType <- "&file_type=json"
  # It is retrieved as JSON but converted to a list data type within R.
WebRequest <- paste(
  URL, SeriesPrefix, Series, APIKey,
  ObservationStart, ReturnType, sep = ""
)

WebRequest
  # Example string we will build to retrieve data from the API.

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

# None

#------------------------------------------------------------------------------
# Process
#------------------------------------------------------------------------------

SeriesList <- c("UNRATE", "CPIAUCSL", "FEDFUNDS")
  # Make a list of the series we will download.
str(SeriesList)

FedData <- as.data.frame
  # An empty data frame to hold results.
toss <- lapply(
  # Loop over each series and add its data to our data frame.
  SeriesList, function(SeriesList) {
    WebRequest <- paste(URL, SeriesPrefix, SeriesList, APIKey,
      ObservationStart, ReturnType, sep = "")
      # We concatenated a string that is a valid API request we can
      # send to the Federal Reserve API endpoint.
  FedData <<- cbind(FedData, SeriesList)
    # We added a column to our data frame.
    # The double << references the variable outside the scope of the loop.
  FedData$SeriesList <<- fromJSON(WebRequest)
    # The fromJSON function hits the URL using the string we built and
    # and puts the results in the new column we added to our data frame.
  }
)
rm(toss)
  # Delete the output of the loop.
str(FedData)
  # Examine the data we collected.
FedData[[2]]
head(FedData[[3]]$observations, 3)
FedData[[6]]
head(FedData[[7]]$observations, 3)
FedData[[14]]
head(FedData[[15]]$observations, 3)

FedData_DF <- cbind(
  FedData[2],  FedData[[3]]$observations,
  FedData[6],  FedData[[7]]$observations,
  FedData[14], head(FedData[[15]]$observations,121)
)
  # Create a new data frame from the raw data;
  # selecting only the columns we want.
str(FedData_DF)
  # Note the realtime_start and realtime_end are temporal database
  # structures. These are not new concepts.
  # 32 years ago: https://cloudfront.escholarship.org/dist/prd/content/qt2hc04856/qt2hc04856.pdf
  # 25 years ago: https://www.semanticscholar.org/paper/Unifying-Temporal-Data-Models-via-a-Conceptual-Jensen-Soo/159123757b4c32b153eaf707e9a6b2bfded19cc1

FedData_DF <- data.frame(
  "Date"         = FedData_DF[4]$date,
  "Unemployment" = FedData_DF[5]$value,
  "Inflation"    = FedData_DF[10]$value,
  "Interest"     = FedData_DF[15]$value
)
  # Replace the data frame and rename the columns.

  # CAUTION! If the times series datasets that are downloaded differ in
  # length, then you will need to slice off one or more observations to
  # make them equal. For example, at the time of this writing all
  # three datasets had 121 observations. However, by way of example, 
  # if the Unemployment dataset gets updated next month before the Inflation
  # dataset, then one dataset will have 122 observations and the other 121
  # observations. You cannot combine lists of differing lengths into the data
  # frame.

str(FedData_DF)
  # Note the factors.
head(FedData_DF,5)

FedData_DF$Date <- as.Date(FedData_DF$Date)
  # Convert date column from chr to date
FedData_DF$Unemployment <- as.numeric(as.character(FedData_DF$Unemployment))
FedData_DF$Inflation    <- as.numeric(as.character(FedData_DF$Inflation))
FedData_DF$Interest     <- as.numeric(as.character(FedData_DF$Interest))
  # Convert the measurement columns from chr to numeric.
str(FedData_DF)
head(FedData_DF)
  # Compare our new data frame.
str(FedData)
  # To what we started with.
FedData_T <- as_data_frame(FedData_DF)
  # Convert data frame to tibble.
str(FedData_T)
head(FedData_T, 10)

#------------------------------------------------------------------------------
# Connect to our PostgreSQL database.
#------------------------------------------------------------------------------
Table <- DBI::Id(schema = "Econ", table = "MultiSeries")
  # Create a table name to use in our queries.
Con <- dbConnect(odbc::odbc(), dsn = "PG")
  # Create a connection to the PostgewSQL database.
  # The PG is an ODBC data source created using Windows Control Panel.
dbBegin(Con)
  # Begin a database trasnaction.
dbWriteTable(Con, Table, as.data.frame(FedData_T), append = TRUE)
  # Insert the contents of the FedData_T tibble into the
  # Econ.MultiSeries table.
dbCommit(Con)
  # Commit the transaction.
