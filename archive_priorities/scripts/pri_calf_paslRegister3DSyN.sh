#!/bin/bash

#!/bin/bash

PIPELINE_NAME="antsRegSyn"
PIPELINE_STAGE="02"
extension=".nii.gz"

inDir=${1-$PWD}

inFixedFileName=${2}
inFixedBaseFileName=$( basename ${inFixedFileName} ${extension} )
inFixedDir=$( dirname ${inFixedFileName})

inMovingFileName=${3}
inMovingBaseFileName=$( basename ${inMovingFileName} ${extension} )
inMovingDir=$( dirname ${inMovingFileName})

prefix=${inMovingBaseFileName}_To_${inFixedBaseFileName}

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
echo "inFixedDir,           " $inFixedDir
echo "inFixedBaseFileName,  " $inFixedBaseFileName
echo
echo "inMovingFileName,     " $inMovingFileName
echo "inMovingDir,          " $inMovingDir
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

extension=".nii.gz"

fixed=pad.${inFixedBaseFileName}${extension}
moving=pad.${inMovingBaseFileName}${extension}

#echo $fixed
#echo $moving

cmd="ImageMath 3 ${outDir}/${fixed}  PadImage ${inFixedFileName}   5"
echo $cmd
$cmd

cmd="ImageMath 3 ${outDir}/${moving} PadImage ${inMovingFileName}  5"
echo $cmd
$cmd

cd $outDir


echo "#"
echo "# Calculating Translation Transformation"
echo "#"

transform=translation
outFileName=${prefix}_${transform}${extension}

its=1e-4

if [ ! -f ${prefix}_${transform}_0GenericAffine.mat ]; then

cmd="antsRegistration -d 3 -v -o ${prefix}_${transform}_                       \
                 --initial-moving-transform [${fixed},${moving},1]             \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]    \
                 --transform   	    	    $transform[0.1]                    \
                 --convergence 	    	    [ 80x40x20, $its, 10 ]            \
                 --shrink-factors   	    4x2x1                              \
                 --smoothing-sigmas 	    4x2x1vox"

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
                 --convergence 	    	    [ 80x40x20, $its, 10 ]                  \
                 --shrink-factors   	    4x2x1                                    \
                 --smoothing-sigmas 	    4x2x1vox"

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
                 --convergence 	    	    [ 80x40x20, $its, 10 ]                  \
                 --shrink-factors   	    4x2x1                                   \
                 --smoothing-sigmas 	    8x4x2vox"

echo $cmd
$cmd


fi

# Apply transformation

interp=NearestNeighbor

cmd="antsApplyTransforms -d 3 -o ${outFileName}                        \
                    --interpolation $interp                            \
                    -r ${fixed}                                        \
                    -i ${moving}                                       \
                    -t ${prefix}_${transform}_1Warp.nii.gz             \
                    -t ${prefix}_${transform}_0GenericAffine.mat -v"

echo $cmd
$cmd


#
#  De-Pad transform images
#




