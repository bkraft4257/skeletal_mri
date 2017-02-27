#!/bin/bash

input_path=${1-$PWD}
input_path=$(readlink -f $input_path ) 
reorient_path=${input_path}/reorient/
moco_path=${input_path}/pasl_moco/
pasl_path=${input_path}/pasl/


for ii in 0 1 2 3; do
   [ -d ${moco_path}/${ii}/input ] || mkdir -p ${moco_path}/${ii}/input
   cp ${reorient_path}/pasl_moco_${ii}.nii.gz ${moco_path}/${ii}/input/moco.nii.gz
   cp -r ${pasl_path}/labels/ ${moco_path}/
done