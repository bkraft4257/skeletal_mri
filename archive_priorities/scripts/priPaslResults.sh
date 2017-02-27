#!/bin/bash

inSubjectDir=${1-$PWD}
inSubjectDir=$(readlink -f $inSubjectDir)

inReorientDir=${inSubjectDir}/reorient/

muscleMaskFileName=${inSubjectDir}/label/muscle/results/mask.muscle.nii.gz
muscleLabelsFileName=${inSubjectDir}/label/clinville/results/*_reorient_t2w_seg.nii.gz

m0=syn.m0_To_mask.muscle.nii.gz    # M0 image
maskM0=syn.mask.m0_To_mask.muscle.nii.gz

maskMuscle=mask.muscle.nii.gz
labelsMuscle=muscleLabels.nii.gz
                  
frequencyBackgroundMask=frequencyBackgroundMask.nii.gz
phaseBackgroundMask=phaseBackgroundMask.nii.gz

pwi=syn.pwi_To_mask.muscle.nii.gz
t2w=t2w.nii.gz
maskT2w=mask.t2w.nii.gz
labelsT2w=labels.t2w.nii.gz

m0ExistFlag=true
maskM0ExistFlag=true
maskMuscleExistFlag=true
frequencyBackgroundMaskExistFlag=true
phaseBackgroundMaskExistFlag=true
pwiExistFlag=true
t2wExistFlag=true
maskT2wExistFlag=true
labelsT2wExistFlag=true


[ -f $m0 ]                   || m0ExistFlag=false
[ -f $maskMuscle ]           || maskMuscleExistFlag=false;
[ -f $frequencyBackground  ] || frequencyBackgroundMaskExistFlag=false;
[ -f $phaseBackground ]      || phaseBackgroundMaskExistFlag=false;
[ -f $pwi             ]      || pwiExistFlag=false;


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $0
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inSubjectDir, "         $inSubjectDir
echo "inReorientDir, "        $inReorientDir
echo
printf "m0, %s, %s \n"         " $m0"     "$m0ExistFlag"
printf "maskM0, %s, %s \n"     " $maskM0" "$maskM0ExistFlag"
printf "maskMuscle, %s, %s \n" " $maskMuscle" "$maskMuscleExistFlag"
printf "pwi, %s, %s \n" "$pwi" " $pwiExistFlag"
printf "t2w, %s, %s \n" "$t2w" " $t2wExistFlag"
printf "maskT2w, %s, %s \n"     "$maskT2w" "$maskT2wExistFlag"
printf "labelsT2w, %s, %s \n"   "$labelsT2w" "$labelsT2wExistFlag"
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
# QA results. Measure background signal and muscle signal
#


rm    {1,2}.qa.results.csv    # Start with a fresh and empty copy of temporary qa.results.csv
touch {1,2}.qa.results.csv    # so that data can be appended to it



for ii in $pwi $m0; do
    
    echo $ii \
            "muscle"         $(fslstats $ii -k $maskM0  -R -M -S)                          \
            "frequency"      $(fslstats $ii -k $frequencyBackgroundMask -R  -M -S)         \
            "phase"          $(fslstats $ii -k $phaseBackgroundMask -R  -M -S)             \
            "abs(muscle)"    $(fslstats $ii -k $maskM0 -a -R -M -S)                     \
            "abs(frequency)" $(fslstats $ii -k $frequencyBackgroundMask -a -R  -M -S) \
            "abs(phase)"     $(fslstats $ii -k $phaseBackgroundMask -a  -R -M -S) > 1.qa.results.csv


#   echo $ii "muscle" $(fslstats $ii -k $maskM0 -R -M -S) \
#            "frequency" $(fslstats $ii -k $frequencyBackgroundMask -R -M -S) \
#            "phase" $(fslstats $ii -k $phaseBackgroundMask  -R -M -S) \
#            "abs(muscle)"  $(fslstats $ii -k $maskM0 -a -R -M -S) \
#            "abs(frequency)" $(fslstats $ii -k $frequencyBackgroundMask -a -R -M -S) \
#            "abs(phase)" $(fslstats $ii -k $phaseBackgroundMask -a -R -M -S)

done

echo "subjectID,visit,paslTime,type,region,m0_nV,pwi_nV,m0_std,pwi_std,m0_mean,pwi_mean" > qa.results.csv
cat  1.qa.results.csv >> qa.results.csv

echo
echo "From qa.results.csv"
echo
cat qa.results.csv
echo
echo

rm -rf [0-9].qa.results.csv


#
# Measure signal from individual muscles.
#

priPaslAnalyze_comproi.sh
