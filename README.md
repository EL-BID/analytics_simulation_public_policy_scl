**SCL Data - Data Ecosystem Working Group**

[![IDB Logo](https://scldata.iadb.org/assets/iadb-7779368a000004449beca0d4fc6f116cc0617572d549edf2ae491e9a17f63778.png)](https://scldata.iadb.org)


# Rising Food Prices and Poverty in Latin America and the Caribbean:
## Effect of Ukrainian invasion

_Lina Arias, Laura Goyeneche; Roberto Sanchez; Luis Tejerina; Eric Torres_

# Index 

1. <a id = "introduction" >Introduction</a>
2. <a id = "methodology" >Methodology</a>
3. <a id = "data-preparation" >Data Preparation</a>
4. <a id = "sim" >Simulation</a>
5. <a id = "con" >Results</a>
6. <a id = "con" >Next Steps</a>
7. <a id = "references" >References</a>


## [Introduction](introduction) 

Changes in food prices always have an impact on people's lives, especially on the most vulnerable. Understanding the impact that exogenous shocks can have, the location and characteristics of the most affected population is fundamental to be able to carry out policy responses to mitigate their effects. The objective of this repository is to create a tool capable of simulating the impact of rising food prices in the Latin American and Caribbean region using a microdata simulation approach from household surveys data.

## [Methodology](#methodology) 

In this first phase of the project, we simulated the impact of price changes on commodities that belong to the basic food basket.

The adjustment is made by impacting each country's poverty line by the percentage that each commodity represents in the line as a whole.

We consider the effects of changes in household welfare through: 

- Direct changes in consumption levels due to changes in consumer prices (Net food buyers)
    - We take into consideration that the price impact does not affect in the same way food-producing households.
- We include a parameter to account for income increase due to GDP growth.


## [Data Preparation](data-preparation) 

### Harmonizing household surveys

Household surveys are the instruments used to analyze poverty and inequality. In this project, the first step was to work on creating a harmonized household-level data set for 25 countries in the region. The list of countries, household surveys, year of data collection and sample sizes are reported in Table 1.

#### Income and consumption

Given that the objective is to analyze the impact of price variation on national poverty rates, it was essential to replicate and harmonize its construction across all countries in the region. To achieve this, the main preprocessing work was the reconstruction of each country's official per capita income/consumption methodology. In Latin America, most countries use household income to measure poverty rates against a welfare line. However, some countries prefer per capita consumption, arguing that consumption fluctuates less over time than income, keeping results more comparable over time (IDB, 2018). This is the case for countries such as Suriname, Barbados and Peru. 

When official per capita income is not available, the estimated income for this exercise includes labor and non-labor income. Labor income includes monetary and non-monetary wages. Non-labor income is defined by pensions, remittances, cash transfers and other income.   

#### Identification of food-producers

As part of the simulation exercise, we assume that the effects of the market imbalance caused by the invasion have had a heterogeneous impact on the economic sectors. Therefore, as a first approximation, we consider the food-production sector.

In this subsection our goal is to identify within the household and employment surveys those individuals who produce food or who otherwise perform tasks closely linked to the agricultural sector (whether they have agriculture as their main or secondary activity). To achieve this, we first identified all workers who are business owners or self-employed. Then, from this group, only those in the agricultural sector are identified. As a final result, we have a column that gives values equal to 1 to employers and self-employed who belong to the agricultural sector and 0 to the rest.

### Poverty lines 

In order to replicate the official poverty of each country, it is also necessary to use the official poverty thresholds. To define them, most countries use the concept of the basic food and non-food basket. On the one hand, the basic food basket establishes the minimum economic threshold to satisfy food needs based on the consumption habits of households in each country; if a family is below this threshold, it is defined as extreme poverty. On the other hand, the non-food basic basket adds non-food components to the basic basket; this threshold is used to identify the population living in poverty. 

It is important to mention that some countries such as Venezuela and Jamaica do not have official national poverty lines; other countries such as Brazil, Suriname and Barbados have used as official the international lines of US\\$1.9 and US\\$5. 

For these two cases in this project we use the international lines, to make the lines comparable with the national income of the year of the survey they are adjusted and deflated with the Consumer Price Index (CPI) and the Purchasing Power Parity - PPP. 

Equation (*) is used to calculate the countries' monthly international poverty lines per person. In this line, PPP data are from the World Bank's World Development Indicators (WDI), and CPI data are from the International Monetary Fund's (IMF) World Economic Outlook (WEO) database. More details 

$$
    lp_{ci}=(lp∗\frac{365}{12})∗[PPP_{2011} ∗ \frac{PCI_{year_{i}}}{PCI_{2011}}]
$$


### Household Food Basket Composition

In order to focus the price increase on specific commodities we consider the relative weight of each component on the basic food basket. 

In CEPAL's methology the products are initially classified into 14 categories: 1. Grains; 2. Breads and cereals; 3. Legumes; 4. Vegetables (greens or vegetables); 5. Roots and tubers; 6. Fruits; 7. Sugars; 8. Fats and oils; 9. Milk and dairy products; 10; 10. Meat, poultry, fish, seafood and eggs; 11; 11. Non-alcoholic beverages; 12. Alcoholic beverages; 13. Food products not previously specified; 14. Meals and beverages outside the home


### Poverty lines adjustment

In this phase of the project, the simulation works by adjusting the proportion of the poverty line that is composed of the commodities in each country that were affected by the price spike.


$$
povertyline\Delta_{country_i} =  povertyline_{country_i} * (1 - \omega_{country_i} ) + \\
                                 povertyline_{country_i} * \omega_{country_i} * (1 + shock\_weight)
$$




#### Simulation Components 

- The user can choose which components will be affected by the exogenous shock 

```python
shock_component = ['Alimentos fuera del hogar',
               'Azúcares', 'Bebidas no alcohólicas',
               'Carnes, aves y huevos',
               'Frutas', 
               'Granos', 'Panes y\ncereales',
               'Grasas', 'Leguminosas',
               'Lácteos', 
               'Productos no especificados previamente', 'Raíces y\ntubérculos', 'Vegetales'
              ]
```

- The User can choose the pct change of exogenous shock

```python
shock_weight = 0.20
```

- And specify whether the impact is focused on a subgroup of the population or if its a general impact

```python
shock_population = {'sec_agri': 0}
# In this example self-employed or independent workers in the agricultural sector will not be impacted by the Shock
```

##  Pending tasks and next steps

- We currently assume that increases in international prices are fully passed through to observed household prices.
- A substitution effect should be included among the products consumed by a households.
- changes in income caused by changes in food prices through agricultural wages. 
- Spending can be directly impacted by analyzing the percentage consumption of each commodity in the household instead of simulating impacts to the poverty line.

These assumptions may overestimate the effect of food price increases where most households consume diverse food baskets.

## [References](references) 

- Schmidt, E, Dorosh, P, & Gilbert, R. Impacts of COVID-19 induced income and rice price shocks on household welfare in Papua New Guinea: Household model estimates. Agricultural Economics. 2021; 52: 391– 406. https://doi.org/10.1111/agec.12625
- Artuc, Erhan; Porto, Guido; Rijkers, Bob. 2019. Household Impacts of Tariffs : Data and Results from Agricultural Trade Protection. Policy Research Working Paper;No. 9045. World Bank, Washington, DC. © World Bank. https://openknowledge.worldbank.org/handle/10986/33015 License: CC BY 3.0 IGO.”


## Annex

#### <center>Table 1</center>


| Country 	| year 	|                                             Survey                                            	| National poverty lines 	| Official   income/consumption  	|  Income/Consumption 	|
|:-------:	|:----:	|:---------------------------------------------------------------------------------------------:	|:----------------------:	|:------------------------------:	|:-------------------:	|
|   ARG   	| 2020 	| Permanent Continuous Household Survey (EPHC acronym in Spanish)                               	|           Yes          	|               Yes              	|    Monthly income   	|
|   BHS   	| 2014 	| Labor Force & Household Survey                                                                	|           No           	|               No               	|    Monthly income   	|
|   BLZ   	| 2007 	| Labor Force & Household Survey                                                                	|           No           	|               No               	|    Monthly income   	|
|   BOL   	| 2020 	| Household Survey (ECH, acronym in Spanish)                                                    	|           Yes          	|               Yes              	|    Monthly income   	|
|   BRA   	| 2020 	| Brazilian National Household Sample Survey (PNADC, acronym in Potuguese)                      	|           Yes          	|               No               	|    Monthly income   	|
|   BRB   	| 2016 	| Labor Force & Household Survey                                                                	|           Yes          	|               No               	| Monthly consumption 	|
|   CHL   	| 2020 	| National Socioeconomic Characterization Survey (CASEN, acronym in   Spanish)                  	|           Yes          	|               Yes              	|    Monthly income   	|
|   COL   	| 2020 	| Large Integrated Household Survey (GEIH, acronym in Spanish)                                  	|           Yes          	|               Yes              	|    Monthly income   	|
|   CRI   	| 2021 	| National Household Survey (ENAHO, acronym in Spanish)                                         	|           Yes          	|               Yes              	|    Monthly income   	|
|   DOM   	| 2020 	| Continuous National Labor Force Survey (ENCFT, acronym in Spanish)                            	|           Yes          	|               Yes              	|    Monthly income   	|
|   ECU   	| 2020 	| National Survey on Employment Unemployment and Underemployment (ENEMDU,   acronym in Spanish) 	|           Yes          	|               Yes              	|    Monthly income   	|
|   GTM   	| 2014 	| National Survey of Living Conditions (ENCOVI, acronym in Spanish)                             	|           Yes          	|               Yes              	|  Annual expenditure 	|
|   GUY   	| 2019 	| Labour Force Surveys (LFS)                                                                    	|           No           	|               No               	|    Monthly income   	|
|   HND   	| 2019 	| Permanent Multipurpose Household Survey (EPHPM, acronym in Spanish)                           	|           Yes          	|               Yes              	|    Monthly income   	|
|   JAM   	| 2018 	| Survey of Living Conditions (SLC)                                                             	|           Yes          	|               Yes              	|    Monthly income   	|
|   MEX   	| 2020 	| National Household Income and Expenditure Survey (ENIGH, acronym in   Spanish)                	|           Yes          	|               Yes              	|    Monthly income   	|
|   NIC   	| 2014 	| Living Standard Measurement Survey (EMNV, acronym in Spanish)                                 	|           Yes          	|               Yes              	| Monthly consumption 	|
|   PAN   	| 2019 	| Multipurpose Survey (EHPM, acronym in Spanish)                                                	|           Yes          	|               No               	|    Monthly income   	|
|   PER   	| 2020 	| National Household Survey (ENAHO, acronym in Spanish)                                         	|           Yes          	|               Yes              	| Monthly consumption 	|
|   PRY   	| 2020 	| Permanent Continuous Household Survey (EPHC acronym in Spanish)                               	|           Yes          	|               Yes              	|    Monthly income   	|
|   SLV   	| 2020 	| Multipurpose Household Survey (EHPM, acronym in Spanish)                                      	|           Yes          	|               Yes              	|    Monthly income   	|
|   SUR   	| 2017 	| Survey of Living Conditions (SLC)                                                             	|           No           	|               No               	| Monthly consumption 	|
|   TTO   	| 2015 	| Continuous Sample Survey of Population (CSSP)                                                 	|           No           	|               Yes              	|    Monthly income   	|
|   URY   	| 2020 	| Continuous Household Survey (ECH, acronym in Spanish)                                         	|           Yes          	|               Yes              	|    Monthly income   	|
|   VEN   	| 2021 	| National Survey of Living Conditions (ENCOVI, acronym in   Spanish)                           	|           No           	|               No               	|    Monthly income   	|