#!/bin/bash
#
#

source ${IC_PATH}/scripts/dcm_functions.sh
 
inFileName="${1:-dcmConvertAll.cfg}"  # Input is dcmConvertAll.cfg or another file format
outFileName="${2:-dcmConvert_priorities.cfg}"

#echo $inFileName
#echo $outFileName

dcm_remove_localizers ${inFileName}        > ${outFileName}.step1
grep calf             ${outFileName}.step1 > ${outFileName}.step2
dcm_group             ${outFileName}.step2 > ${outFileName}.step3
grep 'rs01\|rs03'     ${outFileName}.step3 > ${outFileName}.step4

echo
echo "cat >>> ${outFileName}"
echo

sed  -e 's/calf//g'             \
     -e 's/nifti/nifti_calf/g'  \
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
     -e 's/UVApre/0/g'    \
     -e 's/UVApost//g'    \
     -e 's/_rs01//g'    \
     -e 's/rs03/pwi/g'    \
     -e 's/pasl0.nii/pasl_raw_0.nii/g'    \
     -e 's/pasl1.nii/pasl_raw_1.nii/g'    \
     -e 's/pasl2.nii/pasl_raw_2.nii/g'    \
     -e 's/pasl3.nii/pasl_raw_3.nii/g'    \
     -e 's/pasl0_pwi.nii/pasl_pwi_0.nii/g'    \
     -e 's/pasl1_pwi.nii/pasl_pwi_1.nii/g'    \
     -e 's/pasl2_pwi.nii/pasl_pwi_2.nii/g'    \
     -e 's/pasl3_pwi.nii/pasl_pwi_3.nii/g'    \
     ${outFileName}.step4 | tee ${outFileName}

echo

# Deletes repetitions
# awk '!seen[$4]++' ${outFileName}.step3 > ${outFileName}.step4

rm -rf ${outFileName}.step*