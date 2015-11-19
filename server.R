# load libraries
library(shiny)
library(ggplot2)
library(reshape2)
library(dplyr)
library(tidyr)
library(sp)
library(rgdal)
library(maptools)
library(mapproj)
library(ggmap)
library(gpclib)
library(RColorBrewer)

# aggregation functions
aggregate_by_age <- function(dt, age_min, age_max, districtlist) {
    dtPopD <- dt %>% 
        filter(Age >= age_min, Age <= age_max, District %in% districtlist ) %>% 
        group_by (Age_Group,Gender) %>% 
        filter(Nationality=="D") %>%
        summarise_each(funs(sum), Population) %>%
        spread(Gender, Population)  %>%
        rename(NativeFemale = F, NativeMale = M)
    dtPopA <- dt %>% 
        filter(Age >= age_min, Age <= age_max, District %in% districtlist ) %>% 
        group_by (Age_Group,Gender)  %>% 
        filter(Nationality=="A") %>%
        summarise_each(funs(sum), Population) %>%
        spread(Gender, Population) %>%
        rename(ForeignerFemale = F, ForeignerMale = M)
    dtPopT <- inner_join(dtPopA, dtPopD, by="Age_Group")
    # fill missing values 
    dtPopT[is.na(dtPopT)] <- 0
    dtPopT
}

aggregate_as_percentage <- function(dt, age_min, age_max, districtlist) {
    dtPopDD <- dt %>% 
        filter(Age >= age_min, Age <= age_max, District %in% districtlist ) %>% 
        group_by (Quarter,Gender) %>%
        filter(Nationality=="D") %>%
        summarise_each(funs(sum), Population) %>%
        spread(Gender, Population) %>%
        rename(FD = F, MD = M)
    dtPopAD <- dt %>% 
        filter(Age >= age_min, Age <= age_max, District %in% districtlist ) %>% 
	    group_by (Quarter,Gender) %>%
	    filter(Nationality=="A") %>%
        summarise_each(funs(sum), Population) %>%
        spread(Gender, Population) %>%
        rename(FA = F, MA = M)
    dtPopTD <- inner_join(dtPopAD, dtPopDD, by="Quarter")
    dtPopTD <- dtPopTD %>% 
        mutate(PMF = round(100*MA/(MA+MD),1)) %>%
        mutate(PFF = round(100*FA/(FA+FD),1)) %>%
        mutate(PTF = round(100*(MA+FA)/(MA+MD+FA+FD),1))
    dtPopTD
}

#
# Load map and data
#
dtPop <- read.table("data/EWR_Ortsteile_2014-12-31.csv",sep=";",dec=",", header=TRUE,fileEncoding="ISO-8859-1")

dmap <- readOGR(dsn = "data/bezirke", layer = "RBS_OD_BEZ_1412")
gpclibPermit()
dmap <- fortify(dmap, region="BezName")

qmap <- readOGR(dsn = "data/ortsteile", layer = "RBS_OD_ORT_1412")
qmap <- fortify(qmap, region="Ortsteilna")
qmap$id <- as.factor(qmap$id)
#
# clean data
#
# Replace 1/2 with Male/Female
dtPop$Geschl <- replace(dtPop$Geschl, dtPop$Geschl == 1, "M")
dtPop$Geschl <- replace(dtPop$Geschl, dtPop$Geschl == 2, "F")

# Geschl as.factor
dtPop$Geschl <- as.factor(dtPop$Geschl)

# Extract Alter from Altersgr, first 2 characters as numeric value
dtPop$Alter <- as.numeric(substr(dtPop$Altersgr, 1,2))
names(dtPop) <- c("DistrictID","District","QuarterID","Quarter","Gender","Nationality","Age_Group","Population","Age")
districts <- as.character(sort(unique(dtPop$District)))
quarters <- as.character(sort(unique(dtPop$Quarter)))

# Shiny server 
shinyServer(function(input, output, session) {
    values <- reactiveValues()
    values$districts <- districts

    output$districtCheckboxes <- renderUI({
        checkboxGroupInput('districtCBG', 'City districts', districts, selected=values$districts)
    })

    observe({
        if(input$clearselect == 0) return()
        values$districts <- c()
    })
    
    observe({
        if(input$allselect == 0) return()
        values$districts <- districts
    })
  
    output$ui <- renderUI({
        if (is.null(input$compareCategory))
        return()

    # Depending on input$input_type, we'll generate a different
    # UI component and send it to the client.
    switch(input$compareCategory,
          "Nationality" = radioButtons(
                "categ",
	 	        "Choose Gender",
                c("Male" = "male","Female" = "female","Both" = "both")
              ),
        "Gender" = radioButtons(
	  		   "categ",
			   "Choose Nationality",
                c("Native" = "native","Foreigner" = "foreigner","Both" = "both")
              )
        )
    })

    # plot diagram
    output$populationPyramid <- renderPlot({
        validate(
            need(input$districtCBG, 'Please select at least one district')
        )
        dt<-aggregate_by_age(dtPop, input$age[1], input$age[2], input$districtCBG) %>%
            mutate(VL = {switch (input$compareCategory, 
                "Gender" = {
                    if (input$categ == 'both') {
                        NativeFemale + ForeignerFemale
                    } else if(input$categ == 'native') {
                        NativeFemale
                    } else {
                        ForeignerFemale
                    }},
                "Nationality" = {
                    if (input$categ == 'both') {
                        NativeMale + NativeFemale
                    } else if(input$categ == 'male') {
                        NativeMale
                    } else {
                        NativeFemale
                    }
                })}) %>%
            mutate(VR = {switch (input$compareCategory, 
                "Gender" = {
                    if (input$categ == 'both') {
                        NativeMale + ForeignerMale
                    } else if(input$categ == 'native') {
                        NativeMale
                    } else {
                        ForeignerMale
                    }},
                "Nationality" = {
                    if (input$categ == 'both') {
                        ForeignerMale + ForeignerFemale
                    } else if(input$categ == 'male') {
                        ForeignerMale
                    } else {
                        ForeignerFemale
                    }
            })}) %>%
            select(Age_Group,VL,VR) %>%
            mutate(VL = -1 *VL)

            switch(input$compareCategory,
                "Nationality" = {dt <- dt %>% rename(Age = Age_Group,Native = VL, Foreigner = VR) %>%
                    melt(value.name='Population', variable.name='Group', id.vars='Age')},
                "Gender" = {dt <- dt %>% rename(Age = Age_Group,Female = VL, Male = VR) %>%
                    melt(value.name='Population', variable.name='Group', id.vars='Age')}
            )

        # determine left and right group to display
        leftgroup <- levels(dt$Group)[1]
        rightgroup <- levels(dt$Group)[2]
        # position for labels
        tposleft <- 0.8 * min(subset(dt, Group == levels(dt$Group)[1],Population))
        tposright <- 0.8 * max(subset(dt, Group == levels(dt$Group)[2],Population))
        # plot all together
        g3 <- ggplot(data=dt, aes(x = Age, y = Population, color=Group)) +
            geom_bar(data=subset(dt, Group == leftgroup),fill="red", colour="black", stat = "identity") +
            geom_bar(data=subset(dt, Group == rightgroup),fill="blue", colour="black", stat = "identity") +
            coord_flip() +
            annotate("text", x=nrow(subset(dt, Group == leftgroup)), y=tposleft, label=leftgroup) +
            annotate("text", x=nrow(subset(dt, Group == rightgroup)), y=tposright, label=rightgroup) +
            theme_bw()
        g3
    })

    # plot district map with charters included
	output$populationMap <- renderPlot({
        validate(
            need(input$districtCBG, 'Please select at least one district')
        )
	    dt<-aggregate_as_percentage(dtPop, input$age[1], input$age[2], input$districtCBG) %>%
		    select(Quarter,{if (input$aggCateg == 'both') {
                    PTF
                } else if(input$aggCateg == 'male') {
                    PMF
                } else {
                    PFF
                }}) 
        colnames(dt) <-  c("id","PTF")
		plotData <- left_join(qmap, dt)

        cnames <-aggregate(cbind(long, lat) ~ id, data = dmap, 
            FUN = function(x) mean(range(x)))
        cnames$angle <-0
		cnames$idb <- gsub("-","-\n",cnames$id)

        # plot all together
        p <- ggplot() +
            geom_polygon(data = plotData, aes(x = long, y = lat, group = id, 
                fill = PTF)) +
            geom_polygon(data = dmap, aes(x = long, y = lat, group = id),
                fill = NA, color = "black", size = 0.25) +
            scale_fill_continuous(low = "whitesmoke", high = "springgreen3") +
            guides(fill = guide_legend(reverse = TRUE)) +
            theme_nothing(legend = TRUE) +
            geom_text(data=cnames, aes(long, lat, label = idb,  
                angle=angle, map_id = NULL), size=2.5) +
            labs(title = "Percentage of Foreigners", fill = "")
       p   
	})
})


