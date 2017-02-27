#!/bin/bash

PIPELINE_NAME="initFibula"
PIPELINE_STAGE="04"
extension=".nii.gz"

inDir=${1-$PWD}

inT2wFileName=${2-t2w.nii.gz}
inT1wFileName=t1w.nii.gz

inLabels=${3-calfLabels.nii.gz}
inMask=${4-mask.${inT2wFileName}}


outDir="${5-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inT2wFileName, " $inT2wFileName
echo "inT1wFileName, " $inT1wFileName
echo "inLabels, "      $inLabels
echo "inMask, "        $inMask
echo
echo "outDir, " $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

cp -f ${inDir}/${inT1wFileName}     ${outDir}/
cp -f ${inDir}/${inT2wFileName}     ${outDir}/
cp -f ${inDir}/${inLabels}          ${outDir}/inCalfLabels.nii.gz
cp -f ${inDir}/${inMask}            ${outDir}/

cd $outDir

#
# Estimate Skeletal Muscle Mask
#

if true; then

fslmaths inCalfLabels.nii.gz -binv -mul ${inMask} muscle.step1.${inT1wFileName}

ImageMath  3 muscle.${inT1wFileName}  GetLargestComponent muscle.step1.${inT1wFileName}

# fslmaths muscle.step2.${inT1wFileName} -mul  ${inT1wFileName} muscle.step3.${inT1wFileName}

# Invert image.
#fslmaths       muscle.step3.${inT1wFileName} -recip -mul 10000  -thr 50 -bin  muscle.step4.${inT1wFileName} 

#ImageMath   3  muscle.${inT1wFileName}  GetLargestComponent     muscle.step4.${inT1wFileName}

fi



# fslmaths       muscle.step5.${inT1wFileName} -kernel box 5 -dilF   muscle.step6.${inT1wFileName}

#
# Create Label Image
#

if  true; then

echo "Create Label Image"

fslmaths muscle.${inT1wFileName}        -mul  2 muscle.label.${inT1wFileName}

fslmaths inCalfLabels.nii.gz   -add muscle.label.${inT1wFileName} ${inLabels}


fi



#
# Remove Intermediate Steps
#

# rm -rf *.step[0-9].*
