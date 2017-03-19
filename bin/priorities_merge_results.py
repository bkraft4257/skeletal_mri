#!/usr/bin/env python

import  pandas 
import  os
import  re


#$Id: FreeSurferColorLUT.txt,v 1.70.2.7 2012/08/27 17:20:08 nicks Exp $

#No. Label Name:                            R   G   B   A
# 1  Gastroc_medial                     255    0    0   1
# 2  Gastroc_lateral                   0  255    0   1
# 3  Soleus                    255  255    0   1
# 4  Peroneus                    0  255  255   1
# 5  Tibialis_anterior         255    0  255   1
# 8  Extensor_digitorum_longus         255  170    0   1

keep_labels = [1,2,3,4,5,8]

results_dir = os.getcwd()

pattern    = re.compile('pri[0-9][0-9]_[a-z][a-z][a-z][a-z][a-z]/[0-9]')
match      = re.findall(pattern, results_dir)[0]
visit      = match[-1]
subject_id = match[0:-2]

#print(visit)
#print(subject_id)

mbf       = '_methods_cummean.mbf.csv'
mbf_abs   = '_methods_cummean.abs.mbf.csv'
pc_ghosts = '_methods_phase_ghosts.abs.pwi.csv'

df_results = pandas.DataFrame()
 
usecols          = ['label', 'time', 'mean', 'std', 'min', 'max' ]
rename_columns   = ['label', 'average', 'mean', 'std', 'min', 'max', 'type', 'visit', 'exercise_time' ]

for ii in  [0,1,2,3]:

    df_mbf          = pandas.read_csv( str(ii) + mbf, usecols=usecols)
    df_mbf['type']  = 'mbf'
    df_mbf['visit'] = visit
    df_mbf['exercise_time'] = ii

    df_mbf_abs          = pandas.read_csv( str(ii) + mbf_abs, usecols=usecols)
    df_mbf_abs['type']  = 'abs.mbf'
    df_mbf_abs['visit'] = visit
    df_mbf_abs['exercise_time']  = ii

    df_ghosts = pandas.read_csv( str(ii) + pc_ghosts)

    df_concat =  pandas.concat([df_mbf, df_mbf_abs], axis=0, ignore_index=True)
    df_concat.columns = rename_columns

    df_merge = df_concat.merge(df_ghosts, left_on='average', right_on='time', how='inner')

    df_results = df_results.append( df_merge ) 

df_results['subject_id'] = subject_id
df_results['visit']      = visit
#print(df_results.columns.values)
df_results = df_results.drop(['time', '100.0', '200.0', '300.0'], axis=1)


df_results = df_results[[ 'subject_id', 'type', 'label', 'visit', 'exercise_time', 'average', 'mean', 'std', 'min', 'max',
                 'phase/freq',  'phase/background',  'freq/background' ]]

df_results = df_results.sort_values( ['subject_id', 'type', 'label', 'visit', 'exercise_time', 'average'])
df_results = df_results.reset_index(drop=True)

df_results.loc[:,'label'] = df_results.loc[:,'label'].astype(int)
df_results = df_results[ (df_results['label'] <=5) | (df_results['label'] == 8) ]

#print(df_results['label'].unique())

df_results.to_csv('results.csv', float_format='%.2f')
#print(df_results)


#
#
#

