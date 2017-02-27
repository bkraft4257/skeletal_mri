#!/bin/bash
timePoint=${1}

rename wTo1 w_To_1 *
ln -f t2w.nii.gz ../results/${timePoint}_reorient_t2w.nii.gz

antsApplyTransforms -d 3  -v  -n MultiLabel \
-i 1_project.t2w_seg.nii.gz \
-r   t2w.nii.gz  \
-o ../results/${timePoint}_reorient_t2w_seg.nii.gz \
-t [ ${timePoint}_reorient_t2w_To_1_reorient_t2w_SyN_0GenericAffine.mat , 1]  \
-t   ${timePoint}_reorient_t2w_To_1_reorient_t2w_SyN_1InverseWarp.nii.gz  


