#!/bin/bash

#!/bin/bash

PIPELINE_NAME="padImage"
PIPELINE_STAGE="01"
extension=".nii.gz"

inDir=${1-$PWD}

inFileName=${2}
inBaseFileName=$( basename ${inFileName} ${extension} )

inPadImage=${3}

prefix=${inMovingT2wBaseFileName}To${inBaseFileName}

outDir="${4-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inFileName, " $inFileName
echo "inBaseFileName, " $inFixedBaseFileName
echo "inPadImage, " $inPadImage
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

fixed=pad.${inFileName}
moving=pad.${inMovingT2wFileName}

cmd="ImageMath 3 ${outDir}/${fixed}  PadImage ${inFileName}  $inPadImage"
echo $cmd
echo
$cmd

