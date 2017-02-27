#!/bin/bash

PIPELINE_NAME="warpLabel"
PIPELINE_STAGE="03"
extension=".nii.gz"

inDir=${1-$PWD}

inFileName=${2}
inBaseFileName=$( basename ${inFileName} ${extension} )

inLabelsFileName=${3-manCalfLabels.nii.gz}
inLabelsBaseFileName=$( basename ${inLabelsFileName} ${extension} )

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
echo "inBaseFileName, " $inBaseFileName
echo "inCenterSlice, " $inCenterSlice
echo
echo "outDir, " $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

