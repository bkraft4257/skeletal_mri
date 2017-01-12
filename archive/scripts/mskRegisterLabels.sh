#!/bin/bash

#!/bin/bash

PIPELINE_NAME="antsRegSyn"
PIPELINE_STAGE="01"
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

#
# Calculating Deformation Field along X and Y
#
its=1e-5
transform=SyN
outFileName=${prefix}_${transform}${extension}

if [ ! -f ${prefix}_${transform}_0Warp.nii.gz ]; then

cmd="antsRegistration -d 3 -v -o ${prefix}_${transform}_                            \
                 --restrict-deformation     1x1x0                                   \
                 --metric      	    	    CC[ ${fixed}, ${moving}, 1, 4 ]         \
                 --transform   	    	    $transform[0.1, 26]                     \
                 --convergence 	    	    [ 200x200x200x100x50, $its, 10 ]        \
                 --shrink-factors   	    16x8x4x2x1                              \
                 --smoothing-sigmas 	    8x4x2x1x0vox"

echo $cmd
$cmd


fi

# Apply transformation

interp=NearestNeighbor

cmd="antsApplyTransforms -d 3 -o ${outFileName}                        \
                    --interpolation $interp                            \
                    -r ${fixed}                                        \
                    -i ${moving}                                       \
                    -t ${prefix}_${transform}_0Warp.nii.gz"

echo $cmd
$cmd


#
#  De-Pad transform images
#




