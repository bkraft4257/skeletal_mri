#!/bin/bash

PIPELINE_NAME="initTibia"
PIPELINE_STAGE="02"
extension=".nii.gz"

inDir=${1-$PWD}

inT2wFileName=${2-t2w.nii.gz}

inMask=${3-mask.t2w.nii.gz}
inSubFatMask=${4-subfat.t2w.nii.gz}

inT1wFileName=t1w.nii.gz

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

cp -f ${inDir}/${inT1wFileName}     ${outDir}/
cp -f ${inDir}/${inT2wFileName}     ${outDir}/
cp -f ${inDir}/${inMask}         ${outDir}/
cp -f ${inDir}/${inSubFatMask}   ${outDir}/

cd $outDir

# Find Perimeter of calf
#

echo "Find perimeter from mask"

fslmaths  mask.${inT2wFileName} -kernel boxv 3  -ero                  perimeter.step1.${inT2wFileName}
fslmaths  mask.${inT2wFileName} -sub perimeter.step1.${inT2wFileName} perimeter.${inT2wFileName}

#
# Remove SubFat from Mask
#


if true; then

fslmaths ${inSubFatMask} -binv -mas ${inMask} tibiaMarrow.step1.${inT2wFileName}

ImageMath 3 tibiaMarrow.step2.${inT2wFileName}  GetLargestComponent tibiaMarrow.step1.${inT2wFileName}


#
# 2 binary classification (1=fat, 0=everything else) of remaning fat
#

fslmaths     tibiaMarrow.step2.${inT2wFileName} -mul ${inT2wFileName} otsu.step1.${inT2wFileName}

ThresholdImage 3 otsu.step1.${inT2wFileName}  otsu.step2.${inT2wFileName} Otsu 1

fslmaths     otsu.step2.${inT2wFileName} -mul tibiaMarrow.step2.${inT2wFileName} tibiaMarrow.step3.${inT2wFileName}

ImageMath      3 tibiaMarrow.step5.${inT2wFileName}  GetLargestComponent tibiaMarrow.step3.${inT2wFileName}
 

#
# Find Perimeter of tibia marrow
#

echo "Find perimeter from marrow"

fslmaths  tibiaMarrow.step5.${inT2wFileName} -kernel boxv 29 -dilM -mas mask.${inT2wFileName}  step1.perimeter.tibiaMarrow.${inT2wFileName}

fi

#
# Calculate Tibia Cortex Mask
#

if true; then

echo "Calculate Tibia Cortex mask from ${inT1wFileName}"

# Expand estimate of marrow to find bone cortex. This will be used later to expand the subcutaneous fat.
# This step takes a very long time. 

#if [ ! -f tibiaCortex.step1.${inT1wFileName} ]; then

#fslmaths       tibiaMarrow.step4.${inT2wFileName} -kernel boxv 37 -dilF  \
#               -mul mask.${inT2wFileName}  tibiaCortex.step1.${inT1wFileName}
#fi
# Use T1w image because it has greater contrast between cortex, muscle, fat, and marrow

fslmaths       ${inT2wFileName} -mul ${inT1wFileName} -mas step1.perimeter.tibiaMarrow.${inT2wFileName} step3.perimeter.tibiaMarrow.${inT2wFileName}

# Invert image.
fslmaths       step3.perimeter.tibiaMarrow.${inT2wFileName} -recip -inm 1 -thr 0.2 -bin  tibiaCortex.step1.${inT1wFileName} 
fslmaths       tibiaCortex.step1.${inT1wFileName}           -dilM -ero   tibiaCortex.${inT1wFileName} 

fi


#
# Refine Tibia Marrow Mask
#

if true; then

echo "Refine Tibia Marrow mask"

# Subtract cortex from marrow.
fslmaths       tibiaMarrow.step7.${inT2wFileName}  -sub tibiaCortex.${inT1wFileName} -ero  tibiaMarrow.step9.${inT2wFileName}

# Grab largest components
ImageMath      3 tibiaMarrow.step9.${inT2wFileName}  GetLargestComponent tibiaMarrow.step9.${inT2wFileName}

# Dilate tibia Marrow Mask
fslmaths       tibiaMarrow.step9.${inT2wFileName}  -dilM  tibiaMarrow.${inT2wFileName}

fi

#
# Refine SubFat Mask
#

if true; then

echo "Refine subcutaneuos fat mask"

cp  -f         subfat.${inT2wFileName}            subfat.step0.${inT2wFileName} 

# Dilate Tibia mask to focus correction at boundary of cortex and subcutaneous fat.
# This takes a very long time. 

echo "Creating enlarged tibia mask"

fslmaths       tibiaCortex.${inT1wFileName}  -add tibiaMarrow.${inT2wFileName} -bin tibia.step1.${inT2wFileName}

fslmaths       tibia.step1.${inT2wFileName} -kernel box 7 -dilF  \
               -mul mask.${inT2wFileName}  tibia.step2.${inT2wFileName}

echo "Dilate subcutaneous fat mask"
fslmaths       subfat.step0.${inT2wFileName}  -kernel 2D -dilF -dilF  \
               -mul tibia.step2.${inT2wFileName} subfat.step1.${inT2wFileName}

fslmaths       subfat.step1.${inT2wFileName}  -mul mask.${inT2wFileName} subfat.step2.${inT2wFileName}


# Add tibiaCortex and dilated mask.  This assumes there is no muscle between tibia and subcutaneous fat.
echo "Add tibiaCortex and dilated mask."
fslmaths       tibia.step1.${inT2wFileName}  -add subfat.step2.${inT2wFileName} -bin subfat.step3.${inT2wFileName}

# Do not exceed the original tissue mask.
fslmaths       subfat.step3.${inT2wFileName}  -mul mask.${inT2wFileName}                subfat.step4.${inT2wFileName}

# Add original subfat mask
fslmaths       subfat.step4.${inT2wFileName}  -add subfat.step0.${inT2wFileName} -bin   subfat.step5.${inT2wFileName}

# Closing operation to fill in holes
fslmaths       subfat.step5.${inT2wFileName}  -kernel box 3 -dilF  -ero   subfat.step6.${inT2wFileName}

# Subtract cortex from subfat
fslmaths       subfat.step6.${inT2wFileName}  -sub tibia.step1.${inT2wFileName} -add perimeter.${inT2wFileName} -mas mask.${inT2wFileName} -thr 0 -bin subfat.step7.${inT2wFileName}

ImageMath      3 subfat.${inT2wFileName}  GetLargestComponent subfat.step6.${inT2wFileName}

 fslmaths       tibia.step1.${inT2wFileName} -binv -mul subfat.${inT2wFileName}   subfat.${inT2wFileName} 
#fslmaths       tibiaCortex.${inT2wFileName} -binv -mul tibiaMarrow.${inT1wFileName}       tibiaMarrow.${inT1wFileName} 

fi

#
# Create Label Image
#

if  true; then

cd $outDir

echo "Create Label Image"

fslmaths subfat.${inT2wFileName}        -mul  1 subfat.label.${inT2wFileName}

fslmaths subfat.${inT2wFileName} -add tibiaCortex.${inT1wFileName} -add tibiaMarrow.${inT2wFileName} -binv -mas mask.${inT2wFileName} -mul 2 muscle.label.${inT2wFileName}

fslmaths tibiaCortex.${inT1wFileName}   -mul  4 tibiaCortex.label.${inT1wFileName}
fslmaths tibiaMarrow.${inT2wFileName}   -mul  8 tibiaMarrow.label.${inT2wFileName}

fslmaths subfat.label.${inT2wFileName} -add tibiaCortex.label.${inT1wFileName} -add muscle.label.${inT2wFileName} \
                                       -add tibiaMarrow.label.${inT2wFileName} calfLabels.nii.gz


fi



#
# Remove Intermediate Steps
#

# rm -rf *.step[0-9].* *.label.* step*
