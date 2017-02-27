#!/bin/bash

inSubjectDir=${1-$PWD}
inSubjectDir=$(readlink -f $inSubjectDir)

inMuscleLabels=${2}
outMuscleLabels=muscleLabels.nii.gz
inErodeSigma=5

inReorientDir=${inSubjectDir}/reorient/

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inSubjectDir, "         $inSubjectDir
echo "inReorientDir, "        $inReorientDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
#
#
#  0  "Clear Label"
#  1  "Gastrocnemius m. (medial head)"
#  2  "Gastrocnemius m. (lateral head)"
#  3  "Soleus m."
#  4  "Peroneus brevis and longus mm."
#  5  "Tibialis anterior m"
#  6  "Tibialis posterior m."
#  7  "Fibia"
#  8  "Extensor digitorum longus and extensor hallucis longus mm"
#  9  "Label 9"


fslmaths $inMuscleLabels -mul 0 ${outMuscleLabels} 

for ii in {1..9}; do 
    echo $ii; 
    fslmaths $inMuscleLabels -thr $ii -uthr $ii -bin -kernel boxv $inErodeSigma -ero  -mul ${ii}  ${ii}.muscles.nii.gz; 
    fslmaths ${ii}.muscles.nii.gz -mul ${ii} -add ${outMuscleLabels} ${outMuscleLabels}
done


#
#
#

