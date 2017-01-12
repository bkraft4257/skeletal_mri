#!/bin/bash

gunzip recon.nii.gz
matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_extract('recon.nii'); exit"
gzip *.nii


