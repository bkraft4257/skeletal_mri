#!/bin/bash


in=t2w
cleanFlag=false

if [ $cleanFlag ]; then
    rm -rf ${in}_*.nii.gz
fi

# Extract Thigh
#
#

if [ ! -f ${in}_thigh.nii.gz ]; then

    echo "Extracting thigh"

    fslmaths    ${in}.nii.gz -thrp 25 -bin ${in}_tmp1.nii.gz
    ImageMath 3 ${in}_tmp2.nii.gz GetLargestComponent ${in}_tmp1.nii.gz

    ImageMath 3 ${in}_tmpmask.nii.gz FillHoles ${in}_tmp2.nii.gz

    fslmaths ${in} -mas ${in}_tmpmask.nii.gz ${in}_thigh.nii.gz
fi

#
# Apply bias correction
#

if  [ ! -f ${in}_n3.nii.gz ]; then
    
    echo "Apply bias correction and sharpen"
    
    N3BiasFieldCorrection 3 ${in}_thigh.nii.gz  ${in}_n3.nii.gz
    ImageMath 3 ${in}_sharpen.nii.gz Sharpen ${in}_n3.nii.gz
    ImageMath 3 ${in}_sharpen.nii.gz Normalize ${in}_sharpen.nii.gz

fi

#
# Rough Classification, AT mask, and SM mask
#

if [ !  -f ${in}_c2.nii.gz  ]; then

    echo "Rough Classification"

    nOtsu=2;

    ThresholdImage 3 ${in}_sharpen.nii.gz  ${in}_${nOtsu}.nii.gz Otsu ${nOtsu}

    fslmaths  ${in}_otsu${nOtsu}.nii.gz -thr 2 -uthr 2 -bin  ${in}_tmp3a.nii.gz
    ImageMath 3 ${in}_at.nii.gz GetLargestComponent ${in}_tmp3a.nii.gz
    ImageMath 3 ${in}_atFilled.nii.gz FillHoles  ${in}_at.nii.gz .9


    fslmaths ${in}_${nOtsu}.nii.gz -thr 1 -uthr 1 -bin  ${in}_sm.nii.gz

fi


#
# Find background, foreground
#

if [ ! -f ${in}_foreground.nii.gz  ]; then

    echo "Find foreground and background"

    fslmaths ${in}_${nOtsu}.nii.gz -add 1 -uthr 1.9 ${in}_tmp4a.nii.gz
    ImageMath 3 ${in}_background.nii.gz GetLargestComponent ${in}_tmp4a.nii.gz
    fslmaths ${in}_background.nii.gz -binv ${in}_foreground.nii.gz
fi

# 
# Find Bone Cortex and Marrow
#

if [ ! -f ${in}_marrow.nii.gz  ]; then
   echo "Find bone cortex"

   fslmaths ${in}_foreground.nii.gz  -mul ${in}_tmp4a.nii.gz ${in}_tmp5a.nii.gz
   ImageMath 3 ${in}_tmp5b.nii.gz GetLargestComponent ${in}_tmp5a.nii.gz
   ImageMath 3 ${in}_tmp5c.nii.gz  MO ${in}_tmp5b.nii.gz .1
   ImageMath 3 ${in}_cortex.nii.gz MC ${in}_tmp5c.nii.gz .1

   ImageMath 3 ${in}_tmp5d.nii.gz FillHoles ${in}_cortex.nii.gz

   fslmaths ${in}_cortex.nii.gz -binv -mul ${in}_tmp5d.nii.gz ${in}_marrow.nii.gz
   fslmaths ${in}_cortex.nii.gz -add ${in}_marrow.nii.gz ${in}_bone.nii.gz

fi

exit 

# 
# Refine Skeletal Muscle
#

if [ ! -f ${in}_muscle.nii.gz  ]; then
   echo "Find muscle"

   fslmaths ${in}_atFilled.nii.gz -mul ${in}_sm.nii.gz ${in}_tmp6a.nii.gz
   fslmaths ${in}_bone.nii.gz -binv ${in}_tmp6b.nii.gz
   fslmaths ${in}_at.nii.gz -binv ${in}_tmp6c.nii.gz
   fslmaths ${in}_tmp6a.nii.gz -mul ${in}_tmp6b.nii.gz -mul ${in}_tmp6c.nii.gz ${in}_tmp6d.nii.gz

   ImageMath 3 ${in}_sm2.nii.gz FillHoles ${in}_tmp6d.nii.gz .6

   gunzip ${in}_sm2.nii.gz

fi
