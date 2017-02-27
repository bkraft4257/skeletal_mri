#!/bin/bash

inDir=${1-PWD}
inDir=$( readlink -f ${inDir} )

inImage=${2-$(ls *reorient_t2w_seg.nii.gz)}
inMC=${3-13}
inPadImage=${4-"-5"}

outDir=${inDir}/../01-segment
[ -d $outDir ] || mkdir $outDir
outDir=$( readlink -f ${outDir} )


resultsDir=${inDir}/../results
[ -d $resultsDir ] || mkdir $resultsDir
resultsDir=$( readlink -f ${resultsDir} )


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inLabelImage, " $inImage
echo "inMC, "         $inMC
echo "inPadImage, "   $inPadImage
echo
echo "outDir, " $outDir
echo "resultsDir, " $resultsDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

cd $outDir;

fslmaths ${inDir}/${inImage} -bin 1.muscle.${inImage}

ImageMath 3 2.muscle.${inImage}  MC                  1.muscle.${inImage} $inMC
ImageMath 3 3.muscle.${inImage}  GetLargestComponent 2.muscle.${inImage}
ImageMath 3 4.muscle.${inImage}  FillHoles           3.muscle.${inImage}

if [ ${inPadImage}  -ne 0 ]; then
    ImageMath 3   mask.muscle.nii.gz      PadImage            4.muscle.${inImage} $inPadImage
else
    mv 4.muscle.${inImage} mask.muscle.nii.gz
fi

# rm -rf [1-9].muscle.${inImage}

#
#  Create hard link to results directory
#

ln -f ${outDir}/mask.muscle.nii.gz ${resultsDir}/mask.muscle.nii.gz