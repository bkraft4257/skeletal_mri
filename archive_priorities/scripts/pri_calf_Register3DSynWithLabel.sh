#!/bin/bash

PIPELINE_NAME="antsRegSyn"
PIPELINE_STAGE="02"
extension=".nii.gz"

inDir=${1-$PWD}
inDir=$(readlink -f ${inDir})

inFixedFileName=${2}
inFixedBaseFileName=$( basename ${inFixedFileName} ${extension} )

inMovingFileName=${3}
inMovingBaseFileName=$( basename ${inMovingFileName} ${extension} )

inLabelFileName=${4}
inLabelBaseFileName=$( basename ${inLabelFileName} ${extension} )

prefix=${inMovingBaseFileName}_To_${inFixedBaseFileName}
prefixLabel=${inLabelBaseFileName}_To_${inFixedBaseFileName}

outDir="${5-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

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
echo "inMovingFileName,     " $inMovingFileName
echo "inMovingBaseFileName, " $inMovingBaseFileName
echo "inLabelFileName,     " $inLabelFileName
echo "inLabelBaseFileName, " $inLabelBaseFileName
echo
echo "outDir, "      $outDir
echo "prefix, "      $prefix
echo "prefixLabel, " $prefixLabel
echo
antsRegistration --version
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

fixed=pad.${inFixedFileName}
moving=pad.${inMovingFileName}
movingLabel=pad.${inLabelFileName}

nPadImage=5

[ -f ${outDir}/${fixed}  ]      ||  ImageMath 3  ${outDir}/${fixed}       PadImage ${inDir}/${inFixedFileName}   ${nPadImage}
[ -f ${outDir}/${moving} ]      ||  ImageMath 3  ${outDir}/${moving}      PadImage ${inDir}/${inMovingFileName}  ${nPadImage}
[ -f ${outDir}/${movingLabel} ] ||  ImageMath 3  ${outDir}/${movingLabel} PadImage ${inDir}/${inLabelFileName}  ${nPadImage}

cd $outDir


echo "# ======================================================================================="
echo "# Calculating Translation Transformation"
echo "#"

transform=translation
outFileName=${prefix}_${transform}
outLabelFileName=${prefixLabel}_${transform}

if [ ! -f ${outFileName}_0GenericAffine.mat ]; then

cmd="antsRegistration -d 3 -v -o ${outFileName}_                               \
                 --initial-moving-transform [${fixed},${moving},1]             \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]    \
                 --transform   	    	    $transform[0.1]                    \
                 --convergence 	    	    [ 100x50x25, 1e-6, 10 ]            \
                 --shrink-factors   	    8x4x2                              \
                 --smoothing-sigmas 	    8x4x2vox"

echo $cmd
$cmd

fi

# Apply transformation

interp=HammingWindowedSinc

cmd="antsApplyTransforms -d 3 -o ${outFileName}${extension}   \
                    --interpolation  ${interp}                \
                    -r ${fixed}                               \
                    -i ${moving}                              \
                    -t ${outFileName}_0GenericAffine.mat -v"

echo $cmd
$cmd

echo 
echo "======="
echo 

# Apply Transformation to Label


interp=MultiLabel

cmd="antsApplyTransforms -d 3 -o ${outLabelFileName}${extension}       \
                    --interpolation $interp                            \
                    -r ${fixed}                                        \
                    -i ${movingLabel}                                  \
                    -t ${outFileName}_0GenericAffine.mat -v"

echo $cmd
$cmd

echo "#======================================================================================="
echo "# Affine"
echo "#"

transform=affine
outFileName=${prefix}_${transform}
outLabelFileName=${prefixLabel}_${transform}

if [ ! -f ${outFileName}_0GenericAffine.mat ]; then

cmd="antsRegistration -d 3 -v -o ${prefix}_${transform}_                             \
                 --initial-moving-transform ${prefix}_translation_0GenericAffine.mat \
                 --restrict-deformation     1x1x1x1x1x1x0x0x0x1x1x0                  \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]          \
                 --transform   	    	    $transform[0.1]                          \
                 --convergence 	    	    [ 100x50x25, 1e-6, 10 ]                  \
                 --shrink-factors   	    4x2x1                                    \
                 --smoothing-sigmas 	    2x1x0vox"

echo $cmd
$cmd

fi


# Apply transformation

interp=HammingWindowedSinc

cmd="antsApplyTransforms -d 3 -o ${outFileName}${extension}    \
                    --interpolation  ${interp}                 \
                    -r ${fixed}                                \
                    -i ${moving}                               \
                    -t ${outFileName}_0GenericAffine.mat -v"

echo $cmd
$cmd


echo 
echo "======="
echo 

# Apply Transformation to Label


interp=MultiLabel

cmd="antsApplyTransforms -d 3 -o ${outLabelFileName}${extension}   \
                    --interpolation $interp                        \
                    -r ${fixed}                                    \
                    -i ${movingLabel}                              \
                    -t ${outFileName}_0GenericAffine.mat -v"

echo $cmd
$cmd




echo "#======================================================================================="
echo "# Calculating Deformation Field along X and Y"
echo "#"

transform=SyN
outFileName=${prefix}_${transform}
outLabelFileName=${prefixLabel}_${transform}

if [ ! -f ${outFileName}_0GenericAffine.mat ]; then

cmd="antsRegistration -d 3 -v -o ${outFileName}_                           \
                 --restrict-deformation     1x1x0                                   \
                 --initial-moving-transform ${prefix}_affine_0GenericAffine.mat     \
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

cmd="antsApplyTransforms -d 3 -o ${outFileName}${extension}    \
                    --interpolation ${interp}                  \
                    -r ${fixed}                                \
                    -i ${moving}                               \
                    -t ${outFileName}_1Warp.nii.gz             \
                    -t ${outFileName}_0GenericAffine.mat -v"

echo $cmd
$cmd

echo 
echo "======="
echo 

# Apply Transformation to Label


interp=MultiLabel

cmd="antsApplyTransforms -d 3 -o ${outLabelFileName}${extension}       \
                    --interpolation $interp                            \
                    -r ${fixed}                                        \
                    -i ${movingLabel}                                  \
                    -t ${outFileName}_1Warp.nii.gz                     \
                    -t ${outFileName}_0GenericAffine.mat -v"

echo $cmd
$cmd



# ImageMath 3 ${outDir}/${fixed}       PadImage ${inFixedFileName}   -${nPadImage}
# ImageMath 3 ${outDir}/${moving}      PadImage ${inMovingFileName}  -${nPadImage}
# ImageMath 3 ${outDir}/${movingLabel} PadImage ${inLabelFileName}  -${nPadImage}


