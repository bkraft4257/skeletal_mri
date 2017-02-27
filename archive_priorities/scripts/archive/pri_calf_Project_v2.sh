#!/bin/bash

PIPELINE_NAME="antsRegSyN"
PIPELINE_STAGE="01"
extension=".nii.gz"

inDir=${1-$PWD}

inFixedFileName=${2}
inFixedBaseFileName=$( basename ${inFixedFileName} ${extension} )

inLabelFileName=${3}
inLabelBaseFileName=$( basename ${inLabelFileName} ${extension} )

inCenterSlice=${4-2}

outDir="${5-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"
resultsDir="${5-${inDir}/../results}"

[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})


[ -d $resultsDir ] || mkdir -p $resultsDir
resultsDir=$(readlink -f ${resultsDir})


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir,                " $inDir
echo "inFixedFileName,      " $inFixedFileName
echo "inFixedBaseFileName,  " $inFixedBaseFileName
echo "inLabelFileName,      " $inLabelFileName
echo "inLabelBaseFileName,  " $inLabelBaseFileName
echo "inCenterSlice,"         $inCenterSlice
echo
echo "outDir, "      $outDir
echo "resultsDir, "  $resultsDir
echo "prefix, "      $prefix
echo "prefixLabel, " $prefixLabel
echo
antsRegistration --version
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

#
# Project Slice across volume
#

iwProjectSlice.sh  ${inDir} ${inFixedFileName} ${inCenterSlice} ${outDir}
iwProjectSlice.sh  ${inDir} ${inLabelFileName} ${inCenterSlice} ${outDir}

#
#
#

cd $outDir

#
# Pad images before registration
#

fixed=${inFixedFileName}
moving=project.${inFixedFileName}
movingLabel=project.${inLabelFileName}

prefix=project.${inFixedBaseFileName}_To_${inFixedBaseFileName}
prefixLabel=project.${inLabelBaseFileName}_To_${inFixedBaseFileName}


nPadImage=5

ImageMath 3 ${fixed}       PadImage ${fixed}         ${nPadImage}
ImageMath 3 ${moving}      PadImage ${moving}        ${nPadImage}
ImageMath 3 ${movingLabel} PadImage ${movingLabel}   ${nPadImage}


#=======================================================================================
# Calculating Deformation Field along X and Y
#
transform=SyN
outFileName=${prefix}_${transform}
outLabelFileName=${prefixLabel}_${transform}

if [ ! -f ${outFileName}_0Warp.nii.gz ]; then

cmd="antsRegistration -d 3 -v -o ${outFileName}_                           \
                 --restrict-deformation     1x1x0                                   \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]         \
                 --transform   	    	    $transform[0.1, 26]                     \
                 --convergence 	    	    [ 200x200x200x100x50, 1e-6, 10 ]        \
                 --shrink-factors   	    16x8x4x2x1                              \
                 --smoothing-sigmas 	    8x4x2x1x0vox"

echo $cmd
$cmd

fi


# Apply transformation

interp=HammingWindowedSinc

cmd="antsApplyTransforms -d 3 -v \
                    -o ${outFileName}${extension}    \
                    --interpolation  ${interp}                                  \
                    -r ${fixed}                                        \
                    -i ${moving}                                       \
                    -t ${outFileName}_0Warp.nii.gz"


echo $cmd
$cmd

# Apply Transformation to Label


interp=MultiLabel

cmd="antsApplyTransforms -d 3 -v \
                    -o ${outLabelFileName}${extension}       \
                    --interpolation $interp                            \
                    -r ${fixed}                                        \
                    -i ${movingLabel}                                  \
                    -t ${outFileName}_0Warp.nii.gz"


echo $cmd
$cmd


#
# Copy output to results directory
#

cp ${outFileName}_0Warp.nii.gz ${outLabelFileName}${extension} ${outFileName}${extension}  ${resultsDir}


#
#  De-Pad transform images
#

# ImageMath 3 ${outDir}/${fixed}       PadImage ${inFixedFileName}   -${nPadImage}
# ImageMath 3 ${outDir}/${moving}      PadImage ${inMovingFileName}  -${nPadImage}
# ImageMath 3 ${outDir}/${movingLabel} PadImage ${inLabelsFileName}  -${nPadImage}


