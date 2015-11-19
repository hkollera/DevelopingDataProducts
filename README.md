## Introduction

This project is part of the course Developing Data Products, which is part of Coursera John Hopkins Specialization in Data Science.

It is a shiny app to visualize the distribution of foreigners living in Berlin, grouped by district and age group.   

## Data

The data for this project origines from the Amt für Statistik Berlin-Brandenburg:

* Population data [Foreigners by district](https://www.statistik-berlin-brandenburg.de/opendata/EWR_Ortsteile_2014-12-31.csv)
* Geographical data [Shape files of districts](https://www.statistik-berlin-brandenburg.de/opendata/RBS_OD_BEZ_1412.zip)
* Geographical data [Shape files of charters](https://www.statistik-berlin-brandenburg.de/opendata/RBS_OD_ORT_1412.zip)

The reference date of the population data is 2014-12-31. Data for previous years is also available.

## Usage

The app can be tested on the shiny website at ... 
For local usage run r or rstudio with the following commands:

1. Change into directory: _setwd("<localpath>/DevelopingDataProducts")_
   with <localpath> replaced 
2. Load shiny library: _library("shiny")_
3. Run app: _runApp()_

NOTE: The app uses ggmap, which is described in
  D. Kahle and H. Wickham. ggmap: Spatial Visualization with ggplot2.
  The R Journal, 5(1), 144-161. URL
  http://journal.r-project.org/archive/2013-1/kahle-wickham.pdf





