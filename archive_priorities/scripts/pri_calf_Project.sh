#!/bin/bash

PIPELINE_NAME="project"
PIPELINE_STAGE="01"
extension=".nii.gz"

inDir=${1-$PWD}

inFileName=${2}
inBaseFileName=$( basename ${inFileName} ${extension} )

inCenterSlice=${3-2}

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

 
#
# Split Incoming Image along slice direction
#
#  fslsplit <input> [output_basename] [-t/x/y/z]

cp -f ${inDir}/${inFileName} ${outDir}/${inFileName}

cmd="fslsplit ${inDir}/${inFileName} ${outDir}/split.${inBaseFileName}. -z"
# echo $cmd
# echo
$cmd

#
# Project Slice across other slices
#

cd $outDir

for ii in split.${inBaseFileName}.[0-9][0-9][0-9][0-9].nii.gz; do 

    cmd="fslmaths ${ii} -mul 0 -add split.${inBaseFileName}.000${inCenterSlice} project.${ii}"
    echo $cmd
   $cmd
done

#
# fslmerge
#
# fslmerge <-x/y/z/t/a/tr> <output> <file1 file2 .......> [tr value in seconds]

fslmerge -z project.${inFileName} project.split.*.nii.gz

#
# Clean up directory
#

rm -f *split*
