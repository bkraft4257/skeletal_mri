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
maskT2w=mask.t2w.nii.gz
labelsT2w=labels.t2w.nii.gz

m0ExistFlag=true
maskM0ExistFlag=true
maskMuscleExistFlag=true
freqBackgroundMaskExistFlag=true
phaseBackgroundMaskExistFlag=true
pwiExistFlag=true
t2wExistFlag=true
maskT2wExistFlag=true
labelsT2wExistFlag=true


[ -f $m0 ]              || m0ExistFlag=false;

[ -f $maskMuscle ]      || maskMuscleExistFlag=false;
[ -f $freqBackground  ] || freqBackgroundMaskExistFlag=false;
[ -f $phaseBackground ] || phaseBackgroundMaskExistFlag=false;
[ -f $pwi             ] || pwiExistFlag=false;

if [ ! -f $t2w             ]; then
    cp ../../../reorient/${t2w} .
    [ -f $t2w             ] || t2wExistFlag=false;
fi

if [ ! -f $maskT2w             ]; then
    iwCreateMask.sh ${t2w}
    [ -f $maskT2w         ] || maskT2wExistFlag=false;
fi

if [ ! -f $labelsT2w             ]; then
    cp ../../../label/muscle/input/*_seg.nii.gz $labelsT2w
    [ -f $labelsT2w         ] || labelsT2wExistFlag=false;
fi

if [ ! -f $maskM0       ]; then

    if [ -f ../01-maskM0/cl.$maskM0 ]; then
        cp ../01-maskM0/cl.$maskM0  $maskM0
    else
	[ -f ../01-maskM0/$maskM0 ] && cp ../01-maskM0/$maskM0  $maskM0
    fi

    [ -f $maskM0 ]          || maskM0ExistFlag=false;
fi


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

if [ $m0ExistFlag ] && [ $pwiExistFlag ] && [ $maskM0ExistFlag ] && [ false ]
then
    freeview $pwi $m0 ${maskM0}:colormap=jet:opacity=0.4 &
else
    printf "First QA test failed"
fi


if  [ $maskMuscleExistFlag ] && [ $t2wExistFlag ] && [ $maskT2wExistFlag ]
then

    freeview $t2w ${labelsT2w}:colormap=lut ${maskT2w}:colormap=jet:opacity=0.4 ${maskMuscle}:colormap=jet:opacity=0.4 &
else

    printf "Second QA Test failed"
fi