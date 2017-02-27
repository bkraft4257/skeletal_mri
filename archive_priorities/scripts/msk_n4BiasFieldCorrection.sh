#!/bin/bash


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Iteration " $((ii+1))

echo
echo $(date)
echo $(whoami)
echo $(pwd)
echo
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


cp ${1}/t1w_36ms.nii.gz   ${1}/t1w_36ms_n4_0.nii.gz


for ii in {0..4}; do

cmd="N4BiasFieldCorrection -d 3 -i ${1}/t1w_36ms_n4_${ii}.nii.gz  -o ${1}/t1w_36ms_n4_$((ii+1)).nii.gz -r -s "

echo $cmd
# $cmd

done


ThresholdImage 3 t1w_36ms_n4_5.nii.gz t1w_36ms_n4_atLCC.nii.gz Otsu 1

ImageMath      3 t1w_36ms_n4_mask.nii.gz FillHoles t1w_36ms_n4_atLCC.nii.gz

ImageMath      3 t1w_36ms_n4_thigh.nii.gz GetLargestComponent t1w_36ms_n4_mask.nii.gz

ImageMath      3 t1w_36ms_n4_5b.nii.gz     m  t1w_36ms_n4_5.nii.gz     t1w_36ms_n4_thigh.nii.gz  
ImageMath      3 t1w_36ms_n4_atLCC.nii.gz  m  t1w_36ms_n4_atLCC.nii.gz t1w_36ms_n4_thigh.nii.gz  

#
# Estimate skeletal muscle component
#

ImageMath      3 t1w_36ms_n4_smEstimate.nii.gz FillHoles t1w_36ms_n4_atLCC.nii.gz
fslmaths         t1w_36ms_n4_thigh -sub  t1w_36ms_n4_atLCC.nii.gz t1w_36ms_n4_smEstimate.nii.gz 
fslmaths         t1w_36ms_n4_smEstimate.nii.gz -dilM -ero t1w_36ms_n4_smEstimate_b.nii.gz

ImageMath      3 t1w_36ms_n4_smEstimate_c.nii.gz GetLargestComponent t1w_36ms_n4_smEstimate_b.nii.gz
ImageMath      3 t1w_36ms_n4_smEstimate_d.nii.gz FillHoles t1w_36ms_n4_smEstimate_c.nii.gz
