#!/bin/bash
id=${1}
fullPath=${2}

echo "ID", "fullPath"
echo ${id}, ${fullPath}/t2w_n4_atFraction.nii 
echo ${id}, ${fullPath}/t2w_n4_smFraction.nii 
echo ${id}, ${fullPath}/t2w_n4_chAutoLabels.nii 
echo ${id}, ${fullPath}/t2w_n4_chInnerLabels.nii 
echo ${id}, ${fullPath}/t2w_n4.nii 


#find ${2} -name "*.nii" \( -name "r*.nii" -o -name "t2w.nii" \) | sed "s/^/${id},/g"
