#!/bin/bash

sed -n '1~4p' cl.index > mbf.index

m0=$(echo $(fslstats n4.m0.nii.gz -k mask.n4.m0.nii.gz -M) ); echo $m0

gunzip n4.cl.nii.gz
matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_pwi('mcf.n4.cl.nii'); mskPcasl_mbf('blood.nii', $m0);  exit"
gzip *.nii
