#!/usr/bin/env bash

#import sys      
#import os                                               # system functions
#import glob
#import shutil
#import distutils

#import argparse
#import subprocess
#import _qa_utilities as qa_util
#import _utilities    as util
#import labels    

#import numpy        as np
#import nibabel      as nb
#import pandas       as pd
#import matplotlib.pyplot   as plt

# Replicate Reference Image

input_path=${1-$PWD}
methods_path=$(readlink -f $input_path/../methods )
labels_path=$(readlink -f $input_path/../../labels )

echo
echo $input_path
echo $methods_path
echo $labels_path
echo

tr=60
n_volumes=7

t2w=${labels_path}/t2w.nii.gz
t2w_4d=${methods_path}/t2w_4d.nii.gz

labels=${labels_path}/labels.muscle.nii.gz

m0=${methods_path}/m0.nii.gz
pwi=cummean.pwi.nii.gz
abspwi=cummean.abs.pwi.nii.gz

echo $t2w
echo $t2w_4d


#
# Apply Inverse Transform to T2w Label Image
#


if false; then 

cmd="antsApplyTransforms -d 3 -o ${methods_path}/t2w_iSyN_m0_3d__labels.muscle.nii.gz 
                     -t [ ${input_path}/maskM0_To_mask.muscle_0GenericAffine.mat , 1 ]
                     -t ${input_path}/maskM0_To_mask.muscle_1InverseWarp.nii.gz      
                     -i ${labels} 
                     -r $m0 -v -n Multilabel"

echo;echo; echo $cmd; $cmd; echo 

fi



if true; then

    fslmaths ${methods_path}/t2w_iSyN_m0_3d__labels.muscle.nii.gz -bin ${methods_path}/t2w_iSyN_m0_3d__mask.muscle.nii.gz
    m0_mean=$(fslstats ${methods_path}/m0.nii.gz -k ${methods_path}/t2w_iSyN_m0_3d__mask.muscle.nii.gz -M)

    echo $m0_mean

    fslmaths ${methods_path}/cummean.pwi.nii.gz     -div $m0_mean -mul 3000 ${methods_path}/cummean.mbf.nii.gz
    fslmaths ${methods_path}/cummean.abs.pwi.nii.gz -div $m0_mean -mul 3000 ${methods_path}/cummean.abs.mbf.nii.gz

    fslmaths   ${methods_path}/cummean.mbf.nii.gz -Zmean ${methods_path}/z.cummean.mbf.nii.gz
    fslmaths   ${methods_path}/cummean.abs.mbf.nii.gz -Zmean ${methods_path}/z.cummean.abs.mbf.nii.gz

fi


if true; then 
cd $methods_path

ln $t2w $methods_path
fslroi t2w.nii.gz z.t2w.nii.gz 0 -1 0 -1 3 1

for jj in mbf abs.mbf; do

    if true; then 

	echo "fslsplit"
	fslsplit cummean.${jj}.nii.gz _fslsplit_ -t

	if true; then
	    for ii in 0 1 2 3 4 5 6; do

		cmd="antsApplyTransforms -d 3 -o ${methods_path}/_t2w_SyN_m0_3d__fslsplit_000${ii}.nii.gz
                             -t ${input_path}/maskM0_To_mask.muscle_0GenericAffine.mat
                             -t ${input_path}/maskM0_To_mask.muscle_1Warp.nii.gz
                             -i _fslsplit_000${ii}.nii.gz
                             -r $t2w -v "

		echo;echo; echo $cmd; $cmd; echo 
	    done

	    fslmerge -t ${methods_path}/t2w_SyN_m0_3d__cummean.${jj}.nii.gz  ${methods_path}/_t2w_SyN_m0_3d__fslsplit_000*.gz

	    rm *_fslsplit_*
	fi
    fi

    fslmaths t2w_SyN_m0_3d__cummean.${jj}.nii.gz -Zmean z.t2w_SyN_m0_3d__cummean.${jj}.nii.gz

    cmd="fslcpgeom z.t2w.nii.gz z.t2w_SyN_m0_3d__cummean.${jj}.nii.gz -d"
    echo;echo; echo $cmd; $cmd; echo 
done

fi


exit



if false; then 

cmd="ImageMath 3 $t2w_4d ReplicateImage $t2w $n_volumes $tr 0"
echo;echo; echo $cmd; $cmd; echo



#
# Collapse transforms into single transform
#

cd $methods_path

cmd="antsApplyTransforms -d 3 -o [ m0_SyN_t2w_3d__Warp.nii.gz , 1 ]           
                     -t ${input_path}/maskM0_To_mask.muscle_1Warp.nii.gz      
                     -t ${input_path}/maskM0_To_mask.muscle_0GenericAffine.mat 
                     -r $t2w -v"

echo;echo; echo $cmd; $cmd; echo

cmd="ImageMath 3 m0_SyN_t2w_4d__Warp.nii.gz ReplicateDisplacement  m0_SyN_t2w_3d__Warp.nii.gz $n_volumes $tr 0"
echo;echo; echo $cmd; $cmd; echo


#
# Apply Transforms to Perfusion Weighted Image
#

cmd="antsApplyTransforms -v -d 4 -r ${t2w_4d} -i $pwi
                            -t  m0_SyN_t2w_4d__Warp.nii.gz
                            -o m0_SyN_t2w_$pwi -v "
echo;echo; echo $cmd; $cmd; echo

cmd="antsApplyTransforms -v -d 4 -r ${t2w_4d} -i $abspwi
                            -t m0_SyN_t2w_4d__Warp.nii.gz
                            -o m0_SyN_t2w_$abspwi -v "

echo;echo; echo $cmd; $cmd; echo 



fi