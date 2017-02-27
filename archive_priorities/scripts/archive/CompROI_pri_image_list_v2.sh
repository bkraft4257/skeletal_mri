#!/bin/bash
id=${1}
echo "ID", "fullPath"
find ${2} -name "*.nii" \( -name "*n4*.nii" -o \
                           -name "*labels.nii" -o \
                           -name "t2w.nii" \) | sed "s/^/${id},/g"
