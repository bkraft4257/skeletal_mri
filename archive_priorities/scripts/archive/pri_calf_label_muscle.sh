#!/bin/bash

PIPELINE_NAME="initTibia"
PIPELINE_STAGE="03"
extension=".nii.gz"

inDir=${1-$PWD}
inFileName=${2-t2w.nii.gz}
inMask=${3-mask.t2w.nii.gz}
inSubFatMask=${4-subfat.t2w.nii.gz}

inBaseFileName=$( basename ${inFileName} ${extension} )

outDir="${5-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

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
echo "inMask, " $inMask
echo "inSubFatMask, " $inSubFatMask
echo
echo "outDir, " $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

cp -f ${inDir}/${inFileName}     ${outDir}/
cp -f ${inDir}/${inMask}         ${outDir}/
cp -f ${inDir}/${inSubFatMask}   ${outDir}/

cd $outDir

#
# Remove SubFat from Mask
#

if false; then
fslmaths ${inSubFatMask} -binv -mul ${inMask} tibiaMarrow.step1.${inFileName}

ImageMath      3 tibiaMarrow.step2.${inFileName}  GetLargestComponent tibiaMarrow.step1.${inFileName}

#
# 2 binary classification (1=fat, 0=everything else)
#

fslmaths     mask.${inFileName} -mul ${inFileName} otsu.step1.${inFileName}

ThresholdImage 3 otsu.step1.${inFileName}  otsu.step2.${inFileName} Otsu 1

fslmaths     otsu.step2.${inFileName} -mul tibiaMarrow.step1.${inFileName} tibiaMarrow.step2.${inFileName}


# Open operation
fslmaths       tibiaMarrow.step2.${inFileName} -kernel boxv 5x5x1    -ero -dilM     tibiaMarrow.step3.${inFileName}

ImageMath      3 tibiaMarrow.step4.${inFileName}  GetLargestComponent tibiaMarrow.step3.${inFileName}

fi 

# Calculate Tibia Cortex Mask

if false; then
fslmaths       tibiaMarrow.step4.${inFileName} -kernel boxv 21x21x1 -dilM       tibiaCortex.step1.${inFileName}
fslmaths       tibiaCortex.step1.${inFileName} -mul  t1w.nii.gz                 tibiaCortex.step2.${inFileName} 
fslmaths       tibiaCortex.step2.${inFileName} -recip -mul 10000  -thr 40 -bin  tibiaCortex.step3.${inFileName} 
fslmaths       tibiaCortex.step3.${inFileName} -kernel boxv 5x5x1 -dilM -ero    tibiaCortex.step4.${inFileName}

ImageMath      3 tibiaCortex.${inFileName}  GetLargestComponent tibiaCortex.step4.${inFileName}
fi

#
# Refine Tibia Marrow Mask
#

fslmaths       tibiaMarrow.step4.${inFileName}  -add tibiaCortex.${inFileName} -bin tibiaMarrow.step5.${inFileName}
fslmaths       tibiaMarrow.step5.${inFileName}  -kernel boxv 7x7x1 -dilM -ero       tibiaMarrow.step6.${inFileName}
fslmaths       tibiaMarrow.step6.${inFileName}  -sub tibiaCortex.${inFileName}      tibiaMarrow.step7.${inFileName
fslmaths       tibiaMarrow.step7.${inFileName}  -kernel boxv 5x5x1 -dilM -ero -dilM tibiaMarrow.step8.${inFileName}

ImageMath      3 tibiaMarrow.${inFileName}  GetLargestComponent tibiaMarrow.step8.${inFileName}

#
# Remove Intermediate Steps
#

rm -rf *.step[0-9].*
