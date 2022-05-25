#!/usr/bin/env python3
#!pip install openpyxl
# conda install pandoc
# conda install nvconvert
# sudo yum install texlive-*

import matplotlib.pyplot as plt
import seaborn as sns
#sns.set_theme()

import numpy as np
import pandas as pd
from dotenv import load_dotenv

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import matplotlib.pyplot as plt
import numpy as np

scldatalake = "s3://cf-p-scldata-prod-s3-p-scldata-app"

fig=plt.figure(figsize=(12,8), dpi= 100, facecolor='w', edgecolor='k')
pd.set_option('display.float_format', lambda x: '%.3f' % x)

load_dotenv()
 
    
class SCLdataSimulation():    
    """
    """
    
    
    def __init__(self):
        """
        """        
        self.scldatalake = scldatalake
        self.harmonized = self.get_harmonized()
    
    def get_gdp_growth(self, year):
        gdp_change = (pd.read_csv(scldatalake + '/International Organizations/IMF World Economic Outlook Database/clean/Real GDP_change_IMF.csv')
                      .rename(columns={'ISO':'pais_c', year: 'gdp_change'}))
        gdp_change = gdp_change[['pais_c', 'gdp_change']]
        gdp_change['gdp_change'] = gdp_change['gdp_change']/100
        
        return gdp_change
        
    def get_poverty_lines(self, shock_component):
        """
        """       
        povertyline = "Data Projects/International Poverty Lines/international_poverty_lines.csv"
        pl          = pd.read_csv(f'{self.scldatalake}/{povertyline}')

        # Reshape long to wide 
        index = ['year','isoalpha3']
        pl = pl.pivot_table(index = index, columns = 'indicator', values = 'value').reset_index()
        pl = pl.reset_index()
        pl = pl.drop(columns = ['ppp_wdi2011','tc_wdi'])
        pl = pl.rename(columns = {'isoalpha3':'code'})
        
        # CPI 2011 = 100
        pl['cpi_2011' ] = [pl[(pl.code == x) & (pl.year == 2011)].cpi.item() for x in pl.code]

        # Rename variables for merge 
        pl.rename(columns = {'code':'pais_c', 'year':'anio_c'}, inplace = True)

        # Get weights
        weights = pd.read_excel(f'{scldatalake}/Data Projects/Official National Poverty Lines/cba-weights.xlsx',
                                engine='openpyxl')
        weights = (weights.groupby(['pais_c', 'category'])['year'].max()
                   .reset_index().merge(weights, on=['pais_c', 'category', 'year'], how='left'))
        weights = (weights[weights.category.isin(shock_component)]
                   .groupby(['pais_c']).agg({'weight': 'sum'}).reset_index())
        weights['weight'] = weights['weight']/100 
        pl = pl.merge(weights, on='pais_c')
        pl['weight'].fillna(int(pl['weight'].mean()), inplace=True)
        
        return pl
    
    def get_harmonized(self):
        """
        """
        
        # Harmonized data
        harmonized  = "Household Socio-Economic Surveys/Harmonized Household Surveys"
        # Import data 
        hh = pd.read_csv(f'{self.scldatalake}/{harmonized}/concat/harmonized-latest-v3.csv')
        hh.columns = [i.strip() for i in hh.columns]

        # Principal activities
        hh['sec_agri']   = np.where(((hh['categopri_ci'] == 1) | (hh['categopri_ci'] == 2)) &  # cuenta propia o independientes
                                    ((hh['rama_ci'] == 1) | (hh['ramasec_ci'] == 1)), # trabajo en sector agrícola
                                     1, 0)
        
        hh['sec_transp'] = np.where(((hh['categopri_ci'] == 1) | (hh['categopri_ci'] == 2)) & 
                                    ((hh['rama_ci'] == 7) | (hh['ramasec_ci'] == 7)),
                                    1, 0)
        return hh
        
    def simulate_shock(self, shock_component, shock_weight, shock_population, gdp_growth_population, year='2022'): 
        """
        """

        data_ = self.get_poverty_lines(shock_component)
        tasas = self.harmonized.copy()
        growth = self.get_gdp_growth(year=year)

        ####################
        # International
        ####################

        # Changes in CPI
        data_['cpi_hat'] = data_.cpi * (1 - data_.weight) + data_.cpi * data_.weight * (1 + shock_weight) 

        # CPI 2011 = 100
        data_['cpi_ratio'] = data_.cpi_hat / data_.cpi_2011

        ## Original International
        data_['lp19_2011'] = (1.9*(365/12)) * data_.cpi_ratio * data_.ppp_2011
        data_['lp31_ci'] = (3.1*(365/12)) * data_.cpi_ratio * data_.ppp_2011
        data_['lp5_ci'] = (5.0*(365/12)) * data_.cpi_ratio * data_.ppp_2011

        ## Delta International 
        data_['lp19_2011_delta'] = ((1.9*(365/12)) * (data_.cpi / data_.cpi_2011) * data_.ppp_2011) * (1 + shock_weight)
        data_['lp31_ci_delta'] = ((3.1*(365/12)) * (data_.cpi / data_.cpi_2011) * data_.ppp_2011) * (1 + shock_weight)
        data_['lp5_ci_delta'] = ((5.0*(365/12)) * (data_.cpi / data_.cpi_2011) * data_.ppp_2011) * (1 + shock_weight)


        # Identify poverty lines vars
        lp_vars = [name for name in data_.columns if 'lp' in name]
        
        # Adjust for changes in Venezuelan currency
        for name in lp_vars:
            data_.loc[data_.pais_c == 'VEN',name] = data_.loc[data_.pais_c == 'VEN',name] / 100000000

        data_ = data_[['pais_c','anio_c','weight','lp5_ci', 'lp5_ci_delta', 'lp31_ci', 'lp31_ci_delta']]

        tasas = tasas.drop(['lp5_ci', 'lp31_ci'], axis=1).merge(data_, on = ['pais_c', 'anio_c'], how = 'left')
        
        
        ####################
        # National
        ####################
        # Note: lpe_ci is the food basket line. The non-food part would not be affected by the exogenous shock.
        tasas['lp_ci_no_alim'] = tasas['lp_ci'] - tasas['lpe_ci'] 
        # Impacts - direct shock
        tasas['lpe_ci_delta'] = tasas['lpe_ci'] * (1 - tasas['weight']) + tasas['lpe_ci'] * tasas['weight'] * (1 + shock_weight)  
        # Impacts - only to food basket
        tasas['lp_ci_delta'] = tasas['lp_ci_no_alim'] + tasas['lpe_ci'] * (1 - tasas['weight']) + tasas['lpe_ci'] * tasas['weight'] * (1 + shock_weight) 
        
        # The difference is the same in the two thresholds
        tasas['lp_ci_diff'] = tasas['lp_ci_delta'] - tasas['lp_ci']
        
        ####################
        # Shock Targeting
        ####################
        tasas = tasas.assign(
                            # National
                            lpe_ci_delta = np.where(tasas[shock_population.keys()].isin(shock_population.values()).all(axis=1),
                                                      tasas['lpe_ci_delta'], tasas['lpe_ci']),
                            lp_ci_delta = np.where(tasas[shock_population.keys()].isin(shock_population.values()).all(axis=1),
                                                      tasas['lp_ci_delta'],tasas['lp_ci']),
                            # International
                            lp31_ci_delta = np.where(tasas[shock_population.keys()].isin(shock_population.values()).all(axis=1),
                                                      tasas['lp31_ci_delta'], tasas['lp31_ci']),
                            lp5_ci_delta = np.where(tasas[shock_population.keys()].isin(shock_population.values()).all(axis=1),
                                                      tasas['lp5_ci_delta'],tasas['lp5_ci']))
        
        ####################
        # Growth Targeting
        ####################
        tasas = tasas.merge(growth, on='pais_c', how='left')
        tasas = tasas.assign(# Internation
                             pc_ytot_ch_ofi_delta = tasas['pc_ytot_ch_ofi'] * (1 + tasas['gdp_change']),
                             # National
                             ytot_ci_delta =tasas['ytot_ci'] * (1 + tasas['gdp_change']))
        
        ####################
        # Recreate poverty - national and int
        ####################
        tasas = (tasas.assign(
                             # International
                             poor_int= np.where(tasas['ytot_ci'] <tasas['lp5_ci'],1,
                                                np.where((tasas['ytot_ci'] >= tasas['lp5_ci']) & 
                                                      (~tasas['ytot_ci'].isna()), 0, None)),
                             poor31_int= np.where((tasas['ytot_ci'] <tasas['lp31_ci']),1,
                                              np.where((tasas['ytot_ci']>=tasas['lp31_ci']) &  
                                                       (~tasas['ytot_ci'].isna()), 0,None)),
                             poor_int_delta= np.where(tasas['ytot_ci_delta'] <tasas['lp5_ci_delta'],1,
                                                  np.where((tasas['ytot_ci_delta']>=tasas['lp5_ci_delta']) & 
                                                           (~tasas['ytot_ci_delta'].isna()), 0, None)),
                             poor31_int_delta= np.where((tasas['ytot_ci_delta'] <tasas['lp31_ci_delta']),1,
                                            np.where((tasas['ytot_ci_delta']>=tasas['lp31_ci_delta']) &  
                                                     (~tasas['ytot_ci_delta'].isna()), 0,None)),
                             # National
                             poor_national= np.where((tasas['pc_ytot_ch_ofi'] <tasas['lp_ci']),1,
                                            np.where((tasas['pc_ytot_ch_ofi']>=tasas['lp_ci']) &  
                                                     (~tasas['pc_ytot_ch_ofi'].isna()), 0,None)),           
                             poor_e_national = np.where((tasas['pc_ytot_ch_ofi'] < tasas['lpe_ci']),1,
                                            np.where((tasas['pc_ytot_ch_ofi']>=tasas['lpe_ci']) & 
                                                     ~(tasas['pc_ytot_ch_ofi'].isna()), 0,None)), 

                             poor_national_delta= np.where((tasas['pc_ytot_ch_ofi_delta'] <tasas['lp_ci_delta']),1,
                                            np.where((tasas['pc_ytot_ch_ofi_delta']>=tasas['lp_ci_delta']) &  
                                                     (~tasas['pc_ytot_ch_ofi_delta'].isna()), 0,None)),           
                             poor_e_national_delta = np.where((tasas['pc_ytot_ch_ofi_delta'] < tasas['lpe_ci_delta']),1,
                                            np.where((tasas['pc_ytot_ch_ofi_delta']>=tasas['lpe_ci_delta']) & 
                                                     ~(tasas['pc_ytot_ch_ofi_delta'].isna()), 0,None))))
        tasas = (tasas
                 # poor as a result of the change
                 .assign(poor_national_new = np.where((tasas['poor_national']==0) & (tasas['poor_national_delta']==1),1,
                                            np.where((~tasas['poor_national'].isna()), 0,None)),
                         poor_e_national_new = np.where((tasas['poor_e_national']==0) & (tasas['poor_e_national_delta']==1),1,
                                            np.where((~tasas['poor_e_national'].isna()), 0,None))))
        
        return tasas
    
    def simulate_changes(self, shock_component, shock_weights, shock_population, gdp_growth_population, year='2022'): 
        """
        """
        simulations = []
        for shock_weight in shock_weights:
            change = self.simulate_shock(shock_component=shock_component,
                                         shock_weight=shock_weight,
                                         shock_population=shock_population,
                                         gdp_growth_population=gdp_growth_population,
                                         year=year)
            country_group = self.country_results(change)
            country_group['shock_weight'] = shock_weight
            simulations.append(country_group)
        simulations_concat = pd.concat(simulations)

        return simulations_concat 
    
    def simulate_changes_region(self, shock_component, shock_weights, shock_population, gdp_growth_population, year='2022'): 
        """
        """
        simulations = []
        for shock_weight in shock_weights:
            change = self.simulate_shock(shock_component=shock_component,
                                         shock_weight=shock_weight,
                                         shock_population=shock_population,
                                         gdp_growth_population=gdp_growth_population,
                                         year=year)
            country_group = self.region_results(change)
            country_group['shock_weight'] = shock_weight
            simulations.append(country_group)
        simulations_concat = pd.concat(simulations)

        return simulations_concat     

    def region_results(self, tasas):
        """
        """
        tasas['pais_c'] = 'LAC'
        out = (tasas.assign(population_int = np.where(~(tasas['poor_int'].isna()),tasas.factor_ch, None),
                                    population_nat = np.where(~(tasas['poor_national'].isna()),tasas.factor_ch, None),
                                    poor_int_pop = (tasas["factor_ch"] * tasas['poor_int']),
                                    poor_int_delta_pop = (tasas["factor_ch"] * tasas['poor_int_delta']),
                                    poor31_int_pop = (tasas["factor_ch"] * tasas['poor31_int']),
                                    poor31_int_delta_pop = (tasas["factor_ch"] * tasas['poor31_int_delta']),
                                    poor_national_pop = (tasas["factor_ch"] * tasas['poor_national']),
                                    poor_national_delta_pop = (tasas["factor_ch"] * tasas['poor_national_delta']),
                                    poor_e_national_pop =  (tasas["factor_ch"] * tasas['poor_e_national']),
                                    poor_e_national_delta_pop =  (tasas["factor_ch"] * tasas['poor_e_national_delta']),
                                    # resources needed to mitigate the effect ( factor[I = 0,1] * diff )
                                    poor_national_new_recovery = (tasas['poor_national_new'] * tasas['factor_ch'] * tasas['lp_ci_diff']/tasas['tc_c'] ),
                                    poor_e_national_new_recovery = (tasas['poor_e_national_new'] * tasas['factor_ch'] * tasas['lp_ci_diff']/tasas['tc_c']))
                 .groupby(['pais_c'])
                       .agg({'factor_ch':sum,
                             'population_int':sum,
                             'population_nat':sum,
                             'poor_int_pop':sum,
                             'poor_int_delta_pop':sum,
                             'poor31_int_pop':sum,
                             'poor31_int_delta_pop':sum,
                             'poor_national_pop':sum,
                             'poor_national_delta_pop':sum,
                             'poor_e_national_pop':sum,
                             'poor_e_national_delta_pop':sum,
                             'poor_national_new_recovery':sum,
                             'poor_e_national_new_recovery':sum,                     
                            })).reset_index().rename(columns={'factor_ch':'population'})
        out = (out.assign(poor_int = (out["poor_int_pop"] / out['population_int']),
                          poor_int_delta = (out["poor_int_delta_pop"] / out['population_int']),
                          poor31_int = (out["poor31_int_pop"] / out['population_int']),
                          poor31_int_delta = (out["poor31_int_delta_pop"] / out['population_int']),
                          poor_national = (out["poor_national_pop"] / out['population_nat']),
                          poor_national_delta = (out["poor_national_delta_pop"] / out['population_nat']),                  
                          poor_e_national = (out["poor_e_national_pop"] / out['population_nat']),
                          poor_e_national_delta = (out["poor_e_national_delta_pop"] / out['population_nat'])
                         ).drop(['population_int', 'population_nat'], axis=1))
        
        return out
    
    def country_results(self, tasas):
        """
        """
       
        out = (tasas.assign(population_int = np.where(~(tasas['poor_int'].isna()),tasas.factor_ch, None),
                            population_nat = np.where(~(tasas['poor_national'].isna()),tasas.factor_ch, None),
                            poor_int_pop = (tasas["factor_ch"] * tasas['poor_int']),
                            poor_int_delta_pop = (tasas["factor_ch"] * tasas['poor_int_delta']),
                            poor31_int_pop = (tasas["factor_ch"] * tasas['poor31_int']),
                            poor31_int_delta_pop = (tasas["factor_ch"] * tasas['poor31_int_delta']),
                            poor_national_pop = (tasas["factor_ch"] * tasas['poor_national']),
                            poor_national_delta_pop = (tasas["factor_ch"] * tasas['poor_national_delta']),
                            poor_e_national_pop =  (tasas["factor_ch"] * tasas['poor_e_national']),
                            poor_e_national_delta_pop =  (tasas["factor_ch"] * tasas['poor_e_national_delta']),
                            # resources needed to mitigate the effect ( factor[I = 0,1] * diff )
                            poor_national_new_recovery = (tasas['poor_national_new'] * tasas['factor_ch'] * tasas['lp_ci_diff']/tasas['tc_c'] ),
                            poor_e_national_new_recovery = (tasas['poor_e_national_new'] * tasas['factor_ch'] * tasas['lp_ci_diff']/tasas['tc_c']))
               .groupby(['anio_c', 'pais_c'])
               .agg({'factor_ch':sum,
                     'population_int':sum,
                     'population_nat':sum,
                     'poor_int_pop':sum,
                     'poor_int_delta_pop':sum,
                     'poor31_int_pop':sum,
                     'poor31_int_delta_pop':sum,
                     'poor_national_pop':sum,
                     'poor_national_delta_pop':sum,
                     'poor_e_national_pop':sum,
                     'poor_e_national_delta_pop':sum,
                     'poor_national_new_recovery':sum,
                     'poor_e_national_new_recovery':sum,                     
                    })).reset_index().rename(columns={'factor_ch':'population'})

        out = (out.assign(poor_int = (out["poor_int_pop"] / out['population_int']),
                          poor_int_delta = (out["poor_int_delta_pop"] / out['population_int']),
                          poor31_int = (out["poor31_int_pop"] / out['population_int']),
                          poor31_int_delta = (out["poor31_int_delta_pop"] / out['population_int']),
                          poor_national = (out["poor_national_pop"] / out['population_nat']),
                          poor_national_delta = (out["poor_national_delta_pop"] / out['population_nat']),                  
                          poor_e_national = (out["poor_e_national_pop"] / out['population_nat']),
                          poor_e_national_delta = (out["poor_e_national_delta_pop"] / out['population_nat'])
                         ).drop(['population_int', 'population_nat'], axis=1))
        
        return out.sort_values('pais_c')
    
    def population_segmentation_results(self, tasas, categories=['pais_c']):
        """
        """    
        #categories = ['anio_c', 'pais_c', 'sexo_ci']
        #categories.extend(categories)

        out = (tasas.assign(population_int = np.where(~(tasas['poor_int'].isna()),tasas.factor_ch,None),
                            population_nat = np.where(~(tasas['poor_national'].isna()),tasas.factor_ch,None),
                            poor_int_pop = (tasas["factor_ch"] * tasas['poor_int']),
                            poor_int_delta_pop = (tasas["factor_ch"] * tasas['poor_int_delta']),
                            poor31_int_pop = (tasas["factor_ch"] * tasas['poor31_int']),
                            poor31_int_delta_pop = (tasas["factor_ch"] * tasas['poor31_int_delta']),                    
                            poor_national_pop = (tasas["factor_ch"] * tasas['poor_national']),
                            poor_national_delta_pop = (tasas["factor_ch"] * tasas['poor_national_delta']),
                            poor_e_national_pop =  (tasas["factor_ch"] * tasas['poor_e_national']),
                            poor_e_national_delta_pop =  (tasas["factor_ch"] * tasas['poor_e_national_delta'])
                           )
                .groupby(categories)
                 .agg({'poor_int_pop':sum,
                       'poor_int_delta_pop':sum,
                       'poor31_int_pop':sum,
                       'poor31_int_delta_pop':sum,
                       'poor_national_pop':sum,
                       'poor_national_delta_pop':sum,
                       'poor_e_national_pop':sum,
                       'poor_e_national_delta_pop':sum,
                       'factor_ch':sum,
                       'population_int':sum,
                       'population_nat':sum})).reset_index().rename(columns={'factor_ch':'population'})

        out = (out.assign(poor_int = (out["poor_int_pop"] / out['population_int']),
                          poor_int_delta = (out["poor_int_delta_pop"] / out['population_int']),
                          poor31_int = (out["poor31_int_pop"] / out['population_int']),
                          poor31_int_delta = (out["poor31_int_delta_pop"] / out['population_int']),
                          poor_national = (out["poor_national_pop"] / out['population_nat']),
                          poor_national_delta = (out["poor_national_delta_pop"] / out['population_nat']),                  
                          poor_e_national = (out["poor_e_national_pop"] / out['population_nat']),
                          poor_e_national_delta = (out["poor_e_national_delta_pop"] / out['population_nat'])
                         ).drop(['population_int', 'population_nat'], axis=1))        
        
        return out
    
    def plot_group(self,change, group):
        """
        """
        group_delta = self.population_segmentation_results(tasas=change, categories= group)
        fig=plt.figure(figsize=(30,8), dpi= 100, facecolor='w', edgecolor='k')

        variables = ['poor_national', 'poor_e_national']
        for variable in variables:
            group_delta[variable +'_diff'] = (group_delta[variable + '_delta'] - group_delta[variable])*100  
        variables = [x + '_diff' for x in variables]
        variables.extend(group)
        group_melt = pd.melt(group_delta[variables],
                             id_vars=group,
                             var_name='metrics', value_name='values')

        color_labels = group_melt[group[-1]].unique()
        rgb_values = sns.color_palette("Set2", len(color_labels))
        color_map = dict(zip(color_labels, rgb_values))

        fig=plt.figure(figsize=(30,8), dpi= 100, facecolor='w', edgecolor='k')
        plt.figure(figsize = (22,5))
        for i,variable in enumerate(['poor_national_diff', 'poor_e_national_diff']):
            ordered_df = group_melt[group_melt.metrics==variable]
            ordered_df = ordered_df.sort_values(by=[ 'values'], ascending=False)
            plt.subplot(1,3,i+1)
            my_range=range(1,len(ordered_df.index)+1)
            plt.hlines(y=my_range, xmin=0,
                       xmax=ordered_df['values'],
                       color=ordered_df[group[-1]].map(color_map),
                       alpha=0.4)
            plt.scatter(ordered_df['values'], my_range ,c=ordered_df[group[-1]].map(color_map),  alpha=1) 
            #plt.yticks(my_range, ordered_df['pais_c'])
            plt.title("Percentage points change in {0}".format(variable), loc='left')
            plt.xlabel('Change')
            plt.ylabel(group[-1])
            plt.yticks(rotation = 45)
        return plt.show()
    
    
    

