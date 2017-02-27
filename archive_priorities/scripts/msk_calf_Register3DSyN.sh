#!/bin/bash

#!/bin/bash

PIPELINE_NAME="antsRegSyn"
PIPELINE_STAGE="01"
extension=".nii.gz"

inDir=${1-$PWD}

inFixedFileName=${2}
inFixedBaseFileName=$( basename ${inFixedFileName} ${extension} )

inMovingFileName=${3}
inMovingBaseFileName=$( basename ${inMovingFileName} ${extension} )

prefix=${inMovingBaseFileName}To${inFixedBaseFileName}

outDir="${4-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

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
echo
echo "outDir, " $outDir
echo "prefix, " $prefix
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

ImageMath 3 ${outDir}/${fixed}  PadImage ${inFixedFileName}   5
ImageMath 3 ${outDir}/${moving} PadImage ${inMovingFileName}  5

cd $outDir


#
# Calculating Translation Transformation
#

transform=translation
outFileName=${prefix}_${transform}${extension}

if [ ! -f ${prefix}_${transform}_0GenericAffine.mat ]; then

cmd="antsRegistration -d 3 -v -o ${prefix}_${transform}_                       \
                 --initial-moving-transform [${fixed},${moving},1]             \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]    \
                 --transform   	    	    $transform[0.1]                    \
                 --convergence 	    	    [ 100x50x25, 1e-6, 10 ]            \
                 --shrink-factors   	    8x4x2                              \
                 --smoothing-sigmas 	    8x4x2vox"

echo $cmd
$cmd

cmd="antsApplyTransforms -d 3 -o ${outFileName}       \
                    -r ${fixed}                       \
                    -i ${moving}                      \
                    -t ${prefix}_${transform}_0GenericAffine.mat -v"

echo $cmd
$cmd

fi

#
# Affine
#

transform=affine
outFileName=${prefix}_${transform}${extension}

if [ ! -f ${prefix}_${transform}_0GenericAffine.mat ]; then

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


#                 --initial-moving-transform rigid_0GenericAffine.mat       \
         
cmd="antsApplyTransforms -d 3 -o ${outFileName}       \
                    -r ${fixed}                       \
                    -i ${moving}                      \
                    -t ${prefix}_${transform}_0GenericAffine.mat -v"

echo $cmd
$cmd

fi


#
# Calculating Deformation Field along X and Y
#
transform=SyN
outFileName=${prefix}_${transform}${extension}

if [ ! -f ${prefix}_${transform}_0GenericAffine.mat ]; then

cmd="antsRegistration -d 3 -v -o ${prefix}_${transform}_                            \
                 --restrict-deformation     1x1x0                                   \
                 --initial-moving-transform ${prefix}_affine_0GenericAffine.mat     \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]         \
                 --transform   	    	    $transform[0.1, 26]                     \
                 --convergence 	    	    [ 200x200x200x100x50, 1e-6, 10 ]        \
                 --shrink-factors   	    16x8x4x2x1                              \
                 --smoothing-sigmas 	    8x4x2x1x0vox"

echo $cmd
$cmd

# Apply transformation

interp=HammingWindowedSinc

cmd="antsApplyTransforms -d 3 -o ${outFileName}                        \
                    --interpolation $interp                            \
                    -r ${fixed}                                        \
                    -i ${moving}                                       \
                    -t ${prefix}_${transform}_1Warp.nii.gz             \
                    -t ${prefix}_${transform}_0GenericAffine.mat -v"

echo $cmd
$cmd

fi


#
#  De-Pad transform images
#




