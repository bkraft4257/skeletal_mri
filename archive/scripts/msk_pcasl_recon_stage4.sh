#!/bin/bash

#
# Motion Alignment
#

mcflirt -in n4.cl.nii.gz -out mcf.n4.cl  -reffile n4.m0.nii.gz -plots -report
cat mcf.n4.cl.par | tr -s " " "," > mcf.n4.cl.csv
gnuplot $MSK_SCRIPTS/msk_recon_pcasl_parplot.sh


