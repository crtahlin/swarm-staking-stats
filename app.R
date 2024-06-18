#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(SwarmR)
library(dplyr)
library(DT)

# load data that was prepared and saved previously
# load("nodes_data_w_staking.RData")

# load data directly from Swarmscan, with some waiting period
swarmscan_data <- load_swarmscan_data()$nodes
swarmscan_staking <- load_swarmscan_staking()$events$data
swarmscan_staking_last <- # drop the historical values, just keep the last one
  swarmscan_staking %>% slice_max(lastUpdatedBlock, by = owner)
nodes_data <- merge(x = swarmscan_data,
                    y = swarmscan_staking_last,
                    by.x = "ethereumAddress", by.y = "owner", all.x = TRUE) # merge datasets
nodes_data$stakeAmountBZZ <- nodes_data$stakeAmount/10^16 # add column with BZZ
nodes_data$overlay_binary <- sapply(nodes_data$overlay.x, FUN = hexadecimal2binary) # add binary overlay address to the data set
nodes_data_w_staking_subset <- nodes_data[, c("overlay.x", "lastDiscoveryTime",
                                              "stakeAmount", "stakeAmountBZZ",
                                              "overlay_binary")] # just keep a useful data subset

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Staking per neighbourhood"),

    # Sidebar with a slider input for number of bins 
    verticalLayout(
        sidebarPanel(
            numericInput("storageRadius", "Storage radius", value = 11, min = 1, max = 16, step = 1)#,
            # dateInput("lastDiscoveredFilter", "Filter out nodes last discovered before this date:", value = "2023-01-01")
        ),

        # Show a plot of the generated distribution
        mainPanel(
          verbatimTextOutput("disclaimerText"),
          verbatimTextOutput("summaryText"),
          dataTableOutput("stakingPerNbhood")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  nodes_data <- reactive({
    # TODO make filtering based on lastseen
    nodes_data <- nodes_data_w_staking_subset
    nodes_data$overlay_short <- factor( first_n_places(nodes_data$overlay_binary, input$storageRadius),
                                        levels = generate_short_overlay(input$storageRadius) )
    # nodes_data <- nodes_data[nodes_data$lastDiscoveryTime >= input$lastDiscoveredFilter, ]
    
    return(nodes_data)
  })  
  
  output$stakingPerNbhood <- DT::renderDataTable({
    staking_per_nbhood <- 
      nodes_data() %>% 
      group_by(overlay_short, .drop = FALSE) %>% 
      summarise(minStakePerNode = min(stakeAmountBZZ, na.rm = TRUE),
                maxStakePerNode = max(stakeAmountBZZ, na.rm = TRUE),
                meanStakePerNode = mean(stakeAmountBZZ, na.rm = TRUE),
                totalStakeForNbhood = sum(stakeAmountBZZ, na.rm = TRUE),
                totalNumberOfNodes = n(),
                numberOfStakingNodes = sum(!is.na(stakeAmountBZZ)),
                numberOfNonStakingNodes = sum(is.na(stakeAmountBZZ)),
                relativeExpectedRewardFor10BZZStakePercent = ((100)/(2 ^ input$storageRadius))*(10 / (totalStakeForNbhood + 10) )  # in percent of total winnings, globally
      )
    
    return(staking_per_nbhood)
  }, colnames = c("Nbhood", "Min stake", "Max stake", "Mean stake",
                  "Total stake", "Nodes", "Staking nodes", "Non-staking nodes",
                  "Expected reward per 10 BZZ in percent"),
  rownames = FALSE)
  
  output$summaryText <- renderText({
    paste0("Total number of nodes in filtered dataset: ", dim(nodes_data())[1], " nodes \n",
           "Total staked amount for the nodes in filtered dataset: ", sum(nodes_data()$stakeAmountBZZ, na.rm = TRUE), " BZZ \n"
   )
  })  
  
  output$disclaimerText <- renderText({
    paste0(
"No guarantees whatsoever are given about the correctness of the displayed data and calculations. \n
The underlying data are not acquired in real time.")
  })

}

# Run the application 
shinyApp(ui = ui, server = server)
