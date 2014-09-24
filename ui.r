source("R/dkwidgets.R")
library(dygraphs)

shinyUI(fluidPage(
  titlePanel("EMG Waiting List Simulation"),
  dkWidgets(),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Select EMG Clinic parameters."),
      
      dkAccordion(
        dkAccordionPanel("referralPanel", "Referral Setup",
          selectInput("referralYear", label="Based on year:", choices=c("2010","2011","2012","2013"), selected="2013"),
          fluidRow(
            column(width=6, numericInput("refTotal", label="Total Referrals", value=0)),
            column(width=4, numericInput("waitingList", label="WL @ Jan 1st", value=0))
          ),
          dkSliderInput("apptLengthSlider", values=c(20,60,90), min=0, max = 100),
          fluidRow(
            column(width=4, numericInput("appt30", label="30 min", value=0)),
            column(width=4, numericInput("appt45", label="45 min", value=0)),
            column(width=4, numericInput("appt60", label="60 min", value=0))
          ),
          expanded=T
        )
      ),
      
      wellPanel(     
        helpText("Consultant Setup"),
        sliderInput("consultantSessionsPerWeek", 
                    label = "Sessions Per Week:",
                    min = 0, max = 20, value = 4),
        textInput("consultantTemplate", 
                  label = "Template: ",
                  value = "60,45,45,45")
      ),
      wellPanel(
        helpText("Registrar Setup"),
        sliderInput("regSessionsPerWeek", 
                    label = "Sessions Per Week:",
                    min = 0, max = 20, value = 2),
        textInput("regTemplate", 
                  label = "Template: ",
                  value = "30,30,30")
      ),
      wellPanel(
        helpText("Simulation Setup"),
        sliderInput("simDuration",
                    label="Duration (years):",
                    min=1, max=5, value=1)
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Dashboard", plotOutput("plots", height="800px")),
        tabPanel("Interactive", dygraphOutput("tsplot"))
      )
    )
  )
))