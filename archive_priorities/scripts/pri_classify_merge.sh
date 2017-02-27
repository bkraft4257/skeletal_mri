#!/bin/bash
mkdir segment
mv * segment 
mkdir class1
cd class1

echo
pwd
echo

ln ../segment/t2w_n4_atLCC.nii  t2w_n4_atLCC.nii 
cp /kitzman/SECRET-I_BT/segment/${1}_t2w_n4* .
rename ${1}_ '' *

msk_classify_thigh.sh t2w_n4 t2w_n4_chLabels t2w_n4_atLCC

echo