#!/bin/bash

PIPELINE_NAME="initSubFat"
PIPELINE_STAGE="02"
extension=".nii.gz"

inDir=${1-$PWD}

inT2wFileName=${2-t2w.nii.gz}
inT2wBaseFileName=$( basename ${inT2wFileName} ${extension} )

# inT1wFileName=t1w.nii.gz
# inT1wBaseFileName=$( basename ${inT1wFileName} ${extension} )

outDir="${3-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inT2wFileName, " $inT2wFileName
echo "inT2wBaseFileName, " $inBaseFileName
echo
echo "outDir, " $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

cp -f ${inDir}/${inT2wFileName}   ${outDir}/
# cp -f ${inDir}/${inT1wFileName}   ${outDir}/

cd $outDir

#
# Calculate tissue mask 
#

# Threshold mask
# fslmaths       ${inT1wFileName}   -thrp 35   -bin mask.step1.${inT1wFileName} 

echo "Create  tissue mask from ${inT2wFileName}"

ImageMath     3 mask.step1.${inT2wFileName} ThresholdAtMean ${inT2wFileName} 2
ImageMath     3 mask.step2.${inT2wFileName}  FillHoles mask.step1.${inT2wFileName}

# Closing operation.  Erode mask just a little bit more than dilation to tighten mask.

fslmaths       mask.step2.${inT2wFileName} -kernel boxv 5  -dilF -ero mask.step3.${inT2wFileName}

ImageMath      3 mask.step4.${inT2wFileName}  GetLargestComponent mask.step3.${inT2wFileName}

fslmaths       mask.step4.${inT2wFileName} -nan mask.${inT2wFileName}


#
# Find Perimeter of calf
#

echo "Find perimeter from mask"

fslmaths  mask.${inT2wFileName} -kernel boxv 3  -ero              perimeter.step1.${inT2wFileName}
fslmaths  mask.${inT2wFileName} -sub perimeter.step1.${inT2wFileName} perimeter.${inT2wFileName}


#
# 2 binary classification (1=fat, 0=everything else)
#

echo "Binary classification"

fslmaths     mask.${inT2wFileName} -mul ${inT2wFileName} otsu.step1.${inT2wFileName}

ThresholdImage 3 otsu.step1.${inT2wFileName}  otsu.step2.${inT2wFileName} Otsu 1

# Open operation
fslmaths       otsu.step2.${inT2wFileName} -kernel boxv 3    -ero   -dilF     otsu.step3.${inT2wFileName}
fslmaths       otsu.step3.${inT2wFileName} -add perimeter.${inT2wFileName}  -bin  otsu.step4.${inT2wFileName}

ImageMath      3 otsu.step5.${inT2wFileName}  GetLargestComponent otsu.step4.${inT2wFileName}


fslmaths       otsu.step5.${inT2wFileName} -kernel boxv 5  -dilF             otsu.step6.${inT2wFileName}

fslmaths       mask.${inT2wFileName}       -mul   otsu.step6.${inT2wFileName}       otsu.step7.${inT2wFileName}
fslmaths       otsu.step2.${inT2wFileName} -mul   otsu.step7.${inT2wFileName}       otsu.step8.${inT2wFileName}
fslmaths       otsu.step8.${inT2wFileName} -add   perimeter.${inT2wFileName}  -bin  otsu.${inT2wFileName}


#
# Close operation
#

ImageMath      3 subfat.step1.${inT2wFileName}  GetLargestComponent otsu.${inT2wFileName}
fslmaths       subfat.step1.${inT2wFileName} -kernel boxv 3    -dilF -ero  subfat.step2.${inT2wFileName}
fslmaths       subfat.step2.${inT2wFileName} -kernel boxv 3    -ero  -dilF subfat.${inT2wFileName}

#
# Remove Intermediate Steps
#

echo
# rm -rf *.step[0-9].*