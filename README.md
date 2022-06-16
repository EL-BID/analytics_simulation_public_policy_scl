![IDB Logo](app/assets/iadb.png)


**SCL Data - Data Ecosystem Working Group**


# Rising Food Prices and Poverty in Latin America and the Caribbean:


### Description and Context
This repository contains the code of the [policy simulator tool](https://bid-data.shinyapps.io/scl_policy_simulation/). 


[pdf](https://bid-data.shinyapps.io/scl_policy_simulation/_w_809fa080/session/6100830d32a20ec2001f8316ea242076/download/pdf?w=809fa080)



### Installation Guide
---




---


### Summary

Rapid increases in food prices raise concerns about the potential impact on people's lives, especially on the poverty levels and welfare of the most vulnerable. Understanding the impact of exogenous shocks, their location, and the characteristics of the most affected population, is fundamental for the design and implementation of policy responses to mitigate their effects. 

Previous periods of increases in food prices have resulted in large increases in extreme poverty.  Between 2006 and 2008, the price of rice increased by 217 percent, wheat by 136 percent, and maize by 125 percent, among others (ALNAP, 2008. As a result, it is estimated that an extra 155 million people were pushed into extreme poverty worldwide (de Hoyos, R.E. and Medvedev, D., 2011). It is estimated that in Latin America and the Caribbean poverty increased in this period by 4.3 percentage points of 21 million people (United Nations, 2011).

The current conflict between Russia and Ukraine combined with other factors such as increased demand from Asia is already affecting food and other commodity prices worldwide. Russia and Ukraine represent 28.5% of the world’s wheat exports , and Russia is currently the third oil producer in the world and the leading exporter of fertilizer . Therefore, the conflict between Russia and Ukraine is expected to continue to rise the food prices and affect vulnerable population, particularly households with low food basket substitution power. The most recent figures from the FAO food price index show an increase of around 20% from a year ago and an increase in the cereal price index of around 15% from a year ago. The FAO also warns of the risk of further increments of food prices from 8 to 22% (FAO, 2022). 
This policy brief presents a toolkit to simulate the impact of the increase in food prices caused by the Ukraine war on poverty levels for XX countries in Latin America and the Caribbean (LAC) over 2022. We simulate the impact of poverty levels by adjusting the national poverty lines according to the projection of price increases of key food items (grains, breads, cereals, and meats). This simulation also considers the revised growth projections of countries and accounts for the share of national producers of these essential food items. 

An increase of 20% in the prices of all food items except for meats , together with the revised growth projections of the IMF for LAC countries will result in an average increase in moderate poverty of 1.6 percentage points and a 1.8 percentage point increase in extreme poverty on average, resulting in 9.5 million additional poor in the region. Some countries will be more affected than others. This will depend on four key factors: (a) the composition of the poverty basket in each given country, (b) the income-distribution of household income pre-crisis, (c) the impact of the crisis on growth prospects and (d) the share of food producers in each country. In our simulations, the countries that will be more affected will be Guatemala, Mexico, and Nicaragua. 

Compensating the loss of purchasing power could be costly. A naive transfer large enough to compensate all families below the moderate poverty line to achieve pre-crisis income levels (and therefore, pre-crises moderate poverty levels) would cost 1.3 billion US$ monthly to the region (0.4% of GDP). 

## A tool to simulate the effects on poverty in LAC. The forces at play. 

The toolkit simulates the impact of the increase in food prices caused by the Ukraine war on poverty levels for 24 countries in Latin America and the Caribbean (LAC) over 2022.  Departing from the last available poverty level data in each country (see appendix for details), we adjust poverty lines to reflect the changes in prices, while simultaneously increasing household income in line with the revised GDP growth projections. To reflect the fact that some countries will benefit from the crisis because they are producers of the affected goods, we allow the simulation to shield these population from the increases in prices. Below a detail explanation of these channels. 

-	Changing poverty lines. We simulated the direct effect through the increase in food prices by increasing the poverty lines of the countries in the region. The adjustment is made by impacting each country's poverty line by the percentage that each commodity represents in the poverty line. For example, if there is an increment of 20% in the price of wheat and wheat represents 20% of the basket used to calculate the county's poverty line, the increment in the poverty line is of 4%.  
-	Impact of growth on poverty. We account for the aggregate impact of growth on poverty.   For this we used growth forecasts published by the IMF into the simulations (the latest version being the data for April of 2022). This channel will generate variation across countries, as the commodity shocks will impact countries differently depending on whether they are net commodity exporter and importers. The assumption for simulating GDP growth on poverty was that all incomes in the country grow at the same rate as GDP growth. While the  distribution of growth tends to vary depending on which years are being analyzed, the assumption seems to be backed by  World Bank measurements of growth distribution curves except for the bottom decile. For the bottom decile in the region growth has tended to be less beneficial than for the rest.
-	Share of producers in countries. Similarly, within countries we account for the fact that some households benefit from increases in prices by applying the same rate on increment that is applied to the poverty line to households that are involved in agricultural activities as self-employed or as employers. That is, we considered that there is no pass-through effect to employees in the sector. 

There are important caveats to be considered when interpreting the results of these simulations. We currently assume that increases in international prices are fully passed through to observed household prices. We do not consider substitution effects among the products consumed by a household for practical reasons since these in turn would trigger (likely) smaller increases in prices of substitute goods or hangs in income caused by changes in food prices through agricultural wages. We do not analyze consumption patterns at the micro level since most surveys used do not have detailed information on consumption.

This toolkit is designed to simulate several scenarios. Our baseline scenario considers an increase of 20% in the prices of all food items except for meat, in line with the most recent forecasts from the FAO (see annex), the April 2022 IMF growth projections and we assume that local producers are shielded from price increases. We allow for changes in the goods that are affected by prices inflation (all products, all but meat, grains bread and cereals and only grains) as well as the size of the shock, from 10% to 50% increase in prices. We also allow the user to turn off the impact of growth on poverty and whether producers are affected or not by the prices increases. By turning off these two channels our simulations reflect the direct impact of increases in prices on poverty lines. 

 

## Results

In our baseline scenario, moderate (extreme) poverty will increase by 1.6 (1.8) percentage points, increasing the number of people below moderate poverty line in 9.5 million. The effect of the simulation is larger on extreme poverty because the extreme poverty line is mostly made up of food prices so the increase will be larger compared to the moderate poverty line. The relatively small effect is due to the combination of the GDP growth effect and the effect of the increase in food prices which act in different directions. Among the countries that are expected to be hit the hardest are Guatemala, Nicaragua, Mexico, Ecuador, and Honduras, all of them with poverty rate increases of more than two percentage points in extreme poverty. A naive transfer large enough to compensate all poor households in a way that would help them be in a situation similar to that before the crisis would cost 1.3 billion US$ monthly to the region. (0.4% of GDP). This outlook is particularly worrisome after the efforts made by countries in the region to support households in the face of COVID-19. Efforts to help households cope with the Pandemic cost 3.5% of GDP in 2020 and the growth forecasts are expected to slow down from 6.2% in 2021 to 2.1% in 2022. 


A more extreme scenario in which inflation keeps going up and reaches 50% would be dramatic. It would mean that poverty rises by 7.6 percentage points and extreme poverty by 7.7 points. Adding a staggering 44 million people into (moderate) poverty and costing 4.5 billion monthly to compensate households (1.15% of regions GDP). 

The distribution of the effect in our baseline scenario by country can be seen in Figure 1 below. A more complete view of different inflation scenarios can also be seen in Figure A1 in the Annex. 

We invite you to run your own scenarios using the simulation tool developed by the IDB. 

https://bid-data.shinyapps.io/scl_policy_simulation/


### Limitation of responsibilities
---
The IDB is not responsible, under any circumstance, for damage or compensation, moral or patrimonial; direct or indirect; accessory or special; or by way of consequence, foreseen or unforeseen, that could arise:

I. Under any concept of intellectual property, negligence or detriment of another part theory; I
ii. Following the use of the Digital Tool, including, but not limited to defects in the Digital Tool, or the loss or inaccuracy of data of any kind. The foregoing includes expenses or damages associated with communication failures and / or malfunctions of computers, linked to the use of the Digital Tool.
