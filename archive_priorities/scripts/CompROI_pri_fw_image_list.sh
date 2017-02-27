#!/bin/bash
id=${1}
echo "ID", "fullPath"
echo ${id}, ${2}/wOtsuN4_t2w_mask.nii 
echo ${id}, ${2}/fOtsuN4_t2w_mask.nii 
echo ${id}, ${2}/wOtsuN4_rt1w_mask.nii 
echo ${id}, ${2}/fOtsuN4_rt1w_mask.nii 
echo ${id}, ${2}/rfw1_gcFFAT.nii
echo ${id}, ${2}/rfw1_gcFH20.nii
echo ${id}, ${2}/msk_fatwater_tissue_s33_labels.nii

echo "ID", "fullPath"
echo ${id}, ${2}/wOtsuN4_t2w_mask.nii 
echo ${id}, ${2}/fOtsuN4_t2w_mask.nii 
echo ${id}, ${2}/wOtsuN4_rt1w_mask.nii 
echo ${id}, ${2}/fOtsuN4_rt1w_mask.nii 
echo ${id}, ${2}/rfw1_gcFFAT.nii
echo ${id}, ${2}/rfw1_gcFH20.nii
echo ${id}, ${2}/msk_fatwater_tissue_s24_labels.nii


#find ${2} -name "*.nii" \( -name "r*.nii" -o -name "t2w.nii" \) | sed "s/^/${id},/g"
