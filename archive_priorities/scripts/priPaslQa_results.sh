#!/bin/bash

inDir=${1-$PWD}

muscleLUT=/cenc/other/msk/priorities/mriData/muscleLUT.txt

t2w=$(ls ${inDir}/*t2w.nii.gz)
muscleSeg=$(ls ${inDir}/*t2w_seg.nii.gz)
pwiColorMap="colormap=heat:heatscale=0,40,200:opacity=0.4"


cmd="freeview ${inDir}/m0.nii.gz ${inDir}/pwi.nii.gz:${pwiColorMap} $t2w  ${muscleSeg}:colormap=lut:opacity=0.1 --p-lut $muscleLUT    ${inDir}/mask.pwi.nii.gz:${pwiColorMap}" 

echo
echo $cmd
echo
 
$cmd