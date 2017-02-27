#!/bin/bash

PIPELINE_NAME=n4Bias
PIPELINE_STAGE=01

inDir=${1-$PWD}
inFileName=${2-t2w.nii.gz}
inBaseFileName=$(basename ${inFileName} .nii.gz)

outDir="${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME}"
nIterations=${3-3};

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo
echo $(date)
echo $(whoami)
echo $(pwd)
echo
echo $inDir
echo "inFileName, " ${inFileName}
echo "inBaseFileName, " ${inBaseFileName}
echo "outDir, " ${outDir}
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


[ -d $outDir ] || mkdir -p $outDir

cp -f ${inDir}/${inBaseFileName}.nii.gz   ${outDir}/${inBaseFileName}_0.nii.gz

cd $outDir

#for ii in {0..$(($nIterations-1))}; do
iiMax=$(($nIterations-1))

for ii in $(seq  0 $iiMax ); do

cmd="N4BiasFieldCorrection -d 3 -i ${outDir}/${inBaseFileName}_${ii}.nii.gz  -o ${outDir}/${inBaseFileName}_$((ii+1)).nii.gz -r -s "

echo
echo $cmd
$cmd

done


#
# Copy last iteration to orignal filename.  I am using the directory to keep track of the process.
#

cp ${outDir}/${inBaseFileName}_$((ii+1)).nii.gz ${outDir}/${inBaseFileName}.nii.gz
