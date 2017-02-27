#!/bin/bash
#
#


#echo
#echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo

grep calf  dcmConvertAll.cfg > dcmConvertAll_calf.cfg

sed  -e 's/calf//g'             \
     -e 's#nifti#nifti_calf#g'  \
     -e 's/T2Anatomy/t2w/'  \
     -e 's/T1MuscleComposition/t1w/'  \
     -e '/loc/d'                      \
     -e '/Loc/d'                      \
     -e '/Axial/d'                    \
     -e 's/baseline/pre/' \
     -e '0,/FatWaterTEEven/s/FatWaterTEEven/fw_even_mag/'     \
     -e '0,/FatWaterTEEven/s/FatWaterTEEven/fw_even_phase/'   \
     -e '0,/FatWaterTEOdd/s/FatWaterTEOdd/fw_odd_mag/'     \
     -e '0,/FatWaterTEOdd/s/FatWaterTEOdd/fw_odd_phase/'   \
     dcmConvertAll_calf.cfg > dcmConvert_calf1.cfg

awk '!seen[$4]++' dcmConvert_calf1.cfg > dcmConvert_calf.cfg

cat dcmConvert_calf.cfg
echo

rm -rf dcmConvert_calf1.cfg