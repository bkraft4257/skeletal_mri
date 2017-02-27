#!/bin/bash

inDir=${1}
outDir=${2}  

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo
echo "funcName:" $FUNCNAME
echo "date:"     $(date)
echo "user:"     $(whoami)
echo "pwd: "     $(pwd)
echo "inDir:"    ${inDir}
echo "outDir:"   ${outDir}
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


inBaseImage=t1w_36ms_n4
extension=.nii.gz

inImage=${inBaseImage}_f5${extension}



if [ ! -d ${outDir} ]; then 
   mkdir ${outDir}
fi

cp -sf  ${inDir}/${inImage} ${outDir}/${inBaseImage}${extension}

cd ${outDir}

ThresholdImage 3 ${inBaseImage}${extension} ${inBaseImage}_atLccEstimate${extension} Otsu 1

ImageMath      3 ${inBaseImage}_mask${extension} FillHoles ${inBaseImage}_atLccEstimate${extension}

ImageMath      3 ${inBaseImage}_thigh${extension} GetLargestComponent ${inBaseImage}_mask${extension}

ImageMath      3 ${inBaseImage}b${extension}       m  ${inBaseImage}${extension}     ${inBaseImage}_thigh${extension}  
ImageMath      3 ${inBaseImage}_atLccEstimate${extension}  m  ${inBaseImage}_atLccEstimate${extension} ${inBaseImage}_thigh${extension}  

#
# Estimate skeletal muscle component
#

fslmaths         ${inBaseImage}_thigh -sub  ${inBaseImage}_atLccEstimate${extension} ${inBaseImage}_smEstimate_a${extension} 
fslmaths         ${inBaseImage}_smEstimate_a${extension} -dilM -ero ${inBaseImage}_smEstimate_b${extension}

ImageMath      3 ${inBaseImage}_smEstimate_c${extension} GetLargestComponent ${inBaseImage}_smEstimate_b${extension}
ImageMath      3 ${inBaseImage}_smEstimate_d${extension} FillHoles ${inBaseImage}_smEstimate_c${extension}

cp ${inBaseImage}_smEstimate_d${extension} ${inBaseImage}_smEstimate${extension}

rm ${inBaseImage}_smEstimate_{a,b,c,d}${extension}

#
# Uncompress All images
#

gunzip *.gz