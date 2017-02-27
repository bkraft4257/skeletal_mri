#!/usr/bin/env python

# 4 ../nifti_calf nii pasl_raw_0.nii.gz
# 8 ../nifti_calf nii pasl_raw_1.nii.gz
#12 ../nifti_calf nii pasl_raw_2.nii.gz
#16 ../nifti_calf nii pasl_raw_3.nii.gz


import pandas

df = pandas.read_csv('dcmConvert_priorities.cfg', delim_whitespace=True, names=['series', 'dir','type','filename'] )


df_raw = df[df['filename'].str.contains("pasl_raw")].reindex()
df_raw.loc[:,'filename'] = df_raw.loc[:,'filename'].str.replace('pasl_raw', 'pasl_moco')

df_raw.loc[:,'series'] = df_raw.loc[:,'series'] + 1


print(df_raw)


df_raw.to_csv('dcmConvert_pasl_moco.cfg', sep=' ', header=False, index=False)
