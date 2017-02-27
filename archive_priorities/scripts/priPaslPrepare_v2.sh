#!/bin/bash

inSubjectDir=${1-$PWD}
inSubjectDir=$(readlink -f $inSubjectDir)

inReorientDir=${inSubjectDir}/reorient/
paslDir=${inSubjectDir}/pasl/

muscleLabelDir=${inSubjectDir}/label/muscle/results
muscleLabelFileName=muscleLabels.nii.gz

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inSubjectDir, "         $inSubjectDir
echo "inReorientDir, "        $inReorientDir
echo "inMuscleLabelDir, "        $muscleLabelDir
echo "muscleLabelFileName, "   $muscleLabelFileName
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
# Copy images to the correct time point in the pasl directory.
#

paslLabelDir=${paslDir}/labels
chmod +w -R ${paslLabelDir}
rm -rf ${paslLabelDir}
    
[ -d ${paslLabelDir} ] || cp -rf  ${muscleLabelDir} ${paslLabelDir}

for ii in 0 1 2 3; do

   # Copy data to input directory 

   iiInputDir="${paslDir}/${ii}/input"
   [ -d $iiInputDir ] || mkdir -p ${iiInputDir}
   iiInputDir=$(readlink -f ${iiInputDir})

   # Create results directory

   iiResultsDir="${inSubjectDir}/pasl/${ii}/results"
   [ -d $iiResultsDir ] || mkdir -p ${iiResultsDir}
   iiResultsDir=$(readlink -f ${iiResultsDir})

   # Link files into results directory for measuring ROIs.

   ln -f ${inReorientDir}/t2w.nii.gz  ${iiResultsDir}
   cmd="ln -f ${paslDir}/labels/${muscleLabelFileName}      ${iiResultsDir}"
   $cmd

   echo "======================================="
   echo "Time Point, " ${ii} 
   echo "iiInputDir, " ${iiInputDir}

#  The PWI image when it is stored as a DICOM image has a range of 0-4095. 
#  Therefore it is necessary to subtract 2048 from each image. I also mask the image around the 

#   if [ -f ${inReorientDir}/pasl_pwi_${ii}.nii.gz ]; then
       fslmaths ${inReorientDir}/pasl_pwi_${ii}.nii.gz -sub 2048 ${iiInputDir}/pwi.nii.gz
#   fi

#   if [ -f ${inReorientDir}/pasl_raw_${ii}.nii.gz ]; then
      fslroi ${inReorientDir}/pasl_raw_${ii}.nii.gz  ${iiInputDir}/m0.nii.gz   0 1   
#   fi

   cd ${iiInputDir}

   pwd

   ls

   echo 

done

