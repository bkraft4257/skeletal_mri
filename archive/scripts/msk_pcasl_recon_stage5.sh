#!/bin/bash

#
#
#

sed -n '1~4p' cl.index > mbf.index

m0=$(echo $(fslstats n4.m0.nii.gz -k mask.n4.m0.nii.gz -M) )

gunzip n4.cl.nii.gz

/aging1/software/matlab/bin/matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_pwi('n4.cl.nii'); mskPcasl_mbf('blood.nii', $m0);  mskPcasl_tissue('tissue.nii'); mskPcasl_slice_mean( 'norm_m0.tissue.nii', 'slice_mean.norm_m0.tissue.nii'); exit"
gzip -f *.nii


#
#
#

cd mcf

sed -n '1~4p' cl.index > mbf.index

m0=$(echo $(fslstats n4.m0.nii.gz -k mask.n4.m0.nii.gz -M) )

gunzip mcf.n4.cl.nii.gz
/aging1/software/matlab/bin/matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_pwi('mcf.n4.cl.nii'); mskPcasl_mbf('blood.nii', $m0); mskPcasl_tissue('tissue.nii'); mskPcasl_slice_mean( 'norm_m0.tissue.nii', 'slice_mean.norm_m0.tissue.nii'); exit"
gzip -f *.nii

#gunzip mcf.n4.cl.nii.gz
#matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_pwi('mcf.n4.cl.nii'); mskPcasl_mbf('blood.nii', $m0);  exit"
#gzip -f *.nii

