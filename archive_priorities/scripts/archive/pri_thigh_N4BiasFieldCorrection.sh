#!/bin/bash


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Iteration " $((ii+1))

echo
echo $(date)
echo $(whoami)
echo $(pwd)
echo
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

inputDir=${1}
outputDir=${1}/../01-n4Bias

mkdir -p ${outputDir}

cp ${inputDir}/t1w_36ms.nii.gz   ${outputDir}/t1w_36ms_n4_0.nii.gz


for ii in {0..4}; do

cmd="N4BiasFieldCorrection -d 3 -i ${outputDir}/t1w_36ms_n4_${ii}.nii.gz  -o ${outputDir}/t1w_36ms_n4_$((ii+1)).nii.gz -r -s "

echo $cmd
$cmd

done

