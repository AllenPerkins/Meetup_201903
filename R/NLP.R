#------------------------------------------------------------------------------
# Author: Allen Perkins
# Date:   2019-01-29
# Obj:    Gather textual data from ten years of the Federal Reserve Beige
#         Book. There are generally eight books per year, released on an
#         irregular schedule.
#
#         Find the pages, scrape each page, clean and parse the page
#         contents, save contents of each page to a file on disk.
#
#         Use different word lists to identify whether the Beige Book
#         sentiment for the economic outlook is generally positive or
#         negative.
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

library(tibble)     # Tool for working with data frames.
library(dplyr)      # Tool for shaping data.
library(tidytext)   # Text mining utilities.

library(odbc)       # An ODBC database driver.
library(DBI)        # A library of handy database functions.

Sys.setenv(TZ = 'GMT') # Set timezone

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

Table <- DBI::Id(schema = "NLP", table = "Top10")
  # Create a table name variable to use in our queries.
ColName <- c("Word", "Sentiment", "Frequency")
  # Create a variable to hold the column names of the database table.

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

# None

#------------------------------------------------------------------------------
# Process
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Connect to our PostgreSQL database.
#------------------------------------------------------------------------------

Con <- dbConnect(odbc::odbc(), dsn = "PG")
# Create a connection to the PostgewSQL database.
# The PG is an ODBC data source created using Windows Control Panel.

#------------------------------------------------------------------------------
# Perform natural language processing on Beige Book files we downloaded.
#------------------------------------------------------------------------------

data(stop_words)
  # Load a list of stop words into memory. These are non-substantive words 
  # that will be removed from the Beige Book text before processing.
  # Thank you tidytext!
tail(stop_words, 5)
str(stop_words)
unique(stop_words$lexicon)

SourcePath <- "C:\\temp\\"
  # The path where the Beige Book text files are located.
BBFiles <- list.files(path = SourcePath, pattern = "*.txt",
  full.names = TRUE, recursive = FALSE)
  # Create a list of all the file names in the SourcePath.
str(BBFiles)
  # Have a look at the list.
lapply(
  BBFiles, function(BBFile) {
    # Loop over the list of files and perform the following
    # steps on each file.
    BBText <- readLines(BBFile, encoding = "UTF-8")
      # Get the contents of the file into a variable.
      # We saved the HTML byte stream as UTF-8.
    BBLength <- length(BBText)
      # How many lines in the file?
    YearMonth <- strsplit(BBFile, "\\\\")[[1]][3]
      # Build a string from the name of the file. Just want the file name
      # without the path.
    YearMonth <- strsplit(YearMonth, ".txt")
      # Remove the extension from the file name.
    YearMonth <- as.character(YearMonth)
      #  This is still a list data type, convert to a character string.
    BB_T <- tibble(line = 1:BBLength, text = BBText)
      # Convert the BBText into a tibble, so it can be tokenized.
    BB_TF <- BB_T %>% unnest_tokens(word, text)
      # Tokenize the tibble. %>% is a pipe.
    BB_TFC <- BB_TF %>% anti_join(stop_words)
      # Remove word tokens that are in the stop_words list.
    BB_S <- BB_TFC %>%
      # inner_join(get_sentiments("bing")) %>%
    inner_join(get_sentiments("loughran")) %>%
      count(word, sentiment, sort = TRUE) %>%
      ungroup()
      # Match up Beige Book words with word in the list from Bing or
      # Loughran-McDonald. Each word in the Bing list is associated with
      # either a positive or negative sentiment. Each word in the 
      # Loughran-McDonald  list is associated with one of six sentiments
      # (negative, positive, uncertainty, litigious, constraining,
      # superfluous). The sentiment words are joined to the tokenized and
      # stop word cleansed word list from the Beige Book (BB_TFC).
    BB_DB <- BB_S %>%
      group_by(sentiment) %>%
      top_n(10) %>%
      ungroup() %>%
      mutate(word = reorder(word, n))
        # Grab the top ten most frequently occurring words, grouped by
        # sentiment. Since bing has two sentiments, positive and negative,
        #  there will be 20 rows.
    BB_DB <- setNames(BB_DB, ColName)
      # Update the tibble so the column names match the database table.
    BB_DB <- tibble::add_column(BB_DB, YearMon = as.character(YearMonth))
      # Add a column to the data frame with the year and month, they are
      # part of the file name.
    dbBegin(Con)
      # Begin a database transaction.
    dbWriteTable(Con, Table, as.data.frame(BB_DB), append = TRUE)
      # Insert the contents of the Top10 negative and positive words and
      # their frequency into the database. The table must exist because we
      # specified the "append" option.
      # We converted the tibble to a data frame, since that is the type of
      # object the DBI library supports.
    dbCommit(Con)
      # Commit the transaction we started.
  }
)
