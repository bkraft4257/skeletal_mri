#!/bin/bash

input_path=${1-$PWD}
# input_path=$(readlink -f $input_path)

pasl_path=$input_path/pasl
pasl_moco_path=$input_path/pasl_moco

for ii_visit in 1 2 3; do 
   for ii in 0 1 2 3; do
       echo
       echo "=============================================================="
       echo $ii_visit $ii
       pwd

       # ls ${ii_visit}/${pasl_path}/${ii}/01-register/maskM0_To_mask.muscle_{0GenericAffine,1Warp}*
       # ls ${ii_visit}/${pasl_moco_path}/${ii}/input

       #cmd1="cp ${ii_visit}/${pasl_path}/${ii}/01-register/maskM0_To_mask.muscle_0GenericAffine.mat ${ii_visit}/${pasl_moco_path}/${ii}/input"
       #$cmd1

       #cmd2="cp ${ii_visit}/${pasl_path}/${ii}/01-register/maskM0_To_mask.muscle_1Warp.nii.gz ${ii_visit}/${pasl_moco_path}/${ii}/input"
       #$cmd2

       cmd3="cp ${ii_visit}/${pasl_path}/${ii}/01-register/maskM0_To_mask.muscle_1InverseWarp.nii.gz ${ii_visit}/${pasl_moco_path}/${ii}/input"
       $cmd3
       echo
   done
done
