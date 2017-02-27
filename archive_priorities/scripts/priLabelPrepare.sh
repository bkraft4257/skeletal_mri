#!/bin/bash
refTimePoint=${1-1}
timePoint=${2-2}

inputDir="./clinville/results"

[ -d $inputDir ] ||  mkdir -p $inputDir

if  [ ! -d ./clinville/input ]; then 

mkdir -p ${inputDir}

cd ${inputDir}

cp ../../../../${refTimePoint}/label/clinville/results/${refTimePoint}* .
cp ../../../../register/results/${timePoint}*SyN_* .
cp ../../../reorient/t2w.nii.gz ${timePoint}_reorient_t2w.nii.gz

rename wTo${refTimePoint} w_To_${refTimePoint} *

else

cd ${inputDir}

fi


# T2w Reference Point transformed to Time Point

if true; then

antsApplyTransforms -d 3  -v  \
-i ${refTimePoint}_reorient_t2w.nii.gz \
-r  ${timePoint}_reorient_t2w.nii.gz  \
-o ../results/r${refTimePoint}_t${timePoint}_reorient_t2w.nii.gz \
-t [ ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_0GenericAffine.mat , 1]  \
-t   ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_1InverseWarp.nii.gz  

antsApplyTransforms -d 3  -v  -n MultiLabel \
-i ${refTimePoint}_reorient_t2w_seg.nii.gz \
-r  ${timePoint}_reorient_t2w.nii.gz  \
-o ../results/r${refTimePoint}_t${timePoint}_reorient_t2w_seg.nii.gz \
-t [ ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_0GenericAffine.mat , 1]  \
-t   ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_1InverseWarp.nii.gz  

fi



# T2w Time Point transformed to Reference Point 

if false; then

cp ../../../../${refTimePoint}/label/clinville/results/${refTimePoint}_reorient_t2w* .
cp ${refTimePoint}_reorient_t2w.nii.gz ${refTimePoint}_reorient_t2w_seg.nii.gz ../results

antsApplyTransforms -d 3  -v  -n MultiLabel \
-i ${timePoint}_reorient_t2w_seg.nii.gz \
-r ${refTimePoint}_reorient_t2w.nii.gz  \
-o ../results/t${timePoint}_r${refTimePoint}_reorient_t2w_seg.nii.gz \
-t   ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_1Warp.nii.gz  \
-t   ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_0GenericAffine.mat 

fi



# T2w Time Point transformed to Reference Point

if false; then
antsApplyTransforms -d 3  -v  -n MultiLabel \
-i   ${timePoint}_reorient_t2w.nii.gz   \
-r  ${refTimePoint}_reorient_t2w.nii.gz  \
-o ../results/${timePoint}_${refTimePoint}_reorient_t2w.nii.gz \
-t   ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_1Warp.nii.gz \
-t   ${timePoint}_reorient_t2w_To_${refTimePoint}_reorient_t2w_SyN_0GenericAffine.mat 
fi

cd ../results
cp ../../../reorient/t2w.nii.gz  ${timePoint}_reorient_t2w.nii.gz