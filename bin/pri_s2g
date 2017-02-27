#!/bin/bash

input_path=${1-$PWD}
input_path=$(readlink -f $input_path)

methods_path=$input_path/../methods/
methods_path=$(readlink -f $methods_path)

echo
echo $input_path
echo $methods_path
echo


[ -d $methods_path ] || mkdir $methods_path
cd $methods_path

if false; then 

# Extract M0 and CL images
fslroi ${input_path}/moco.nii.gz ${methods_path}/m0.nii.gz 0 1
fslroi ${input_path}/moco.nii.gz ${methods_path}/cl.nii.gz 1 -1

# Create M0 mask and create QA labels
$TIC_LABELS_PATH/labels/create_mask.py m0.nii.gz -r --clean
$TIC_LABELS_PATH/labels/create_qa_labels.py mask.m0.nii.gz

# Perform Simple Subtraction
ImageMath 4 pwi.nii.gz TimeSeriesSimpleSubtraction cl.nii.gz

# Take abs value
fslmaths pwi.nii.gz -abs abs.pwi.nii.gz

# Measure phase ghosts. Phase ghosts are measured from the absolute value so it doesn't matter if 
# you use pwi.nii.gz or abs.pwi.nii.gz 

$TIC_LABELS_PATH/labels/measure.py qa_background_label.mask.m0.nii.gz   abs.pwi.nii.gz  --out abs.pwi.csv -v
$TIC_LABELS_PATH/labels/calculate_phase_ghosts.py abs.pwi.csv --out prefix -v

sort_list=$(tail -n +2 phase_ghosts.abs.pwi.csv | cut -d , -f 1 | tr "\n" " ")


# Sort and calculate cumulative sum
$TIC_TOOLS_PATH/tools/sort_nii.py pwi.nii.gz -s $sort_list
$TIC_TOOLS_PATH/tools/sort_nii.py abs.pwi.nii.gz -s $sort_list

fi 

$TIC_TOOLS_PATH/tools/cummean_nii.py sort_nii.pwi.nii.gz -o cummean.pwi.nii.gz
$TIC_TOOLS_PATH/tools/cummean_nii.py sort_nii.abs.pwi.nii.gz -o cummean.abs.pwi.nii.gz

