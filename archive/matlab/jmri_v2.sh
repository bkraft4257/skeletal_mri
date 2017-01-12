#!/bin/bash


in=${1}
prefix=${2}_${in}

cleanFlag=${3}

if [ $cleanFlag ]; then

    echo "Cleaning directory ... "
    rm -rf ${prefix}*.nii.gz
    rm -rf ${prefix}*.nii
fi

# Extract Thigh
#
#

cp ${in}.nii.gz ${prefix}.nii.gz

if [ ! -f ${prefix}_thigh.nii.gz ]; then

    echo "Extracting thigh"

    fslmaths    ${prefix}.nii.gz -thrp 25 -bin ${prefix}_tmp1.nii.gz
    ImageMath 3 ${prefix}_tmp2.nii.gz GetLargestComponent ${prefix}_tmp1.nii.gz

    ImageMath 3 ${prefix}_tmpmask.nii.gz FillHoles ${prefix}_tmp2.nii.gz

    fslmaths ${prefix} -mas ${prefix}_tmpmask.nii.gz ${prefix}_thigh.nii.gz
fi

#
# Apply bias correction
#

if  [ ! -f ${prefix}_sharpen.nii.gz ]; then
    
    echo "Apply bias correction and sharpen"
    
    N3BiasFieldCorrection 3 ${prefix}_thigh.nii.gz  ${prefix}_n3.nii.gz
    ImageMath 3 ${prefix}_sharpen.nii.gz Sharpen ${prefix}_n3.nii.gz
    ImageMath 3 ${prefix}_sharpen.nii.gz Normalize ${prefix}_sharpen.nii.gz

    cp ${prefix}_n3.nii.gz      ${in}_n3.nii.gz
    cp ${prefix}_sharpen.nii.gz ${in}_sharpen.nii.gz

fi


#
# Rough Classification, AT mask, and SM mask
#

if [ !  -f ${prefix}_otsu.nii.gz  ]; then

    echo "Otsu classification"

    nOtsu=2;

    ThresholdImage 3 ${prefix}_sharpen.nii.gz  ${prefix}_otsu${nOtsu}.nii.gz Otsu ${nOtsu}


fi

#
#
#
gunzip ${prefix}_n3.nii.gz  ${prefix}_sharpen.nii.gz  ${prefix}_otsu${nOtsu}.nii.gz