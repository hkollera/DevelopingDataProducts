### Exploring the Population of Berlin, Germany

This application is based on data from [berlin open data](http://daten.berlin.de/). 

The [population data](https://www.statistik-berlin-brandenburg.de/opendata/EWR_Ortsteile_2014-12-31.csv) and the geographical data about [districts](https://www.statistik-berlin-brandenburg.de/opendata/RBS_OD_BEZ_1412.zip) and [charters](https://www.statistik-berlin-brandenburg.de/opendata/RBS_OD_ORT_1412.zip) of Berlin are published by the Amt für Statistik Berlin-Brandenburg.

The app is part of the work for the Coursera Developing Data Product Course.

It consists of two pages. The first one displays a population pyramid where you can oppose the absolut numbers of age groups, divided by gender and nationality. The second displays the percentage of foreign people on a map of Berlin in each quarter. Both pages give the choice to subset the data by age groups and districts.

Source code is available on [GitHub](https://github.com/hkollera/DevelopingDataProducts).

## Architecture

### Components

```plantuml format="svg"

@startuml

!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

ContainerQueue(eq, "gitlab", "Google PubSub")

Container_Boundary(my_system, "Four Keys eventhandler") {

    Component(evh, "fourkeys-eventhandler", "Webserver", "receives external notification events")

}

System(sec, "secret manager", "")

System_Ext(ext_system, "Gitlab CI/CD", "Notification via webhook")

Rel_R(ext_system, evh, "Sends notifications about events")

Rel_R(evh, eq, "Stores events into the queue")

Rel_R(evh, sec, "fetches stored secret")

@enduml

```
