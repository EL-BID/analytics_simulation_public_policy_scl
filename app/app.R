#library(shinydashboard)
library(semantic.dashboard)
library(shiny)
library(tidyverse)
library(ggtext)
library(knitr)

### Source

ui <- dashboardPage(
  dashboardHeader(title = "SCL Policy Simulator"),
  
  dashboardSidebar(sidebarMenu(
    menuItem(tabName = "description", text = "Description", icon = icon("info")),
    menuItem(tabName = "simulator", text = "Simulator", icon = icon("lab")),
    menuItem(tabName = "regionresults", text = "Distribution results", icon = icon("globe"))
  )),
  
  dashboardBody(tabItems(
        tabItem(tabName='description',
                div(style="display:inline-block",downloadButton("pdf", label="Download Report", class = "butt2"),
                    style="float:left"),
                tags$head(tags$style(".butt2{background-color:#a1d99b;} .butt2{color: white;} .butt2{font-style: italic;}")),

                box(title = "Project Readme", status = "primary", solidHeader = F,
                    collapsible = T, width = 12, 
                    column(12, htmlOutput("readme"))) 
        ),
    
        tabItem(tabName = "simulator",
              fluidRow(box(
                          title = "Controls",
                          h1("Simulator Controls"),
                          p('Choose which components will be affected by the exogenous shock '),
                          selectInput("shock_component", "shock_component:",
                                      c('Grains', 'Grains, Breads and Cereals', 
                                        'All - No meat', 'All')),
                          p('Choose the pct change of exogenous shock'),
                          sliderInput("shock", "Shock level:", value=0,min = 0, max = .5, step = .1),
                          br(' '),
                          br(' '),
                          downloadButton("downloadData", "Download Simulation Results")),
                       box(title = "Change in Poverty",
                           plotOutput("diff", height = 400)) 
                      ),
              fluidRow(box(title = "Official Poverty",
                           plotOutput("realpoor", height = 400)),
                        box(title = "Change in Poverty",
                            plotOutput("deltapoor", height = 400)))),
        tabItem(tabName = "regionresults",
                fluidRow(
                  box(title = "Change in Poverty - grains",
                      plotOutput("boxplot_granos", height = 400)),
                  box(title = "Change in Poverty - grains, breads and cereals.",
                             plotOutput("boxplot", height = 400))),
                fluidRow(
                  box(title = "Change in Poverty - All products *except* meat",
                      plotOutput("boxplot_all_no_meat", height = 400)),
                  box(title = "Change in Poverty - All products",
                      plotOutput("boxplot_all", height = 400))
                )
        )
        
        )))


server <- function(input, output) {
  output$readme <- renderUI({
    HTML(markdown::markdownToHTML(knit('README.md', quiet = TRUE),
                                  style=list(html.output='diff.w.style')))

  })

  load_data <- reactive({
    if (input$shock_component=='Grains') {
      data <- read_csv('simulations_concat_Granos.csv') %>% 
        filter(pais_c!='GUY')  
    } else if (input$shock_component=='Grains, Breads and Cereals'){
    data <- read_csv('simulations_concat.csv') %>% 
      filter(pais_c!='GUY')
    }else if (input$shock_component=='All - No meat'){
      data <- read_csv('simulations_concat_all_no_meat.csv') %>% 
        filter(pais_c!='GUY')
    }else if (input$shock_component=='All'){
      data <- read_csv('simulations_concat_all.csv') %>% 
        filter(pais_c!='GUY')
    }
    
    return(data)
  })

  load_data_shock <- reactive({
    data <- load_data() %>%
      filter(shock_weight %in% c(0.0, round(input$shock,1))) 
    return(data)
  })
  
    
  
  
  output$downloadData <- downloadHandler(
    filename = function() {
      str_c('simulations_demo_shock_level_',toString(round(input$shock,1)), ".csv")
    },
    content = function(file) {
      write.csv(load_data() %>%
                  filter(shock_weight==round(input$shock,1)),
                file, row.names = FALSE)
    }
  )

  output$pdf <- downloadHandler(
    filename = "report.pdf",
    content = function(file) {
      file.copy("README.pdf", file)
    }
  )
  output$downloadDict <- downloadHandler(
    filename = function() {
      paste('simulations_demo', ".csv", sep = "")
    },
    content = function(file) {
      write.csv(load_data(), file, row.names = FALSE)
    }
  )
  
  output$realpoor <- renderPlot({
    library(colorspace)
    data<-load_data_shock()
    #qcolor <- qualitative_hcl(length(unique(data$pais_c)), "blues3")
    
    data %>% filter(shock_weight==0) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national', 'poor_e_national')) %>% 
      mutate(indicator = case_when(indicator=='poor_national' ~ 'Poverty',
                                   indicator=='poor_e_national' ~ 'Extreme Poverty')) %>% 
      ggplot(aes(x=reorder(pais_c, desc(value)), y=value, fill=pais_c)) + 
      geom_bar(stat="identity") +
      scale_y_continuous(labels=scales::percent) +
      geom_text(aes( label = round(value*100,2),group=1),
                nudge_y=0.125,
                va='bottom',
                size=3) +  
      facet_wrap(~indicator) + 
      theme_minimal() +
      scale_fill_discrete_sequential(palette = 'blues 2') +
      #scale_fill_grey(start = 0.8, end = 0.2) +
      theme(legend.position = "none") +   
      ylab('value') +
      xlab('Country') +
      ggtitle('Latin American and the Caribbean Poverty Rates by country (% of population)') +
      theme(plot.title = element_text(size = 15, face = "bold")) +      
      coord_flip()+ 
      labs(caption = "The poverty is estimated with the official poverty line. BHS, BRB, BLZ, SUR and VEN was estimated with international poverty lines (US $ 3.1 and US $ 5).")
  })
  

  output$deltapoor <- renderPlot({
    
    load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national_delta', 'poor_e_national_delta')) %>% 
      mutate(indicator = case_when(indicator=='poor_national_delta' ~ 'Poverty',
                                   indicator=='poor_e_national_delta' ~ 'Extreme Poverty')) %>%       
      ggplot(aes(x=reorder(pais_c, desc(value)), y=value,  fill=pais_c)) + 
      geom_bar(stat="identity") +
      scale_y_continuous(labels=scales::percent) +
      geom_text(aes( label = round(value*100,2),group=1),
                nudge_y=0.125,
                va='bottom',
                size=3) +  
      facet_wrap(~indicator) + 
      theme_minimal() +
      theme(legend.position = "none") +   
      #scale_fill_grey(start = 0.8, end = 0.2) + 
      scale_fill_discrete_sequential(palette = 'blues 2') +
      ylab('value') +
      xlab('Country') +
      ggtitle(' Latin American and the Caribbean Poverty Rates by country with price shock (% of population)') + 
      theme(plot.title = element_text(size = 15, face = "bold")) +
      coord_flip()+ 
      labs(caption = "Notes: The poverty is estimated with the official poverty line.
           BHS, BRB, BLZ, SUR and VEN was estimated with international poverty lines (US $ 3.1 and US $ 5).")
  })
  
  output$diff <- renderPlot({
    
    t <- load_data_shock()  %>% 
      filter(shock_weight %in% c( round(input$shock,1))) %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased')) %>% 
      select(anio_c, pais_c,  type, poor_national_change, poor_e_national_change) 
    
    
    
    cbPallete <- c("Decreased"= "green", "Increased"="red")
    
    t %>% 
      ggplot(aes(x=reorder(pais_c, -poor_national_change),
                 y=poor_national_change,
                 color = type)) +   
      geom_point(size = 4) + 
      geom_line(aes(group = pais_c)) +
      scale_colour_manual(values = c("Decreased"= "#a1d99b", "Increased"="#fc9272")) +   
      theme_minimal() +
      coord_flip() +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +  
      geom_segment(aes(xend=pais_c, yend=0, color=type)) + 
      theme(plot.title = element_text(size = 15, face = "bold")) +      
      geom_text(aes( label = round(poor_national_change,2),group=1),
                nudge_y=0.125,
                va='bottom', color='black',
                size=3) +              theme(legend.position = "none") +
      ylab("Change (last value - simulated value)") +
      ggtitle('Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock') + 
      xlab('Country') +
      labs(caption = "Notes:
      - Negative values are a reduction of poverty in percentage points")      
    
    
  })  
  
  output$boxplot_granos <- renderPlot({
    data <- read_csv('simulations_concat_Granos.csv') %>% 
      filter(pais_c!='GUY')
    t <- data  %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased'),
             type = as_factor(type)) %>% 
      select(anio_c, pais_c,  poor_national_change:poor_e_national_change) %>% 
      pivot_longer(poor_national_change:poor_e_national_change, 'indicator') %>% 
      mutate(indicator = case_when(indicator=='poor_national_change' ~ 'Poverty',
                                   indicator=='poor_e_national_change' ~ 'Extreme Poverty')) 
    
    t %>% 
      group_by(pais_c) %>% 
      mutate(mx = min(value[indicator=='Poverty'])) %>% 
      ungroup() %>% 
      ggplot(aes(x=reorder(pais_c, desc(mx)), y=value, fill=indicator)) +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +    
      geom_boxplot() + 
      theme_minimal() + 
      scale_fill_manual(values = c("Poverty"= "#D3DDDC", "Extreme Poverty"="#fc9272")) +   
      ylab('value') +
      xlab('Country') +
      coord_flip() +
      ylab("Change (last value - simulated value)") +
      ggtitle( 'Results of simulating the effect of a shock of 10 to 50 percent on the price of *Grains*') + 
      labs(caption = 'Notes:
      - Negative values are a reduction of poverty in percentage points \n
      - Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock ')
  })
    
  output$boxplot <- renderPlot({
    data <- read_csv('simulations_concat.csv') %>% 
      filter(pais_c!='GUY')
    
    t <- data  %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased'),
             type = as_factor(type)) %>% 
      select(anio_c, pais_c,  poor_national_change:poor_e_national_change) %>% 
      pivot_longer(poor_national_change:poor_e_national_change, 'indicator') %>% 
      mutate(indicator = case_when(indicator=='poor_national_change' ~ 'Poverty',
                                   indicator=='poor_e_national_change' ~ 'Extreme Poverty')) 
    
    t %>% 
      group_by(pais_c) %>% 
      mutate(mx = min(value[indicator=='Poverty'])) %>% 
      ungroup() %>% 
      ggplot(aes(x=reorder(pais_c, desc(mx)), y=value, fill=indicator)) +      
      geom_hline(yintercept=0, linetype="dashed", color = "red") +    
      geom_boxplot() + 
      theme_minimal() + 
      scale_fill_manual(values = c("Poverty"= "#D3DDDC", "Extreme Poverty"="#fc9272")) +   
      ylab('value') +
      xlab('Country') +
      coord_flip() +
      ylab("Change (last value - simulated value)") +
      ggtitle( ggtext::element_markdown('Results of simulating the effect of a shock of 10 to 50 percent on the price of *Grains, Breads and Cereals*')) + 
      labs(caption = 'Notes:
      - Negative values are a reduction of poverty in percentage points \n
      - Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock ')
  })
  
  

  

  
  output$boxplot_all_no_meat <- renderPlot({
    data <- read_csv('simulations_concat_all_no_meat.csv') %>% 
      filter(pais_c!='GUY')
    t <- data  %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased'),
             type = as_factor(type)) %>% 
      select(anio_c, pais_c,  poor_national_change:poor_e_national_change) %>% 
      pivot_longer(poor_national_change:poor_e_national_change, 'indicator') %>% 
      mutate(indicator = case_when(indicator=='poor_national_change' ~ 'Poverty',
                                   indicator=='poor_e_national_change' ~ 'Extreme Poverty')) 
    
    t %>% 
      group_by(pais_c) %>% 
      mutate(mx = min(value[indicator=='Poverty'])) %>% 
      ungroup() %>% 
      ggplot(aes(x=reorder(pais_c, desc(mx)), y=value, fill=indicator)) +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +    
      geom_boxplot() + 
      theme_minimal() + 
      scale_fill_manual(values = c("Poverty"= "#D3DDDC", "Extreme Poverty"="#fc9272")) +   
      ylab('value') +
      xlab('Country') +
      coord_flip() +
      ylab("Change (last value - simulated value)") +
      ggtitle( 'Results of simulating the effect of a shock of 10 to 50 percent on the price of *All - Meat*') + 
      labs(caption = 'Notes:
      - Negative values are a reduction of poverty in percentage points \n
      - Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock ')
  })

  output$boxplot_all <- renderPlot({
    data <- read_csv('simulations_concat_all.csv') %>% 
      filter(pais_c!='GUY')
    t <- data  %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased'),
             type = as_factor(type)) %>% 
      select(anio_c, pais_c,  poor_national_change:poor_e_national_change) %>% 
      pivot_longer(poor_national_change:poor_e_national_change, 'indicator') %>% 
      mutate(indicator = case_when(indicator=='poor_national_change' ~ 'Poverty',
                                   indicator=='poor_e_national_change' ~ 'Extreme Poverty')) 
    
    t %>% 
      group_by(pais_c) %>% 
      mutate(mx = min(value[indicator=='Poverty'])) %>% 
      ungroup() %>% 
      ggplot(aes(x=reorder(pais_c, desc(mx)), y=value, fill=indicator)) +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +    
      geom_boxplot() + 
      theme_minimal() + 
      scale_fill_manual(values = c("Poverty"= "#D3DDDC", "Extreme Poverty"="#fc9272")) +   
      ylab('value') +
      xlab('Country') +
      coord_flip() +
      ylab("Change (last value - simulated value)") +
      ggtitle( 'Results of simulating the effect of a shock of 10 to 50 percent on the price of *All*') + 
      labs(caption = 'Notes:
      - Negative values are a reduction of poverty in percentage points \n
      - Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock ')
  })  
  
}

shinyApp(ui, server)