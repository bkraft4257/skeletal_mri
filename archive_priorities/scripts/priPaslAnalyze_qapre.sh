#!/bin/bash

inSubjectDir=${1-$PWD}
inSubjectDir=$(readlink -f $inSubjectDir)

inReorientDir=${inSubjectDir}/reorient/

muscleMaskFileName=${inSubjectDir}/label/muscle/results/mask.muscle.nii.gz
muscleLabelsFileName=${inSubjectDir}/label/clinville/results/*_reorient_t2w_seg.nii.gz

m0=m0.nii.gz    # M0 image
maskM0=mask.m0.nii.gz
maskMuscle=mask.muscle.nii.gz
freqBackgroundMask=freqQaPaslMask.nii.gz
phaseBackgroundMask=phaseQaPaslMask.nii.gz
pwi=pwi.nii.gz
t2w=t2w.nii.gz

m0ExistFlag=true
maskM0ExistFlag=true
maskMuscleExistFlag=true
freqBackgroundMaskExistFlag=true
phaseBackgroundMaskExistFlag=true
pwiExistFlag=true
t2wExistFlag=true

[ -f $m0 ]              || m0ExistFlag=false;
[ -f $maskM0 ]          || maskM0ExistFlag=false;
[ -f $maskMuscle ]      || maskMuscleExistFlag=false;
[ -f $freqBackground  ] || freqBackgroundMaskExistFlag=false;
[ -f $phaseBackground ] || phaseBackgroundMaskExistFlag=false;
[ -f $pwi             ] || pwiExistFlag=false;
[ -f $t2w             ] || t2wExistFlag=false;

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
printf "m0, %s, %s \n"         "$m0"     "$m0ExistFlag"
printf "maskM0, %s, %s \n"     "$maskM0" "$maskM0ExistFlag"
printf "muscleMask, %s, %s \n" "$muscleMask" "$muscleMaskExistFlag"
printf "pwi, %s, %s \n" "$pwi" "$pwiExistFlag"
printf "t2w, %s, %s \n" "$t2w" "$t2wExistFlag"
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

if [ $m0ExistFlag ] && [ $pwiExistFlag ] && [ $maskM0ExistFlag ] && [ false ]
then
    freeview $m0 $pwi ${maskM0}:colormap=jet:opacity=0.4 &
else
    printf "First QA test failed"
fi


if  [ $maskMuscleExistFlag ] && [ $t2wExistFlag ]
then

    freeview $t2w ${maskMuscle}:colormap=jet:opacity=0.4 &
else

    printf "Second QA Test failed"
fi