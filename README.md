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

Obviously I wanted this web app to be useful for users so I added an import dataset option.

Initally there was only going to be a linear model, but having the different model options to choose from made more sense from an exploratory data analysis perspective. So I included linear, second order polynomial, third order polynomial, logarithmic, and exponential models.

The user is able to choose which variables to compare, and choose an x value to predict a y value. To guide the user in analysis, I display the range of x as well as variable options to choose from.

## Results

Once a user inputs an x value to predict a y value, the main plot updates to show the predicted value:

<img width="781" alt="image" src="https://user-images.githubusercontent.com/56312233/199394705-3cd61581-c493-4ad0-8f6c-2fdf64e4cd8a.png">

The sidebar also updates to show the prediction data including the predicted value as well as the upper and lower 95% confidence interval: 

<img width="347" alt="image" src="https://user-images.githubusercontent.com/56312233/199394834-0c3a2422-272b-4531-996a-be1de29e732d.png">

Each plot is made with plotly so it is interactive. You can select specific points to zoom in on, you can hover over points to see the underlying data values, and you can download the plot as a png.







