library(shiny)
library(plotly)
library(tidyverse)
library(vtable)
library(lolcat)

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
          fileInput("file", "Import Dataset (csv only)", multiple = F,
                    accept = ".csv"),
          radioButtons("radio_buttons", "Default Dataset or Imported",
                       choices = c("Default","Imported")),
          selectInput("variable_choice1","Select Variable 1 (x)", choices = c("var1","var2","var3")),
          selectInput("variable_choice2","Select Variable 2 (y)", choices = c("var1","var2","var3")),
          #selectInput("color_choice","Select A Variable to Add Color", choices = c("N/A","var1","var2"), selected = "N/A"),
          #submitButton(),
          h4("Numeric Variable Options"),
          tableOutput("table2")
          
            
        ),

        # Show a plot of the generated distribution
        mainPanel(
          tabsetPanel(
            tabPanel("Correlation",
              h4("Correlation Coefficients"),
              fluidRow(
                column(5,
                  textOutput("slopeOut"),
                  textOutput("intOut")),
                column(5,
                  textOutput("cor"),
                  textOutput("pval"))
              ),
              br(),
              h4("Plot"),
              plotlyOutput("plotly"),
              br(),
              h4("Top 15 Rows of Chosen Variables"),
              fluidRow(
                tableOutput("table")
          
              )),
            tabPanel("Statistics",
              h4("Summary Stats"),
              tableOutput("sum_stat"),
              h4("Normality Stats"),
              tableOutput("sum_stat2"),
              column(6,plotlyOutput("histogram1")),
              column(6,plotlyOutput("histogram2"))
                     )
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
  
  total_options = reactive(as_tibble(names(data())) %>% add_row(value="N/A"))
  
  observe({
    updateSelectInput(session, "variable_choice1", choices = variable_options())
  })
  
  observe({
    updateSelectInput(session, "variable_choice2", 
                      choices = variable_options(), selected = tail(variable_options(),n=1))
  })
  
  observe({
    updateSelectInput(session, "color_choice", 
                      choices = total_options(), selected = "N/A")
  })
  
  #color_var = reactive(data() %>% select(input$color_choice))
  variable1 = reactive(data() %>% select(input$variable_choice1) )
  variable2 = reactive(data() %>% select(input$variable_choice2) )
  
  var_data = reactive(bind_cols(variable1(),variable2()))
  
  model <- reactive({
    lm(get(input$variable_choice2) ~ get(input$variable_choice1), data = data())
  })
  
  slope = reactive(model()[[1]][2])
  int = reactive(model()[[1]][1])
  
  output$slopeOut <- renderText({
    paste0("Linear Model Slope = ",round(slope(),3))
  })
  
  output$intOut <- renderText({
    paste0("Linear Model Intercept = ",round(int(),3))
  })
  
  output$cor <- renderText({
    paste0("Correlation = ", round(cor(variable1(),variable2(), use = "complete.obs"),3))
  })
  
  cor_test = reactive(cor.test(as_vector(variable1()),as_vector(variable2()),method = "pearson"))
  
  output$pval = renderText({
    paste0("Correlation p-value = ",round(cor_test()[[3]],4))
  })
  
  data_predict = reactive({
   data() %>% mutate(y_predict = slope()*get(input$variable_choice1)+int()) 
  })
  
  x_range = reactive(seq(min(variable1(), na.rm=TRUE),max(variable1(), na.rm=TRUE),length.out=100) %>% as_tibble() )
  
  data_predict2 = reactive({
    x_range() %>% mutate(y_predict = slope()*value+int())
  })
  
  output$plotly = renderPlotly(
    plot_ly(data = data(), x = ~get(input$variable_choice1), y = ~get(input$variable_choice2), 
            type = 'scatter', mode = 'markers') %>%
      add_trace(data = data_predict2(), x = ~value, y = ~y_predict, mode = 'lines', type = 'scatter') %>%
      layout(title = 'Variable Correlation', xaxis = list(title = input$variable_choice1), 
             yaxis = list(title = input$variable_choice2))
  )
  
  
  output$table2 = renderTable(as_tibble(names(data_numeric())) )
  
  output$table = renderTable(head(var_data(),n=15))
  output$sum_stat = renderTable(st(var_data(),out = "return"))
  output$sum_stat2 = renderTable(summary.continuous(var_data()))
  output$histogram1 = renderPlotly( plot_ly(data = data(), x = ~get(input$variable_choice1), type = "histogram") %>%
                                      layout(title = 'Variable 1', xaxis = list(title = input$variable_choice1), yaxis = list(title = "Frequency") ))
  output$histogram2 = renderPlotly( plot_ly(data = data(), x = ~get(input$variable_choice2), type = "histogram") %>%
                                      layout(title = 'Variable 2', xaxis = list(title = input$variable_choice2), yaxis = list(title = "Frequency")))
  
   
}

# Run the application 
shinyApp(ui = ui, server = server)
