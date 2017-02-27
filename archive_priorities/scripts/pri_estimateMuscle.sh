#!/bin/bash

PIPELINE_STAGE=msk_initSegment
extension=".nii.gz"

inDir=${1-$PWD}
inFileName=${2}
inBaseFileName=$(basename ${inFileName} ${extension})

outDir="${3-${inDir}/../04-initSegment}"


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inFileName, " $inFileName
echo "inBaseFileName, " $inBaseFileName
echo
echo "outDir, " $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

[ -d $outDir ] || mkdir -p $outDir

cp ${inDir}/${inFileName}   ${outDir}/

cd $outDir

#
# Estimate skeletal muscle component
#

# fslmaths       ${inBaseFileName}_mask${extension}   -kernel box 3 -dilF ${inBaseFileName}_dilate${extension}
fslmaths       ${inBaseFileName}_mask${extension} -kernel boxv 3x3x1  -ero  ${inBaseFileName}_erode${extension}
fslmaths       ${inBaseFileName}_mask${extension} -sub  ${inBaseFileName}_erode${extension} perimeter_${inFileName}

#
# 2 bin classification (1=muscle, 2=fat)
#

ThresholdImage 3 ${inFileName} otsu_${inFileName} Otsu 1
fslmaths otsu_${inFileName} -add perimeter_${inFileName}  -bin subfat.step1.${inFileName}

# Get largest component and delete it
ImageMath      3 subfat.step2.${inFileName} GetLargestComponent subfat.step1.${inFileName}
fslmaths         subfat.step2.${inFileName} -binv -mul subfat.step1.${inFileName} subfat.step3.${inFileName}

# Get 2nd largest component and delete it
ImageMath      3 tibia.step.${inFileName}   GetLargestComponent subfat.step3.${inFileName}
fslmaths         tibia.step.${inFileName}  -binv -mul subfat.step3.${inFileName} sm_fat.step.${inFileName}

fslmaths       tibia.step.${inFileName} -add subfat.step2.${inFileName} -binv -mul ${inBaseFileName}_mask.nii.gz fat_mask.step.${inFileName} 
ImageMath      3 sm_estimate.step.${inFileName}   GetLargestComponent fat_mask.step.${inFileName} 
exit 

#
# Create an estimate of the skeletal muscle
#

ImageMath      3 sm_filled_mask.step.${inFileName} FillHoles sm_estimate_mask.step.${inFileName}
fslmaths         sm_filled_mask.step.${inFileName} -kernel boxv 5x5x1 -dilM sm_dilm.step.${inFileName}
fslmaths         sm_dilm.step.${inFileName}        -kernel boxv 5x5x1 -ero  sm_estimate.step.${inFileName}


#
# Create Mask of Tibia
#


#fslmaths         ${inBaseFileName}_smEstimate${extension} -dilM -ero ${inBaseFileName}_smEstimate_b${extension}
#ImageMath      3 ${inBaseFileName}_smEstimate_c${extension} GetLargestComponent ${inBaseFileName}_smEstimate_b${extension}
#ImageMath      3 ${inBaseFileName}_smEstimate_d${extension} FillHoles ${inBaseFileName}_smEstimate_c${extension}
