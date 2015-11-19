library(shiny)

shinyUI(fluidPage(
  titlePanel("Population of Berlin - 2014"),
  fluidRow(
    column(3,
      sliderInput("age",
        "Age Groups",
        min = 0,
        max = 95,
        step = 5,
        value = c(0,95),
        format = "##"
      ),
      uiOutput("districtCheckboxes"),
	  actionButton(inputId = "clearselect", label = "Clear all", icon = icon("circle-o")),
      actionButton(inputId = "allselect", label = "Select all", icon = icon("check-circle-o"))
    ),
    column(9,
      mainPanel(
        tabsetPanel(
          tabPanel("Pyramid plot",
            column(5,
              wellPanel(
                radioButtons(
	        	  "compareCategory",
                  "Comparison",
                  c("Male/Female" = "Gender", "Native/Foreigner" = "Nationality")
                )
              )
            ),
            column(6,
              wellPanel(
                uiOutput("ui")
              )
            ),
            column(12,
              plotOutput("populationPyramid")
            )
          ),
          tabPanel("District map",
            column(8,
              wellPanel(
                radioButtons(
                  "aggCateg",
	 	          "Choose Gender",
                  c("Male" = "male","Female" = "female","Both" = "both")
                )
              )
            ),
            column(12,
              plotOutput("populationMap")
            )
          ),
          tabPanel("About",
            column(12,
              mainPanel(
                includeMarkdown("AboutBerlinPop.md")
              )
            )
          )
        )
      )
    )
  )
))
