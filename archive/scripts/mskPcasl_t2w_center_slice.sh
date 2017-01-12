#!/bin/bash

gunzip project.roi.t2w.nii.gz
matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_slice_scale('project.roi.t2w.nii', [], 'center_slice.t2w.nii');  exit"
gzip *.nii
iwCreateMask.py center_slice.t2w.nii.gz --thr 50 -r --qo --ac &

cp mask.center_slice.t2w.nii.gz ../results
