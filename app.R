#########################SET WORKING DIRECTORY TO SOURCE FOLDER#######################################

#Make sure you have installed packages below
library("leaflet")
library("tidyverse")
library("shiny")
library("lubridate")
library("shinythemes")
library("kableExtra")
library("plotly")
library("shinycssloaders")
library("mapview")


getwd()
list.files()
load('global.RData')


# Define UI ----
ui <- fixedPage(theme =shinytheme("paper"),
                titlePanel(HTML('<center><span style="font-family: georgia, palatino;">The Road to Zero Fatality<br>A  Visualization Tool on UK Fatal Road Accidents</center></span>')),
  tabsetPanel(
    id = "tab_being_displayed", # will set input$tab_being_displayed
    tabPanel("Introduction", fluid = TRUE,
      
               mainPanel( width="100%",
                 
                 div(img(src='Intro.jpg', width = "100%"), style="float:left;margin-right:20px;width:30%"),
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
                             choices = c('All',(2005:2015)),
                             selected = '2005'),
                 selectInput("Month",
                             label="Month of interest",
                             choices = c('All',(1:12)),
                             selected = '1'),
         
                 selectInput("District",
                             label="Zoom in to District",
                             choices = c('All',levels(myDistrict$label)),
                             selected = 'All'),
                 
                 
                 textInput("AccidentIndex", label = h6("Enter Accident Index to Retrieve Data"), placeholder = 'Eg: 200532C014005')

               ),
        
        
                
                # Main panel for displaying outputs ----
                mainPanel(
                  HTML('<p>Please wait for Map to load. Refresh the page if map is not rendering properly.</p>'),
                  # Output: Leaflet map ----
                  leafletOutput(outputId = "LeafletMap", height = "625")%>%withSpinner(color="#0dc5c1",type=6),
                  h6(textOutput(outputId="Index")),                 
                  tableOutput(outputId="table"),
                  h6(textOutput(outputId="Vehicle")),
                  tableOutput(outputId="table2"),
                  h6(textOutput(outputId="Casualties")),
                  tableOutput(outputId="table3")
                  

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
                             selected = "Weather_Conditions"),
                 
                 uiOutput("ChartTypeInputs"),
                 uiOutput("ColorInputs")
                 

               ),

               # Main panel for displaying outputs ----
               mainPanel(
                 # Output: Chart ----
                 plotlyOutput(outputId="chartPlot", height= 625)%>%withSpinner(color="#0dc5c1",type=6)
                 
               )
             )#SidebarLayout
    ),#Tab Panel
    
    tabPanel("About", fluid = TRUE,

             mainPanel( width="100%",
                        uiOutput("About")%>%withSpinner(color="#0dc5c1",type=6)
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
                  popup = popupTable(mapOutlineUK), 
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
leaflet
#To filter time frame  
  observe({
    req(input$tab_being_displayed == "Interactive Map")
    
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())

    leafletProxy(("LeafletMap"))%>%
      addLayersControl(overlayGroups = c("Severity: Fatal","Outline"))%>%
      clearGroup(c("Severity: Fatal"))

    
    progress$set(message = "Please wait while computing",value=1)
    
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
    
    if (input$AccidentIndex %in% myFatal.Shiny$Accident_Index){
      output$Index = renderText({
        paste("Accident Index:",input$AccidentIndex)
      })
      
      output$table = function ()({
        myFatal.Shiny[myFatal.Shiny$Accident_Index==input$AccidentIndex,2:15]%>%
          t()%>%
          kable(col.names = NULL) %>%
          kable_styling()%>%
          scroll_box(width="100%")
      })
      
      output$Vehicle = renderText({
        paste("Details by vehicles involved")
      })
      
      
      output$table2 = function ()({        
        myVehicles.Shiny[myVehicles.Shiny$Accident_Index==input$AccidentIndex,2:13]%>%
          t()%>%
          kable(col.names = NULL) %>%
          kable_styling()%>%
          scroll_box(width="100%")
        
      })
      
      output$Casualties = renderText({
        paste("Details by casualties involved")
      })
      
      
      output$table3 = function ()({        
        myCasualties.Shiny[myCasualties.Shiny$Accident_Index==input$AccidentIndex,2:7]%>%
          kable() %>%
          kable_styling()%>%
          scroll_box(width="100%")
        
      })
      
    } 
    else if (!(input$AccidentIndex%in% myFatal.Shiny$Accident_Index)&nchar(input$AccidentIndex)>0) {
      output$Index = renderText({
        paste("Accident Index Input Not Found. Please Try Again...")
      })
      output$table = function ()({
      })
      output$Vehicle = renderText({
      })
      output$table2 = function ()({
      })
      output$Casualties = renderText({
      })
      output$table3 = function ()({
      })
    }
    else {
      output$Index = renderText({
      })
      output$table = function ()({
      })
      output$Vehicle = renderText({
      })
      output$table2 = function ()({
      })
      output$Casualties = renderText({
      })
      output$table3 = function ()({
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
  
  
  
##################ABOUT SECTION##################
##################ABOUT SECTION##################
  output$About = renderUI ({
    includeMarkdown('./README/README.md')
  })
  
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)

