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


subjectID=$(echo $inDir | grep -o "pri[0-1][0-9]_[a-z][a-z][a-z][a-z][a-z]")
visit=$(echo -n $inDir | grep -o "pri[0-1][0-9]_[a-z][a-z][a-z][a-z][a-z]\/[1-3]" | grep -o "[0-9]$" )
paslAcquisition=$(echo $inDir | grep -o "pasl\/[0-3]\/results" | grep -o "[0-3]" )

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, "    	$inDir
echo "muscleLabels",    $muscleLabels
echo "subjectID," 	$subjectID
echo "visit,"           $visit
echo "paslAcquisition," $paslAcquisition
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
# QA results. Measure background signal and muscle signal
#


echo "image,subjectID,visit,paslTime,type,region,nVoxels,volume,min,max,mean,std,abs(min),abs(max),abs(mean),abs(std)" > qa.results.csv

for ii in $pwi $m0; do
    for jj in $maskM0 $frequencyBackgroundMask $phaseBackgroundMask; do
 
    echo $subjectID $visit $paslAcqusition $ii $jj \
            $(fslstats $ii -k $jj  -V -R -M -S)    \
            $(fslstats $ii -k $jj  -a -R -M -S)    >> qa.results.csv

done
done

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
k