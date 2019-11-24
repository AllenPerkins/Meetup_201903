#------------------------------------------------------------------------------
# Author: Allen Perkins
# Date:   2019-03-01
# Obj:    Create visualizations using the Federal Reserve numeric data and
#         text analysis of the Federal Reserve Beige book commentary.
#
#         # Question: Does the commentary in the Beige Book lead or lag the
#         # published numerical economic measures.
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
# 2019-03-01  Allen Perkins   Original (001.000 .000)
# 
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

library(ggplot2)    # Graphing and visualization.
library(gridExtra)  # Layout multiple graphs.
library(odbc)       # An ODBC database driver.
library(DBI)        # A library of handy database functions.

Sys.setenv(TZ = 'GMT') # Set timezone

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# None

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

#None

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
# Create some data frames from the tables in the database.
#------------------------------------------------------------------------------

#-----------------------------------------
# Load our Beige Book sentiment.
#-----------------------------------------
Table <- DBI::Id(schema = "NLP", table = "LMScore_S3")
  # Create a table name to use in our queries.
BeigeBook <- dbReadTable(Con, Table)
str(BeigeBook)
BeigeBook$Start <- as.Date(BeigeBook$Start)
BeigeBook$End <- as.Date(BeigeBook$End)

#-----------------------------------------
# Load our economic trend: Unemployment.
#-----------------------------------------
Table <- DBI::Id(schema = "Econ", table = "Unemployment_S5")
  # Create a table name to use in our queries.
Unemployment <- dbReadTable(Con, Table)
str(Unemployment)
Unemployment$Trend <- as.factor(Unemployment$Trend)

#-----------------------------------------
# Load our economic trend: Inflation.
#-----------------------------------------
Table <- DBI::Id(schema = "Econ", table = "Inflation_S5")
# Create a table name to use in our queries.
Inflation <- dbReadTable(Con, Table)
str(Inflation)
Inflation$Trend <- as.factor(Inflation$Trend)

#-----------------------------------------
# Load our economic trend: Interest.
#-----------------------------------------
Table <- DBI::Id(schema = "Econ", table = "Interest_S5")
# Create a table name to use in our queries.
Interest <- dbReadTable(Con, Table)
str(Interest)
Interest$Trend <- as.factor(Interest$Trend)

#------------------------------------------------------------------------------
# Visualize our data frames.
#------------------------------------------------------------------------------


#-----------------------------------------
# Unemployment graph.
#-----------------------------------------
Unemployment_V <- ggplot(BeigeBook) +
  geom_rect(
    aes(
      xmin = Start, xmax = End, fill = Outlook),
      ymin = -Inf, ymax = Inf, alpha = 0.1,
      show.legend = TRUE
) +
ggtitle("Unemployment") +
# labs(x = "") +
geom_vline(
  aes(xintercept = as.numeric(Start)),
  data = BeigeBook,
  color = "grey50", alpha = 0.5
) +
geom_text(
  aes(x = Start, y = "", label = ""),
  data = BeigeBook,
  size = 3, vjust = 0, hjust = 0, nudge_x = 100
) +
theme(
  axis.title.y = element_blank(),
  axis.text.y = element_blank(),
  axis.ticks.y = element_blank(),
  axis.title.x = element_blank(),
  plot.margin = unit(c(0.25, 0.25, 0.25, 0.25), "inches"),
  legend.position = "None"
) +
scale_fill_manual(values = c("red", "green")) +
geom_point(
  aes(x = Date, y = TrendN,
  show.legend = FALSE,
  shape = Trend,
  size = Trend,
  color = Trend,
  fill = Trend,
  ymin = -0.5
  ),
data = Unemployment) +
  scale_shape_manual(values = c(25, 24)) +
  scale_color_manual(values = c("green", "red")) +
  scale_fill_manual(values = c("red", "green")) +
  scale_size_manual(values = c(6, 6)) +
geom_path(aes(x = Date, y = TrendN, group = TRUE,
  color = Trend,
  ),
  data = Unemployment,
  size = 1
  ) +
  scale_color_manual(values = c("darkgreen", "darkred"))

#-----------------------------------------
# Inflation graph.
#-----------------------------------------
Inflation_V <- ggplot(BeigeBook) +
  geom_rect(
    aes(
      xmin = Start, xmax = End, fill = Outlook),
      ymin = -Inf, ymax = Inf, alpha = 0.2,
      show.legend = TRUE
) +
ggtitle("Inflation") +
# labs(x = "") +
geom_vline(
  aes(xintercept = as.numeric(Start)),
  data = BeigeBook,
  color = "grey50", alpha = 0.5
) +
geom_text(
  aes(x = Start, y = "", label = ""),
  data = BeigeBook,
  size = 3, vjust = 0, hjust = 0, nudge_x = 100
) +
theme(
  axis.title.y = element_blank(),
  axis.text.y = element_blank(),
  axis.ticks.y = element_blank(),
  axis.title.x = element_blank(),
  plot.margin = unit(c(0.25, 0.25, 0.25, 0.25), "inches"),
  legend.position = "None"
) +
scale_fill_manual(values = c("red", "green")) +
geom_point(
  aes(x = Date, y = TrendN,
  show.legend = FALSE,
  shape = Trend,
  size = Trend,
  color = Trend,
  fill = Trend,
  ymin = -0.5
  ),
  data = Inflation) +
scale_shape_manual(values = c(25, 24)) +
  scale_color_manual(values = c("green", "red")) +
  scale_fill_manual(values = c("red", "green")) +
  scale_size_manual(values = c(6, 6)) +
geom_path(aes(x = Date, y = TrendN, group = TRUE,
  color = Trend,
  ),
  data = Inflation,
  size = 1
  ) +
  scale_color_manual(values = c("darkgreen", "darkred"))

#-----------------------------------------
# Interest graph.
#-----------------------------------------
Interest_V <- ggplot(BeigeBook) +
  geom_rect(
    aes(
      xmin = Start, xmax = End, fill = Outlook),
      ymin = -Inf, ymax = Inf, alpha = 0.2,
      show.legend = TRUE
) +
ggtitle("Interest") +
# labs(x = "") +
geom_vline(
  aes(xintercept = as.numeric(Start)),
  data = BeigeBook,
  color = "grey50", alpha = 0.5
) +
geom_text(
  aes(x = Start, y = "", label = ""),
  data = BeigeBook,
  size = 3, vjust = 0, hjust = 0, nudge_x = 100
) +
theme(
  axis.title.y = element_blank(),
  axis.text.y = element_blank(),
  axis.ticks.y = element_blank(),
  axis.title.x = element_blank(),
  plot.margin = unit(c(0.25, 0.25, 0.25, 0.25), "inches"),
  legend.position = "None"
) +
scale_fill_manual(values = c("red", "green")) +
geom_point(
  aes(x = Date, y = TrendN,
  show.legend = FALSE,
  shape = Trend,
  size = Trend,
  color = Trend,
  fill = Trend,
  ymin = -0.5
  ),
  data = Interest) +
scale_shape_manual(values = c(25, 24)) +
  scale_color_manual(values = c("green", "red")) +
  scale_fill_manual(values = c("red", "green")) +
  scale_size_manual(values = c(6, 6)) +
geom_path(aes(x = Date, y = TrendN, group = TRUE,
  color = Trend,
  ),
  data = Interest,
  size = 1
  ) +
  scale_color_manual(values = c("darkgreen", "darkred"))

#------------------------------------------------------------------------------
# Display the graph objects.
#------------------------------------------------------------------------------

dev.new()
# Start a mew plot window.
Unemployment_V

dev.new()
Inflation_V

dev.new()
Interest_V

dev.new()
grid.arrange(Unemployment_V, Inflation_V, Interest_V, nrow = 1)

