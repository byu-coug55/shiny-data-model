# shiny-data-model
Import any dataset, select any two variables to compare, and develop a predictive model

## Web App Link
[Web App](https://byu-coug55.shinyapps.io/shiny_data_model/)

## Intro
I created my [Marathon Data App](https://byu-coug55.shinyapps.io/Marathon_Data_App/) to help me compare my marathon results with other athlete's results. My time wasn't very good, but interestingly my power output was similar to other runners. In analyzing the data, you could also see that power output was negatively correlated with marathon time - i.e. as you increase power output, you go faster!

This led me to the thought of creating a Shiny web app that would allow a user to import a dataset and analyze the correlation between any two variables.

This web app took a while to develop as there were several things that could go wrong, but I think I worked out all the kinks. If you find that any improvements are needed, please reach out to me on [LinkedIn](https://www.linkedin.com/in/lance-christian-byu/).

## Interface

<img width="1180" alt="image" src="https://user-images.githubusercontent.com/56312233/199391780-0ee1af3a-d354-4297-bddc-1de5fb94c52d.png">

Once the app loads, it initializes the plots and results with data from a sample dataset: `mtcars`. This default dataset can be changed and the user is able to choose between three datasets: `mtcars`, `diamonds`, and `pressure`. I choose these three datasets because they are decent matches for different models: 

`wt` adn `mpg` from `mtcars` have a relatively linear relationship

<img width="776" alt="image" src="https://user-images.githubusercontent.com/56312233/199392289-eb86aa19-7aa9-49da-81f4-7b0eedfe092d.png">

`carat` and `z` from `diamonds` match a logarithmic relationship

<img width="775" alt="image" src="https://user-images.githubusercontent.com/56312233/199392461-e217bddf-40ed-4fe7-953d-29f57e2a8c54.png">

and `temperature` and `pressure` can be approximated with a multi-order polynomial

<img width="784" alt="image" src="https://user-images.githubusercontent.com/56312233/199392658-f452b460-f92f-49d3-a2ab-4c56a4122980.png">

To enable the analysis of any dataset (smaller than 5 mb) the user can import their own dataset.

Initally there was only going to be a linear model, but having the different model options to choose from made more sense from an exploratory data analysis perspective. So I included linear, second order polynomial, third order polynomial, logarithmic, and exponential models.

The user is able to choose which variables to compare, and choose an x value to predict a y value. To guide the user in analysis, I display the range of x as well as variable options to choose from.

## Troubleshooting Issues

The first issue/design question I thought about was what the user saw when first opening the app. The purpose behind the app was to allow a user to upload a dataset to analyze. However, that would mean that would mean that the user would first encounter a blank screen. I wanted to encourage interactivity, so I needed to include a few default datasets. I also wanted these default datasets to fit different models so they could be used as examples.

So I explored differently preloaded datasets contained in base R by running `data()` which loads a table of contents with various datasets. I ended up chosing `mtcars`, `diamonds`, and `pressure`. This following code loads the user's chosen dataset:

```
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
```

Loading the user's imported dataset:

```
imported_data = reactive({
    file <- input$file
    if (is.null(file)){
      return(NULL)
    } else {
    read.csv(file$datapath)
    }
  })
```

If the user loads a dataset with too few values, I send an alert:

```
observeEvent(input$file,
          if (nrow(imported_data())<10){
            showNotification("Low row count, please use a dataset with more observations", type = "error", duration = 30)
          } else {
            showNotification("Dataset imported", type = "message", duration = 10)
          }
            )
```

Then to perform analysis on the user's selected dataset (whether imported or default), the user makes a radiobutton selection:

```
data = reactive({
    if (input$radio_buttons == "Default"){
      default_data_table()
    } else if(is.null(input$file)){
      showNotification("Please import a csv file", duration = 45, closeButton = FALSE, type = "error")
      default_data_table()
    } else {
      imported_data()
    }
  })
```

If the user selects "Imported" dataset before actually importing anything, the app will send a notification as shown above and continue to use the default dataset.

Once the dataset is chosen, I update the variable dropdown menus to select numeric variables from the dataset:

```
data_numeric = reactive(data() %>% dplyr::select(where(is.numeric)))
  
variable_options = reactive(as_tibble(names(data_numeric())))
    
observe({
    updateSelectInput(session, "variable_choice1", choices = variable_options())
  })
  
observe({
    updateSelectInput(session, "variable_choice2", 
                      choices = variable_options(), selected = tail(variable_options(),n=1))
  })
```

I then combine the user's selected variables into a dataframe:

```
variable1 = reactive(data() %>% select(input$variable_choice1) )
  
  variable2 = reactive(data() %>% select(input$variable_choice2) )
  
  var_data_int = reactive(bind_cols(variable1(),variable2()))
  
  var_data = reactive({
    if (input$model_choice == "Logarithmic"){
      var_data_int() %>% filter(get(input$variable_choice1)>0)
    } else {
      var_data_int() %>%
        filter(!is.na(get(input$variable_choice1))) %>%
        filter(!is.na(get(input$variable_choice2))) %>%
        filter(!is.null(get(input$variable_choice1))) %>%
        filter(!is.null(get(input$variable_choice2))) 
    }
  })
```

Many analyses don't like N/A or `null` values, so those are filtered out above. If the data model is `logarithmic` then the chosen x variable cannot be negative.

For the model selection, I allow the user to choose from `linear`, `second order polynomial`, `third order polynomial`, `logarithmic`, and `exponential`.

```
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
```

As part of this app, I wanted the user to be able to put in a value and make a prediction based on the model they chose. However, if the user deletes the value from the numericInput, then the app would throw several errors for the dependent tables and plots. To get around this, I used and if statement conditional on a valid numericInput. This can be done by using `isTruthy()`:

```
output$y_pred = renderTable({
    if(!isTruthy(input$x_pred)){
      return(range_y())
    } else {
      return(y_pred_out())
    }
  })

output$plotly = renderPlotly({
    if(!isTruthy(input$x_pred)){
      return(plotly1())
    } else {
      return(plotly2())
    }
  })
```

You'll notice that when the numericInput field is blank, the y prediction table shows only the range of y instead of a prediction. Also the main scatter plot changes when the numericInput is not null.

The last issue I had was creating the combination plots. [Plotly's documentation](https://plotly.com/r/) is pretty extensive, but I found that it was hard to navigate sometimes. However, I was able to find a post that contained info on creating combination plots by using `subplot()`:

```
output$combined1 = renderPlotly(
    subplot(
      plot_ly(data = var_data(), x = ~get(input$variable_choice1), type = "histogram", name = "histogram") %>%
        layout(title = 'Variable 1', xaxis = list(title = input$variable_choice1), yaxis = list(title = "Frequency")),
      plot_ly(data = var_data(), x = ~get(input$variable_choice1), type = "box", name = "boxlpot", boxmean = T, boxpoints = "all"),
      plot_ly(data = var_data(), x = ~get(input$variable_choice1), type = "violin", name = "violin", side = "negative") %>%
        layout(title = 'Variable 1', xaxis = list(title = input$variable_choice1)),
      nrows = 3, heights = c(0.6, 0.2,0.2), widths = c(0.8),
      shareX = T
    )
  )
```

Using the `subplot()` function allowed me to combine a histogram, boxplot, and a violin plot! I think the result is pretty visually appealing! (and at the same time, very information dense!)

<img width="817" alt="image" src="https://user-images.githubusercontent.com/56312233/199598094-680df7ff-7165-4e4a-8011-28b51e70ab3b.png">


## Results - Correlation Tab

Once a user inputs an x value to predict a y value, the main plot updates to show the predicted value:

<img width="781" alt="image" src="https://user-images.githubusercontent.com/56312233/199394705-3cd61581-c493-4ad0-8f6c-2fdf64e4cd8a.png">

The sidebar also updates to show the prediction data including the predicted value as well as the upper and lower 95% confidence interval: 

<img width="347" alt="image" src="https://user-images.githubusercontent.com/56312233/199394834-0c3a2422-272b-4531-996a-be1de29e732d.png">

Each plot is made with plotly so it is interactive. You can select specific points to zoom in on, you can hover over points to see the underlying data values, and you can download the plot as a png.

Model coefficients, model r squared value, and variable correlation coefficient and p-value are displayed under the primary scatter plot: 

<img width="596" alt="image" src="https://user-images.githubusercontent.com/56312233/199490277-faff41a9-8aa3-4c49-bcab-c0ba41ff9c0c.png">

Then, to aid the user in verifying they are visualizing the correct data, I display the top 15 rows of the chosen variables.

## Results - Variable Stats Tab

<img width="902" alt="image" src="https://user-images.githubusercontent.com/56312233/199490787-afe8c9a4-d612-4109-bffc-0bdf586bbd11.png">

In analyzing the correlation between two variables, it is helpful to know as much as you can about those variables. This tab is meant to help as a deep dive into the chosen variables. The user is shown some summary statistics (observation count, mean, standard deviation, min, 25 percentile, 75 percentile, and max). The next table shows a few normaility stats including skewness (does the data lean one way) and kurtosis (how peaked or plateau-like is the data). Then I display a combination chart showing a histogram, boxplot, and a violin plot. 

With this chart, if you wanted to focus in on the data closest to the mean, you can double click on the boxplot trace to isolate it, then select the data around the mean like so:

<img width="385" alt="image" src="https://user-images.githubusercontent.com/56312233/199493045-52b811ff-8a36-4cdb-a8b8-58e5bb12a170.png">

The solid line is the median and the dashed line is the mean.

## Results - Model Info

<img width="606" alt="image" src="https://user-images.githubusercontent.com/56312233/199493338-0b503b6e-5c97-4c41-ab78-3a865db6556b.png">

In choosing an optimal model, there are multiple considerations to take into account. This tab helps in that task.

### Considerations

 - How is the model comparing x and y values?
    - This is shown in the Call section
    - The values in the estimate column are the model coefficients
 -  Is there a pattern in the residual plot? (Shown below the model summary)
    - Patterns in the residual plot mean your model is missing something and doesn't fully explain the correlation
 -  Minimize standard error in the coefficients
 -  Maximize R-squared and F-statistic
 -  Minimize p-value (significance level set at 0.05, values below that show significance)


## Conclusion

Overall this has been a fun project and definitely my largest so far. Hopefully users get good use out of it. If you have any suggestions or project ideas, send them my way!





