#########################SET WORKING DIRECTORY TO SOURCE FOLDER#######################################

#Make sure you have installed packages below
library("leaflet")
library("tidyverse")
library("shiny")
library("lubridate")
library("shinythemes")
library("kableExtra")
library("plotly")

getwd()
list.files()
load('global.RData')


# Define UI ----
ui <- fluidPage(theme =shinytheme("paper"),
                titlePanel(HTML('<center><span style="font-family: georgia, palatino;">The Road to Zero Fatality<br>A  Visualization Tool on UK Fatal Road Accidents</center></span>')),
  tabsetPanel(
    
    tabPanel("About", fluid = TRUE,
      
               mainPanel( width="100%",
                 
                 div(img(src='Intro.jpg'), style="float:left;margin-right:20px;"),
                 includeHTML("introduction.html")
               )
    ),
    
    
    
    tabPanel("Interactive Map",fluid=TRUE,
             
             # Sidebar layout with input and output definitions ----
             sidebarLayout(
               
               # Sidebar panel for inputs ----
               sidebarPanel(
                 h6("Select range and attributes to filter the data"),
                 
                 selectInput("Year",
                             label="Year of interest",
                             choices = c('','All',(2005:2015)),
                             selected = ''),
                 selectInput("Month",
                             label="Month of interest",
                             choices = c('','All',(1:12)),
                             selected = ''),
         
                 selectInput("District",
                             label="Zoom in to District",
                             choices = c('','All',levels(myDistrict$label)),
                             selected = ''),
                 
                 
                 textInput("AccidentIndex", label = h6("Enter Accident Index to Retrieve Data"), value = "enter text...")

               ),
        
        
                
                # Main panel for displaying outputs ----
                mainPanel(
                  # Output: Leaflet map ----
                  leafletOutput(outputId = "LeafletMap", height = 625),
                  
                  textOutput(outputId="Index"),
                  tableOutput(outputId="table")

                )
              )#SidebarLayout           
        
    ),#TabPanel
    
    tabPanel("Interactive Chart",fluid=TRUE,
             sidebarLayout(
               
               # Sidebar panel for inputs ----
               sidebarPanel(
                 h6("Select Chart Types and Attributes"),
                 
                 selectInput("ChartType",
                             label="ChartType",
                             choices = c("Pie Chart","Histogram","2D Histogram"),
                             selected = "Pie Chart"),
                 
                 selectInput("Attributes",
                             label="Attributes",
                             choices = c(AccidentAttributes,VehicleAttributes),
                             selected = "Time_of_Day"),
                 
                 uiOutput("ChartTypeInputs"),
                 uiOutput("ColorInputs")
                 

               ),

               # Main panel for displaying outputs ----
               mainPanel(
                 # Output: Chart ----
                 plotlyOutput(outputId="chartPlot", height= 625)
                 
               )
             )#SidebarLayout
    ),#Tab Panel
    
    tabPanel("About", fluid = TRUE,

             mainPanel( width="100%",
                        includeHTML('./README/README.html')
             )
    )#TabPanel
  )#TabSetPanel
)#ui
# Define server logic required to draw a histogram ----
server <- function(input, output, session) {

##################LEAFLET SECTION##################
##################LEAFLET SECTION##################
#Initialiaze Leaflet
  output$LeafletMap = renderLeaflet({
    leaflet(options = leafletOptions(preferCanvas = TRUE))%>%
      addTiles(options = providerTileOptions(updateWhenZooming = FALSE,
                                             updateWhenIdle = TRUE))%>%
      setView(lng=-5,lat=54.5, zoom =6)%>%
      addPolygons(data = mapOutlineUK, 
                  #popup = popupTable(mapOutlineUK), 
                  color = "blue", 
                  weight = 1, 
                  smoothFactor = 0.5,
                  opacity = 0.15, 
                  fillOpacity = 0.1,
                  group = "Outline")%>%
      addMiniMap(toggleDisplay = TRUE,position = "bottomleft")
  })
##################
#To filter data according to time frame input
  myFatal.Interval = reactive({
    if (input$Year != 'All' & input$Month != 'All') {
      myFatal.Shiny %>%filter(year(Date) == input$Year & month(Date)==input$Month)
    } 
    else if (input$Year == 'All' & input$Month != 'All'){
      myFatal.Shiny %>%filter(month(Date)==input$Month)
    }
    else if (input$Year != 'All' & input$Month == 'All'){
      myFatal.Shiny %>%filter(year(Date) == input$Year)
    }
    else if (input$Year == 'All' & input$Month == 'All'){
      myFatal.Shiny 
    }
  })
  
####################
#To select district lat and long for zoom in
  myFatal.District = reactive({
    if (input$District != 'All') {
      myDistrict[myDistrict$label==input$District,]
    }else {
      break
    }
  })
###################

#To set zoom view  
  observe({
  
    if (input$AccidentIndex %in% myFatal.Shiny$Accident_Index){
      leafletProxy(("LeafletMap"))%>% 
        setView(lng=myFatal.Shiny[myFatal.Shiny$Accident_Index==input$AccidentIndex,"Longitude"],
                lat=myFatal.Shiny[myFatal.Shiny$Accident_Index==input$AccidentIndex,"Latitude"],
                zoom =15)
    }
    else if (input$District !='All'){
      leafletProxy(("LeafletMap"))%>% setView(lng=myFatal.District()$Long,lat=myFatal.District()$Lat, zoom =12)
    }
    else{
      leafletProxy(("LeafletMap"))%>% setView(lng=-5,lat=54.5, zoom =6)
    }
  })

#To filter time frame  
  observe({
    
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    
    leafletProxy(("LeafletMap"))%>%
      addLayersControl(overlayGroups = c("Severity: Fatal","Outline"))%>%
      clearGroup(c("Severity: Fatal"))

    
    progress$set(message = "Please wait while computing",value=0)
    leafletProxy("LeafletMap", data= myFatal.Interval())%>%
      addCircleMarkers(lat=~Latitude,
                       lng=~Longitude,
                       popup= ~popup1,
                       group = 'Severity: Fatal',
                       options = popupOptions(closeButton = FALSE),
                       radius = 3,
                       color = "red",
                       fill = TRUE,
                       opacity = 1,
                       clusterOptions = markerClusterOptions(maxClusterRadius = 30,disableClusteringAtZoom = 15))
    
    



    progress$inc(1/1, detail = paste("Almost there"))
    
  })


  observe({
    
    if (input$AccidentIndex == "enter text..."){
      
      return(NULL)
      
    }
    else if (input$AccidentIndex %in% myFatal.Shiny$Accident_Index){
      output$Index = renderText({
        paste("Accident Index:",input$AccidentIndex)
      })
      
      output$table = function ()({
        myFatal.Shiny[myFatal.Shiny$Accident_Index==input$AccidentIndex,2:15]%>%
          kable() %>%
          kable_styling()%>%
          scroll_box(width="100%")
      })
      
    } 
    else {
      output$Index = renderText({
        paste("Accident Index Input Not Found. Please Try Again")
      })
    }
    
  })

##################INTERACTIVE CHART SECTION##################
##################INTERACTIVE CHART SECTION##################   
  
  output$ChartTypeInputs = renderUI ({
    
    if (input$ChartType == '2D Histogram'){

      selectInput("YAttributes",
                  label="Additional Attributes",
                  choices = c(AccidentAttributes,VehicleAttributes),
                  selected = "Day_of_Week")

    }

  })
  
  output$ColorInputs = renderUI ({
    
    if (input$ChartType == '2D Histogram'){
      
      selectInput("ColorScale",
                  label="Color Scale",
                  choices = PlotlycolorScale,
                  selected = "Reds") 
      
    }
    
  })
  

  
  myPieData = reactive({
    if (input$Attributes %in% AccidentAttributes){
      myFatal.Shiny%>%group_by(get(input$Attributes))%>%tally()%>%as.data.frame()
    }
    else if (input$Attributes %in% VehicleAttributes){
      myVehicles.Shiny%>%group_by(get(input$Attributes))%>%tally()%>%as.data.frame()
    }
  })
  
  myHistData = reactive({
    if (input$Attributes %in% AccidentAttributes){
      myFatal.Shiny
    }
    else if (input$Attributes %in% VehicleAttributes){
      myVehicles.Shiny
    }
  })
  
  my2DHistDataX = reactive({
    if (input$Attributes %in% AccidentAttributes){
      myFatal.Shiny
    }
    else if (input$YAttributes %in% VehicleAttributes){
      myVehicles.Shiny
    }
  })
  

    
  output$chartPlot = renderPlotly({
    
    if (input$ChartType == 'Pie Chart'){
      plot_ly(data=myPieData(), labels=sort(myPieData()[,1]), values=myPieData()[,2] ,type='pie')%>%
        layout(title = paste('UK Fatal Road Accidents Frequency by ', input$Attributes))
      
    }
    else if(input$ChartType == 'Histogram'){
      plot_ly(data=myHistData(), x= ~get(input$Attributes),type='histogram')%>%
        layout(title = paste('UK Fatal Road Accidents Frequency by ', input$Attributes),
               xaxis=list(title=input$Attributes),
               yaxis=list(title="Frequency"))
    }
    else if(input$ChartType == '2D Histogram'){
      cnt <- with(myVehicles.Shiny, table(input$Attributes, input$YAttributes))
      plot_ly(data=myVehicles.Shiny, x= ~get(input$Attributes),y=~get(input$YAttributes))%>%
        add_histogram2d(colorscale=input$ColorScale)%>%
        layout(title = paste('UK Fatal Road Accidents 2D Histogram', input$YAttributes, 'vs',input$Attributes),
               xaxis=list(title=input$Attributes),
               yaxis=list(title=input$YAttributes))
    }
  })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)

