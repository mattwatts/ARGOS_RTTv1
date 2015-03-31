# ARGOS Real Time Tracking rev 1

require(shiny)

shinyUI(pageWithSidebar(

    #headerPanel("ARGOS Real Time Tracking rev 1"),
    headerPanel(paste0("ARGOS Real Time Tracking rev 1 ",sUserID)),

    sidebarPanel(
        actionButton("aupdate","Fetch ARGOS"), 
        br(),
        br(),
        textOutput("textfeedback"),
        br(),
        sliderInput("gmzoom", "Google Maps Zoom:",value=11,min=4,max=13),
        br(),
        selectInput("gmtype", "Google Maps Type:",
                    choices = c("satellite","roadmap","hybrid","terrain")),
        br(),
        selectInput("argoslc", "ARGOS Location Class:",
                    choices = c("< 250m","250m to 500m","500m to 1500m","> 1500m","unbounded"))
    ),

    mainPanel(
        plotOutput('argosmap')#,
        #tableOutput('argostable')
             )
))
