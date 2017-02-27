#!/bin/bash

PIPELINE_STAGE=msk_getLargestConnectedComponent
extension=".nii.gz"

inDir=${1-$PWD}
inFileName=${2}
inBaseFileName=$(basename ${inFileName} ${extension})

outDir="${3-${inDir}/../03-getLCC}"


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

cp ${inDir}/${inFileName}   ${outDir}/${inBaseFileName}_original${extension}

cd $outDir

#
# Find the largest single component
#

ImageMath      3 ${inBaseFileName}_threshold${extension} ThresholdAtMean ${inBaseFileName}_original${extension} 1

ImageMath      3 ${inBaseFileName}_filled${extension} FillHoles ${inBaseFileName}_threshold${extension}

ImageMath      3 ${inBaseFileName}_mask${extension} GetLargestComponent ${inBaseFileName}_filled${extension}

ImageMath      3 ${inFileName} m  ${inBaseFileName}_original${extension}       ${inBaseFileName}_mask${extension}  


#
# Estimate skeletal muscle component
#

#ImageMath      3 ${inBaseFileName}_smEstimate${extension} FillHoles ${inBaseFileName}_atLCC${extension}
#fslmaths         ${inBaseFileName}_extremity -sub  ${inBaseFileName}_atLCC${extension} ${inBaseFileName}_smEstimate${extension} 
#fslmaths         ${inBaseFileName}_smEstimate${extension} -dilM -ero ${inBaseFileName}_smEstimate_b${extension}

#ImageMath      3 ${inBaseFileName}_smEstimate_c${extension} GetLargestComponent ${inBaseFileName}_smEstimate_b${extension}
#ImageMath      3 ${inBaseFileName}_smEstimate_d${extension} FillHoles ${inBaseFileName}_smEstimate_c${extension}
