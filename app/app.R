#library(shinydashboard)
options(warn = -1)


library(semantic.dashboard)
library(shiny)
library(tidyverse)
library(ggtext)
library(knitr)
library(plotly)
library(scales)
library(tidytext)
library(leaflet)
library(colorspace)
library(sf)

library(idbsocialdataR)
height_='100em'

skip_countries <- c('Guyana', 'Venezuela')
skip_iso <- c('GUY', 'VEN')

#install.packages("devtools")
#devtools::install_github("EL-BID/idbsocialdataR@main")
countries <- idbsocialdataR:::get_countries() %>% select(isoalpha3, country_name_en) 

gdp_data <- read_csv('gdp_output.csv') %>% 
  filter(year==2020)%>% 
  dplyr::select(year, isoalpha3, value) %>% 
  filter(isoalpha3 %in% countries$isoalpha3) %>% 
  rename(pais_c=isoalpha3, gdp=value) %>% #anio_c=year, 
  filter(!pais_c %in% skip_iso) %>% 
  select(-year)

### Source
data_source <- read_csv('simulations_concat.csv') %>% 
  mutate(isoalpha3 = pais_c) %>% 
  left_join(countries) %>% 
  left_join(gdp_data) %>% 
  filter(!country_name_en %in% skip_countries)

# map <- idbsocialdataR:::get_map()


ui <- dashboardPage(
  dashboardHeader(title = "SCL Policy Simulator"),
  
  dashboardSidebar(sidebarMenu(
    menuItem(tabName = "description", text = "Description", icon = icon("info")),
    menuItem(tabName = "simulator", text = "Simulator", icon = icon("lab")),
    # menuItem(tabName = "LACmap", text = "Map results", icon = icon("globe")),
    menuItem(tabName = "regionresults", text = "Distribution results", icon = icon("globe"))
  )),
  
  dashboardBody(tabItems(
        tabItem(tabName='description',
                div(style="display:inline-block",downloadButton("pdf", label="Download Report", class = "butt2"),
                    style="float:left"),
                tags$head(tags$style(".butt2{background-color:#a1d99b;} .butt2{color: white;} .butt2{font-style: italic;}")),
                
                box(title = "Project Readme",
                    status = "primary",
                    solidHeader = F,
                    collapsible = T, width = 12,
                    column(12, htmlOutput("readme2"))
                    #column(12, includeMarkdown("README.md"))
                    #column(12, uiOutput('markdown'))
                    #htmlOutput("README.html")
                    #includeHTML('README.html')
                    ) 

        ),
    
        tabItem(tabName = "simulator",
                
              fluidRow(
                box(
                  height = 500,
                  title = "External Shock",
                  width = 4,
                  height =  "height:1000px;" ,
                  status = "warning", 
                  solidHeader = FALSE, 
                  collapsible = TRUE,
                  
                  h2("Country Controls"),
                  selectInput("country", "Country: ",
                              append(c('All'),sort(countries$country_name_en)),
                              selected='All'),
                  h3(""),
                  h2("Shock Controls"),
                  selectInput("shock_component", "shock_component:",
                              c('Grains', 'Grains, Breads and Cereals',
                                'All - No meat', 'All'),
                              selected='All - No meat'),
                  p('Choose the components that will be affected by the exogenous shock'),
                  h3("Schock Level"),
                  sliderInput("shock", "Shock level:",min = 0, max = .5, 
                              step = .1, value=.2),
                  p('Choose the pct change of exogenous shock'),
                  br(' '),
                  downloadButton("downloadData", "Download Simulation Results")
                  ),
                box(
                  title = "Growth",
                  width = 4,
                  height = 500,
                  status = "warning", 
                  solidHeader = FALSE, 
                  collapsible = TRUE,
                  h3(""),
                  h2("Growth Controls"),
                  selectInput("gdp_growth", "Projected growth:",
                              c('IMF', 'None'),
                              selected='IMF'),
                  p('To control for the economic growth you can Use the International Monetary Fund (IMF)
                    projections for the year 2022. In this phase of the project we impact the income of all households in each country with the same weighting.'),
                  h3("Heterogeneous impact"),
                  selectInput("shock_population", "Impact-resilient population:",
                              c('agricultural sector', 'None'),
                              selected='agricultural sector'),
                  p('Positive wage effect to employers and self-employed 
                      who belong to the agricultural sector. 
                      The positive effect cancels out the impact of the exogenous shock for these families.'),
                  br(' '),
                  
                ),
                tabBox(title = "LAC Poverty Change", color = "grey",
                       tabs = list(
                         list(menu = "LAC Pct Change",
                              content = plotlyOutput("lac_change", height = 450)),                         
                         list(menu = "Main Results", 
                              content =
                                fluidRow(
                                  column(width = 8,
                                    valueBox(
                                      tags$p("People who transitioned into poverty (Crossing the moderate poverty line)",
                                             style = "font-size: 80%;"),
                                      span(textOutput("population_count"),style = "font-size: 80%;"),
                                      color = "yellow", width = 8),
                                    br(''),
                                    valueBox(
                                      tags$p("Monthly resources required mitigate the effect (USD)
                                            Sum of the economic impact on people who transitioned into poverty (Crossing the moderate poverty line).",
                                             style = "font-size: 80%;"),
                                      span(textOutput("resources_required_new"),
                                           style = "font-size: 80%;"),
                                      color = "blue", width = 8),
                                    br(''),
                                    valueBox(
                                      tags$p("Monthly resources required mitigate the effect (USD)
                                        (Sum of the economic impact on **All Families** below the moderate poverty line).",
                                             style = "font-size: 80%;"),
                                      span(textOutput("resources_required")
                                           ,style = "font-size: 80%;"),
                                      color = "red", width = 8),
                                    br(''),
                                    valueBox(
                                      tags$p("Monthly resources required mitigate the effect (USD)
                                        (Sum of the economic impact on **All Families**.",
                                             style = "font-size: 80%;"),
                                      span(textOutput("national_resources_required")
                                           ,style = "font-size: 80%;"),
                                      color = "red", width = 8)
                                  ),
                                  column(width = 8,
                                    valueBox(
                                      tags$p("Annual GDP (current US$) World Bank national accounts data, and OECD National Accounts data files.",
                                             style = "font-size: 80%;"),
                                      span(textOutput("gdp")
                                           ,style = "font-size: 80%;"),
                                      color = "green", width = 8),
                                    br(''),
                                    valueBox(
                                      tags$p("cesources required mitigate the effect (GDP)
                                            Sum of the economic impact on people who transitioned into poverty (Crossing the moderate poverty line).",
                                             style = "font-size: 80%;"),
                                      span(textOutput("resources_required_new_gdp"),
                                           style = "font-size: 80%;"),
                                      color = "blue", width = 8),
                                    br(''),
                                    valueBox(
                                      tags$p("Resources required mitigate the effect (GDP)
                                        (Sum of the economic impact on **All Families** below the moderate poverty line).",
                                             style = "font-size: 80%;"),
                                      span(textOutput("resources_required_gdp")
                                           ,style = "font-size: 80%;"),
                                      color = "red", width = 8),
                                    br(''),
                                    valueBox(
                                      tags$p("Resources required mitigate the effect (GDP)
                                        (Sum of the economic impact on **All Families**.",
                                             style = "font-size: 80%;"),
                                      span(textOutput("national_resources_required_gdp")
                                           ,style = "font-size: 80%;"),
                                      color = "red", width = 8)
                                    ))
                              ),
                         list(menu = "Map Pct Point Change",
                              content = plotlyOutput("mymap", height = 450))
                         ))),
              fluidRow(tabBox(title = "Poverty Rates", color = "grey",
                              tabs = list(
                                list(menu = "Official Poverty",
                                     content = plotlyOutput("realpoor", height = 400)),
                                list(menu = "Poverty after shock",
                                     content =plotlyOutput("deltapoor", height = 400)))),
                       tabBox(title = "Poverty change", color = "grey",
                              tabs = list(
                                list(menu = "Change in Poverty",
                                     content = plotlyOutput("diff", height = 400)),
                                list(menu = "Change in Extreme Poverty",
                                     content =plotlyOutput("diff_e", height = 400))))
                       ),
              fluidRow(box(title = "Transition into poverty",
                           plotlyOutput("deltapop", height = 400)),
                       box(title = "Recovery (USD)",
                           plotlyOutput("deltarecov", height = 400))
                       )

        # tabItem(tabName = "LACmap",
        #         fluidRow(
        #           box(title = "Map",
        #               leafletOutput("lac_map"))
        # )),
        ),
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
  #   
  #   output$mymap <- renderLeaflet({
  #     
  #     leaflet() %>% 
  #       addTiles() %>% 
  #       setView()
  #     
  #     library(leaflet)
  #     
  #     m <- leaflet() %>%
  #       addTiles()
  #   })
  
  output$mymap <-  renderPlotly({
    indicator <- 'poor_national_change'
    t <- load_data_shock()  %>% 
      filter(shock_weight %in% c( round(input$shock,1))) %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased')) %>% 
      select(anio_c, pais_c,  type, poor_national_change, poor_e_national_change) 
    
    output <- idbsocialdataR:::get_map() %>%
      mutate(pais_c = isoalpha3) %>% 
      left_join(t)
    indicator<-'poor_national_change'
    p <- ggplot(data = output, aes(fill = poor_national_change)) +
      geom_sf(size = 0.25) +
      scale_fill_distiller(name='Percentage Point Change in Poverty',
                           palette = "Blues",
                           breaks = pretty_breaks(), direction=1)+
      theme(axis.text.x = element_blank(),
            axis.text.y = element_blank(),
            axis.ticks = element_blank(),
            panel.background = element_rect(fill = "white", color = NA))
    
    ggplotly(p)
    
    })

  ############
  ##### Output
  ############  
  
  output$readme <- renderUI({
    includeHTML(rmarkdown::render("README.md", 'html_document'))

  })
  
  output$readme2 <- renderUI({
    HTML(markdown::markdownToHTML('README.md',
                                  style=list(html.output='diff.w.style')))
  })

  output$readme3 <- renderUI({
    HTML(markdown::markdownToHTML(knit('README.md', quiet = TRUE),
                                  style=list(html.output='diff.w.style')))
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

  output$pdf <- downloadHandler(filename = "report.pdf",
                                content = function(file) {
                                  file.copy("README.pdf", file)
                                }
  )
  
  # output$pdf_download = downloadHandler(
  #   filename = 'report.pdf',
  #   
  #   content = function(file) {
  #     #out = knit2pdf('README.md', clean = TRUE)
  #     out = rmarkdown::render("README.md", 'pdf_document')
  #     file.rename(out, file) # move pdf to file for downloading
  #   },
  #   
  #   contentType = 'application/pdf'
  # )
  
  output$downloadDict <- downloadHandler(
    filename = function() {
      paste('simulations_demo', ".csv", sep = "")
    },
    content = function(file) {
      write.csv(load_data(), file, row.names = FALSE)
    }
  )
  
  
  
  
  ############
  ##### Data
  ############  
  
  load_data_pre <- reactive({
    data <- data_source %>% 
      filter(!country_name_en %in% skip_countries) 
    
    if (input$country!='All') {
      data <- data %>% 
        filter(country_name_en==input$country) 
    } 
    
    if (input$gdp_growth=='IMF') {
      data <- data %>% 
        filter(gdp_growth=='IMF') 
    } else if (input$gdp_growth!='IMF'){
      data <- data %>% 
        filter(is.na(gdp_growth))
    }
  })
  
  load_data <- reactive({
    data <- load_data_pre()
    if (input$shock_population=='agricultural sector') {
      data <- data %>% 
        filter(shock_population=='sec_agri') 
    }    
    
    if (input$shock_component=='Grains') {
      data <- data %>% 
        filter(shock_component=='Granos') 
    } else if (input$shock_component=='Grains, Breads and Cereals'){
      data <- data %>% 
        filter(shock_component=='Granos_panes_cereales')
    }else if (input$shock_component=='All - No meat'){
      data <- data %>% 
        filter(shock_component=='all_no_meat')
    }else if (input$shock_component=='All'){
      data <- data %>% 
        filter(shock_component=='all') 
    }
    
    return(data)
  })
  
  load_data_shock <- reactive({
    data <- load_data() %>%
      filter(shock_weight %in% c(0.0, round(input$shock,1))) 
    #%>% filter((pais_c %in% c('GTM', 'JAM'))==FALSE)
    return(data)
  })
  
  ############
  ##### Values
  ############
  
  gdp_num <-reactive({
    count<- load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(gdp, 'indicator') %>% 
      filter(indicator=='gdp') %>% 
      summarise(value = sum(value,na.rm = TRUE)) %>% pull(value)
    return(count) 
  })
  
  population_count_num <-reactive({
    count <- load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national_new_pop', 'poor_e_national_new_pop')) %>% 
      mutate(indicator = case_when(indicator=='poor_national_new_pop' ~ 'Poverty',
                                   indicator=='poor_e_national_new_pop' ~ 'Extreme Poverty')) %>% 
      filter(indicator=='Poverty') %>% 
      summarise(value = sum(value,na.rm = TRUE)) %>% pull(value)
    return(count) 
  })
  
  resources_national_required_num <-reactive({
    count<-     load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('national_recovery')) %>% 
      filter(indicator=='national_recovery') %>% 
      summarise(value = sum(value,na.rm = TRUE)) %>% pull(value) 
    
    return(count) 
  })  
  
  resources_required_num <-reactive({
    count<-     load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national_recovery', 'poor_e_national_recovery')) %>% 
      mutate(indicator = case_when(indicator=='poor_national_recovery' ~ 'Poverty',
                                   indicator=='poor_e_national_recovery' ~ 'Extreme Poverty')) %>%
      filter(indicator=='Poverty') %>% 
      summarise(value = sum(value,na.rm = TRUE)) %>% pull(value) 
    
    return(count) 
  })  
  
  resources_required_new_num <-reactive({
    count<-     load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national_new_recovery', 'poor_e_new_national_recovery')) %>% 
      mutate(indicator = case_when(indicator=='poor_national_new_recovery' ~ 'Poverty',
                                   indicator=='poor_e_new_national_recovery' ~ 'Extreme Poverty')) %>%
      filter(indicator=='Poverty') %>% 
      summarise(value = sum(value,na.rm = TRUE)) %>% pull(value)
    return(count) 
  })
  
  output$gdp <-renderText({
    count<- gdp_num()
    return( label_number_si(accuracy=0.001)(count)) 
  })
  
  output$population_count <-renderText({
    count<- population_count_num()
    return( label_number_si(accuracy=0.001)(count)) 
  })
  
  output$resources_required <-renderText({
    count<- resources_required_num()
    return( label_number_si(accuracy=0.001)(count)) 
  })  
  
  output$resources_required_new <-renderText({
    count<- resources_required_new_num()
    return( label_number_si(accuracy=0.001)(count)) 
  })  
  
  output$national_resources_required <-renderText({
    count<- resources_national_required_num()
    return( label_number_si(accuracy=0.001)(count)) 
  })  
  
  
  output$resources_required_gdp <-renderText({
    count<- resources_required_num()*12/gdp_num()
    return( label_percent(accuracy=0.001,suffix = " %")(count)) 
  })  
  
  output$resources_required_new_gdp <-renderText({
    count<- resources_required_new_num()*12/gdp_num()
    return( label_percent(accuracy=0.001, suffix = " %")(count)) 
  })  
  
  output$national_resources_required_gdp <-renderText({
    count<- resources_national_required_num()*12/gdp_num()
    return( label_percent(accuracy=0.001, suffix = " %")(count)) 
  })  
  
  
  
  ############
  ##### Plots
  ############
  output$lac_change <- renderPlotly({
    p<-load_data_shock() %>% 
      filter(shock_weight==round(input$shock,1)) %>% 
      summarize(poor_national_pop=sum(poor_national_pop, na.rm = T),
                poor_e_national_pop=sum(poor_e_national_pop, na.rm = T),
                poor_national_delta_pop=sum(poor_national_delta_pop, na.rm = T),
                poor_e_national_delta_pop=sum(poor_e_national_delta_pop, na.rm = T),
                population_nat=sum(population_nat, na.rm = T)) %>% 
      mutate(poor_pct=poor_national_pop/population_nat,
             poor_e_pct=poor_e_national_pop/population_nat,
             poor_pct_delta=poor_national_delta_pop/population_nat,
             poor_e_pct_delta=poor_e_national_delta_pop/population_nat) %>% 
      mutate(poor_pct_change = poor_pct_delta - poor_pct,
             poor_e_pct_change = poor_e_pct_delta - poor_e_pct) %>% 
      pivot_longer(poor_pct_change:poor_e_pct_change, names_to = 'indicator', values_to='value') %>% 
      filter(indicator %in% c('poor_pct_change', 'poor_e_pct_change')) %>% 
      mutate(indicator = case_when(indicator=='poor_pct_change' ~ 'Poverty',
                                   indicator=='poor_e_pct_change' ~ 'Extreme Poverty')) %>% 
      mutate(type = if_else(value<0,'Decreased', 'Increased')) %>% 
      ggplot(aes(x=indicator,
                 y=value,
                 color = type)) +   
      geom_point(size = 2) + 
      geom_line(aes(group = indicator)) +
      scale_colour_manual(values = c("Decreased"= "#a1d99b", "Increased"="#fc9272")) +   
      theme_minimal() +
      coord_flip() +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +  
      geom_segment(aes(xend=indicator, yend=0, color=type)) + 
      scale_y_continuous(labels=scales::percent) +      
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      geom_text(aes( label = round(value,3)*100,group=1),
                nudge_x=0.2,
                va='bottom', color='black',
                size=2) +  
      theme(legend.position = "none") +
      ylab("Change (last value - simulated value)") +
      ggtitle('Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock') + 
      xlab('Country') +
      labs(caption = "Notes:
      - Negative values are a reduction of poverty in percentage points")      
    
    ggplotly(p) %>% style(hoverinfo = 'none')
  })
  
  
  
  
  
  output$realpoor <- renderPlotly({
    data<-load_data_shock()
    #qcolor <- qualitative_hcl(length(unique(data$pais_c)), "blues3")
    
    p <- data %>% filter(shock_weight==0) %>% 
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
                size=2) +  
      facet_wrap(~indicator) + 
      theme_minimal() +
      scale_fill_discrete_sequential(palette = 'blues 2') +
      #scale_fill_grey(start = 0.8, end = 0.2) +
      theme(legend.position = "none") +   
      ylab('value') +
      xlab('Country') +
      ggtitle('Latin American and the Caribbean Poverty Rates by country (% of population)') +
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      coord_flip()+ 
      labs(caption = "The poverty is estimated with the official poverty line. BHS, BRB, BLZ, SUR and VEN was estimated with international poverty lines (US $ 3.1 and US $ 5).")
    ggplotly(p) %>% style(hoverinfo = 'none')
  })
  

  output$deltapoor <- renderPlotly({
    
    p <- load_data_shock() %>%
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
                size=2) +  
      facet_wrap(~indicator) + 
      theme_minimal() +
      theme(legend.position = "none") +   
      #scale_fill_grey(start = 0.8, end = 0.2) + 
      scale_fill_discrete_sequential(palette = 'blues 2') +
      ylab('value') +
      xlab('Country') +
      ggtitle(' Latin American and the Caribbean Poverty Rates by country with price shock (% of population)') + 
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      coord_flip()+ 
      labs(caption = "Notes: The poverty is estimated with the official poverty line.
           BHS, BRB, BLZ, SUR and VEN was estimated with international poverty lines (US $ 3.1 and US $ 5).")
    ggplotly(p) %>% style(hoverinfo = 'none')
  })
  
  output$diff <- renderPlotly({
    
    t <- load_data_shock()  %>% 
      filter(shock_weight %in% c( round(input$shock,1))) %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_national_change<0,'Decreased', 'Increased')) %>% 
      select(anio_c, pais_c,  type, poor_national_change, poor_e_national_change) 
    
    
    
    cbPallete <- c("Decreased"= "green", "Increased"="red")
    
    p <- t %>% 
      ggplot(aes(x=reorder(pais_c, -poor_national_change),
                 y=poor_national_change,
                 color = type)) +   
      geom_point(size = 2) + 
      geom_line(aes(group = pais_c)) +
      scale_colour_manual(values = c("Decreased"= "#a1d99b", "Increased"="#fc9272")) +   
      theme_minimal() +
      coord_flip() +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +  
      geom_segment(aes(xend=pais_c, yend=0, color=type)) + 
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      geom_text(aes( label = round(poor_national_change,2),group=1),
                nudge_y=0.125,
                va='bottom', color='black',
                size=2) +              theme(legend.position = "none") +
      ylab("Change (last value - simulated value)") +
      ggtitle('Percentage Point Change in Poverty: Real poverty rate minus poverty rate with price shock') + 
      xlab('Country') +
      labs(caption = "Notes:
      - Negative values are a reduction of poverty in percentage points")      
    
    ggplotly(p) %>% style(hoverinfo = 'none')
  })  
  
  
  output$diff_e <- renderPlotly({
    
    t <- load_data_shock()  %>% 
      filter(shock_weight %in% c( round(input$shock,1))) %>% 
      select(anio_c, pais_c,  shock_weight,  everything()) %>% 
      mutate(poor_national_change = (poor_national_delta - poor_national)*100,
             poor_e_national_change = (poor_e_national_delta - poor_e_national)*100, 
             type = if_else(poor_e_national_change<0,'Decreased', 'Increased')) %>% 
      select(anio_c, pais_c,  type, poor_national_change, poor_e_national_change) 
    
    
    
    cbPallete <- c("Decreased"= "green", "Increased"="red")
    
    p <- t %>% 
      ggplot(aes(x=reorder(pais_c, -poor_e_national_change),
                 y=poor_e_national_change,
                 color = type)) +   
      geom_point(size = 2) + 
      geom_line(aes(group = pais_c)) +
      scale_colour_manual(values = c("Decreased"= "#a1d99b", "Increased"="#fc9272")) +   
      theme_minimal() +
      coord_flip() +
      geom_hline(yintercept=0, linetype="dashed", color = "red") +  
      geom_segment(aes(xend=pais_c, yend=0, color=type)) + 
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      geom_text(aes( label = round(poor_e_national_change,2),group=1),
                nudge_y=0.125,
                va='bottom', color='black',
                size=2) +              theme(legend.position = "none") +
      ylab("Change (last value - simulated value)") +
      ggtitle('Percentage Point Change in Extreme Poverty: Real poverty rate minus poverty rate with price shock') + 
      xlab('Country') +
      labs(caption = "Notes:
      - Negative values are a reduction of poverty in percentage points")      
    
    ggplotly(p) %>% style(hoverinfo = 'none')
  })  
  # Gap People
  
  output$deltapop <- renderPlotly({
    require(scales)
    
    
    p<-load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national_new_pop', 'poor_e_national_new_pop')) %>% 
      mutate(indicator = case_when(indicator=='poor_national_new_pop' ~ 'Poverty',
                                   indicator=='poor_e_national_new_pop' ~ 'Extreme Poverty')) %>%       
      ggplot(aes(x=reorder(pais_c, desc(value)), y=value,  fill=pais_c)) + 
      geom_bar(stat="identity") +
      facet_wrap(~indicator) + 
      theme_minimal() +
      theme(legend.position = "none") +   
      scale_y_continuous(labels = comma) + 
      scale_fill_discrete_sequential(palette = 'blues 2') +
      ylab('value') +
      xlab('Country') +
      ggtitle('People who transitioned into poverty after the shock (Population)') + 
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      coord_flip()+ 
      labs(caption = "Notes: The poverty is estimated with the official poverty line.
           BHS, BRB, BLZ, SUR and VEN was estimated with international poverty lines (US $ 3.1 and US $ 5).")
    ggplotly(p) %>% style(hoverinfo = 'none')
  })
  
  
  output$deltarecov <- renderPlotly({
    
    p<-load_data_shock() %>%
      filter(shock_weight==round(input$shock,1)) %>% 
      pivot_longer(population:poor_e_national_delta, 'indicator') %>% 
      filter(indicator %in% c('poor_national_new_recovery', 'poor_e_national_new_recovery')) %>% 
      mutate(indicator = case_when(indicator=='poor_national_new_recovery' ~ 'Poverty',
                                   indicator=='poor_e_national_new_recovery' ~ 'Extreme Poverty')) %>%       
      mutate(indicator = as.factor(indicator),
             pais_c = as.factor(pais_c),
             pais_c = reorder_within(pais_c, desc(value), indicator)) %>% 
      ggplot(aes(x=pais_c, y=value,  fill=pais_c)) + 
      geom_col(show.legend = FALSE) +
      geom_bar(stat="identity") +

      scale_y_continuous(labels = comma) + 
      facet_wrap(indicator~., scales = "free") + 
      theme_minimal() +
      theme(legend.position = "none") +   
      scale_y_continuous(labels = comma) + 
      scale_fill_discrete_sequential(palette = 'blues 2') +
      ylab('value') +
      xlab('Country') +
      ggtitle('Monthly resources required to mitigate the effect (USD)') + 
      theme(plot.title = element_text(size = 10, face = "bold"),
            text = element_text(size = 8)) +      
      coord_flip()+ 
      scale_x_reordered() +
      labs(caption = "Notes: The poverty is estimated with the official poverty line.
           BHS, BRB, BLZ, SUR and VEN was estimated with international poverty lines (US $ 3.1 and US $ 5).")
    ggplotly(p) %>% style(hoverinfo = 'none')
  })
  
  
  
  ## Boxplot 
  
  output$boxplot_granos <- renderPlot({
    data <- load_data_pre()
    data <- data %>% 
      filter(shock_component=='Granos') 
    
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
    data <- load_data_pre()
    data <- data %>% 
      filter(shock_component=='Granos_panes_cereales')
    
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
    data <- load_data_pre()
    data <- data %>% 
      filter(shock_component=='all_no_meat')
    
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
    data <- load_data_pre()
    data <- data %>% 
      filter(shock_component=='all')
    
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
