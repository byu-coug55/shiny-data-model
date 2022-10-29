library(shiny)
library(plotly)
library(tidyverse)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Linear Modeling"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
          selectInput("default_data", "Select a default Dataset",
                      choices = c("MT_Cars","Diamonds", 
                                  "Pressure")),
          radioButtons("radio_buttons", "Default Dataset or Imported",
                       choices = c("Default","Imported")),
          fileInput("file", "Import Dataset (csv only)", multiple = F,
                    accept = c(
                      "text/csv",
                      "text/comma-separated-values,text/plain",
                      ".csv")),
          selectInput("variable_choice1","Select Variable 1 (x)", choices = c("var1","var2","var3")),
          selectInput("variable_choice2","Select Variable 2 (y)", choices = c("var1","var2","var3")),
          #submitButton(),
          h5("Variable Options"),
          tableOutput("table2")
          
            
        ),

        # Show a plot of the generated distribution
        mainPanel(
          fluidRow(
            textOutput("slopeOut"),
            textOutput("intOut"),
            textOutput("cor")
          ),
          plotlyOutput("plotly"),
          fluidRow(
            tableOutput("table")
          
          )
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  default_data_table = reactive({
    if(input$default_data == "MT_Cars"){
      as_tibble(mtcars)
    } else if (input$default_data == "Diamonds"){
      as_tibble(diamonds %>% filter(cut %in% c("Very Good", "Premium")) %>%
                  head(n=1000))
    } else {
      as_tibble(pressure)
    }
  })
  
  imported_data = reactive({
    file <- input$file
    if (is.null(file))
      return(NULL)
    read.csv(file$datapath)
  })
  
  data = reactive({
    if (input$radio_buttons == "Default"){
      default_data_table()
    } else {
      imported_data()
    }
  })
  
  data_numeric = reactive(data() %>% dplyr::select(where(is.numeric)))
  
  variable_options = reactive(as_tibble(names(data_numeric())))
  
  observe({
    updateSelectInput(session, "variable_choice1", choices = variable_options())
  })
  
  observe({
    updateSelectInput(session, "variable_choice2", 
                      choices = variable_options(), selected = tail(variable_options(),n=1))
  })
  
  
  variable1 = reactive(data() %>% select(input$variable_choice1))
  variable2 = reactive(data() %>% select(input$variable_choice2))
  
  var_data = reactive(bind_cols(variable1(),variable2()))
  
  model <- reactive({
    lm(get(input$variable_choice2) ~ get(input$variable_choice1), data = data())
  })
  
  slope = reactive(model()[[1]][2])
  int = reactive(model()[[1]][1])
  
  output$slopeOut <- renderText({
    paste0("Linear Model Slope = ",round(slope(),2))
  })
  
  output$intOut <- renderText({
    paste0("Linear Model Intercept = ",round(int(),2))
  })
  
  output$cor <- renderText({
    paste0("Correlation = ", round(cor(variable1(),variable2()),2))
  })
  
  data_predict = reactive({
   data() %>% mutate(y_predict = slope()*get(input$variable_choice1)+int()) 
  })
  
  x_range = reactive(seq(min(variable1()),max(variable1()),length.out=100) %>% as_tibble() )
  
  data_predict2 = reactive({
    x_range() %>% mutate(y_predict = slope()*value+int())
  })
  
  output$plotly = renderPlotly(
    plot_ly(data = data(), x = ~get(input$variable_choice1), y = ~get(input$variable_choice2), 
            type = 'scatter', mode = 'markers') %>%
      add_trace(data = data_predict2(), x = ~value, y = ~y_predict, mode = 'lines', type = 'scatter')
  )
  
  
  output$table2 = renderTable(as_tibble(names(data_numeric())) %>% 
                                mutate(index = row_number()))
  
  output$table = renderTable(var_data())
  output$table3 = renderTable(data_predict())
  output$xmin = renderTable(data_predict2())
  output$xmax = renderText(max(variable1()))
  
}

# Run the application 
shinyApp(ui = ui, server = server)
