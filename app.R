library(shiny)
library(plotly)
library(tidyverse)
library(vtable)
library(lolcat)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Data Modeling"),

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
          selectInput("model_choice", "Select Model", choices = c("Linear","Second Order Polynomial","Third Order Polynomial",
                                                                  "Exponential","Logarithmic")),
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
              h4("Plot"),
              plotlyOutput("plotly"),
              br(),
              br(),
              h4("Model Fit and Correlation"),
              fluidRow(
                column(5,
                       h5("Model Fit"),
                       h6("Model Coefficients"),
                       verbatimTextOutput("coeffOut"),
                       textOutput("modelSumOut")),
                column(5,
                       h5("Variable Correlation"),
                       br(),
                       textOutput("cor"),
                       textOutput("pval"))
              ),
              br(),
              br(),
              h4("Top 15 Rows of Chosen Variables"),
              fluidRow(
                tableOutput("table")
          
              )),
            tabPanel("Variable Stats",
              h4("Summary Stats"),
              tableOutput("sum_stat"),
              h4("Normality Stats"),
              tableOutput("sum_stat2"),
              column(6,plotlyOutput("combined1")),
              column(6,plotlyOutput("combined2"))
                     ),
            tabPanel("Model Info",
                     h4("Model Summary"),
                     verbatimTextOutput("modelsummary"),
                     br(),
                     br(),
                     h4("Residual Plot"),
                     br(),
                     plotlyOutput("residuals"))
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
  
  var_data_int = reactive(bind_cols(variable1(),variable2()))
  
  var_data = reactive({
    if (input$model_choice == "Logarithmic"){
      var_data_int() %>% filter(get(input$variable_choice1)>0)
    } else {
      var_data_int()
    }
  })
  
  model <- reactive({
    if (input$model_choice == "Linear"){
      lm(get(input$variable_choice2) ~ get(input$variable_choice1), data = var_data())
    } else if (input$model_choice == "Second Order Polynomial"){
      lm(get(input$variable_choice2) ~ poly(get(input$variable_choice1),2), data = var_data())
    } else if (input$model_choice == "Third Order Polynomial"){
      lm(get(input$variable_choice2) ~ poly(get(input$variable_choice1),3), data = var_data())
    } else if (input$model_choice == "Exponential"){
      lm(log(get(input$variable_choice2)) ~ get(input$variable_choice1), data = var_data())
    } else if (input$model_choice == "Logarithmic"){
      lm(get(input$variable_choice2) ~ log(get(input$variable_choice1)), data = var_data())
    } else {
      NULL
    }
  })
  
  coefficients1 = reactive(round(model()[[1]],2) %>% as_tibble() %>% t())
  model_sum = reactive(summary(model()))
  
  output$coeffOut <- renderPrint({
    coefficients1()
  })
  
  output$modelSumOut <- renderText({
    paste0("Model R_squared = ",round(model_sum()[[8]],3))
  })
  
  output$cor <- renderText({
    paste0("Correlation = ", round(cor(variable1(),variable2(), use = "complete.obs"),3))
  })
  
  cor_test = reactive(cor.test(as_vector(variable1()),as_vector(variable2()),method = "pearson"))
  
  output$pval = renderText({
    paste0("Correlation p-value = ",round(cor_test()[[3]],5))
  })
  
  output$modelsummary = renderPrint({
    model_sum()
  })
  
  data_predict = reactive({
   data() %>% mutate(y_predict = slope()*get(input$variable_choice1)+int()) 
  })
  
  x_range = reactive(seq(min(variable1(), na.rm=TRUE),max(variable1(), na.rm=TRUE),length.out=100) %>% as_tibble() )
  
  name = reactive(input$variable_choice1)
  
  x_range2 = reactive( x_range() %>% mutate(!!name() := value))
  
  data_predict2 = reactive({
    x_range2() %>% mutate(y_predict = predict(model(), newdata = x_range2()[2]))
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
  output$combined1 = renderPlotly(
    subplot(
      plot_ly(data = data(), x = ~get(input$variable_choice1), type = "histogram", name = "histogram") %>%
        layout(title = 'Variable 1', xaxis = list(title = input$variable_choice1), yaxis = list(title = "Frequency")),
      plot_ly(data = data(), x = ~get(input$variable_choice1), type = "box", name = "boxlpot", boxmean = T, boxpoints = "all"),
      plot_ly(data = data(), x = ~get(input$variable_choice1), type = "violin", name = "violin", side = "negative") %>%
        layout(title = 'Variable 1', xaxis = list(title = input$variable_choice1)),
      nrows = 3, heights = c(0.6, 0.2,0.2), widths = c(0.8),
      shareX = T
    )
  )
  
  output$combined2 = renderPlotly(
    subplot(
      plot_ly(data = data(), x = ~get(input$variable_choice2), type = "histogram", name = "histogram") %>%
        layout(title = 'Variable 2', xaxis = list(title = input$variable_choice2), yaxis = list(title = "Frequency")),
      plot_ly(data = data(), x = ~get(input$variable_choice2), type = "box", name = "boxlpot", boxmean = T, boxpoints = "all"),
      plot_ly(data = data(), x = ~get(input$variable_choice2), type = "violin", name = "violin", side = "negative")%>%
        layout(title = 'Variable 2', xaxis = list(title = input$variable_choice2)),
      nrows = 3, heights = c(0.6, 0.2,0.2), widths = c(0.8),
      shareX = T
    )
  )
  
  residuals_data = reactive(bind_cols(model()[5],model()[2]))
  
  output$residuals = renderPlotly(
    plot_ly(data = residuals_data(), x = ~fitted.values, y = ~residuals, type = "scatter", mode = "markers")
  )
  
   
}

# Run the application 
shinyApp(ui = ui, server = server)
