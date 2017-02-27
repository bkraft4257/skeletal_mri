#!/bin/bash
id=${1}
echo "ID", "fullPath"
find ${2} -name "*.nii" \( -name "r*.nii" -o -name "t2w.nii" \) | sed "s/^/${id},/g"
