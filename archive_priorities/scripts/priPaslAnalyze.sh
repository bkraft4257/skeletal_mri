#!/bin/bash

inSubjectDir=${1-$PWD}
inSubjectDir=$(readlink -f $inSubjectDir)

inReorientDir=${inSubjectDir}/reorient/

muscleMaskFileName=${inSubjectDir}/label/muscle/results/mask.muscle.nii.gz
muscleLabelsFileName=${inSubjectDir}/label/clinville/results/*_reorient_t2w_seg.nii.gz


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inSubjectDir, "         $inSubjectDir
echo "inReorientDir, "        $inReorientDir
echo "muscleMaskFileName, "   $muscleMaskFileName
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
#
#

for ii in 0 1 2 3; do

   iiOutDir="${inSubjectDir}/pasl/${ii}/input"
   [ -d $iiOutDir ] || mkdir -p ${iiOutDir}
   iiOutDir=$(readlink -f ${iiOutDir})

   iiResultsDir="${inSubjectDir}/pasl/${ii}/results"
   [ -d $iiResultsDir ] || mkdir -p ${iiResultsDir}
   iiResultsDir=$(readlink -f ${iiResultsDir})

   echo "======================================="
   echo "Time Point, " ${ii} 
   echo "iiOutDir, " ${iiOutDir}

   cd ${iiOutDir}

   pwd

   ls

   echo 

   priPaslRegisterM0.sh &

done

