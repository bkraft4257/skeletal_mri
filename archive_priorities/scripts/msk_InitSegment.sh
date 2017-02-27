#!/bin/bash


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

echo
echo $(date)
echo $(whoami)
echo $(pwd)
echo
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

inDir=${1}
inBaseImage=t1w_36ms_n4
extension=.nii.gz

inImage=${inBaseImage}_5${extension}

outDir=${inDir}/../02-initSegment

mkdir ${outDir}
cp    ${inDir}/${inImage} ${outDir} 

cd ${outDir}

ThresholdImage 3 ${inBaseImage}_5${extension} ${inBaseImage}_atLCC${extension} Otsu 1

ImageMath      3 ${inBaseImage}_mask${extension} FillHoles ${inBaseImage}_atLCC${extension}

ImageMath      3 ${inBaseImage}_thigh${extension} GetLargestComponent ${inBaseImage}_mask${extension}

ImageMath      3 ${inBaseImage}b${extension}       m  ${inBaseImage}${extension}     ${inBaseImage}_thigh${extension}  
ImageMath      3 ${inBaseImage}_atLCC${extension}  m  ${inBaseImage}_atLCC${extension} ${inBaseImage}_thigh${extension}  

#
# Estimate skeletal muscle component
#

fslmaths         ${inBaseImage}_thigh -sub  ${inBaseImage}_atLCC${extension} ${inBaseImage}_smEstimate_a${extension} 
fslmaths         ${inBaseImage}_smEstimate_a${extension} -dilM -ero ${inBaseImage}_smEstimate_b${extension}

ImageMath      3 ${inBaseImage}_smEstimate_c${extension} GetLargestComponent ${inBaseImage}_smEstimate_b${extension}
ImageMath      3 ${inBaseImage}_smEstimate_d${extension} FillHoles ${inBaseImage}_smEstimate_c${extension}

cp ${inBaseImage}_smEstimate_d${extension} ${inBaseImage}_smEstimate${extension}

rm ${inBaseImage}_smEstimate_{a,b,c,d}${extension}


