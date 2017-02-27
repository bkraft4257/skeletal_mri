#!/bin/bash

inDir=${1-$PWD}
inDir=$(readlink -f $inDir)

inMuscleLabels=${2}

outMuscleDir="${inDir}/../results"
[ -d ${outMuscleDir} ] || mkdir $outMuscleDir
outMuscleDir=$(readlink -f $outMuscleDir )

outMuscleLabels=muscleLabels.nii.gz

inErodeSigma=2

inReorientDir=${inDir}/reorient/

cp ${inDir}/$inMuscleLabels ${outMuscleDir}

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir,  "        $inDir
echo "inT2wLabels,   "        $inMuscleLabels
echo "inErodeSigma,  "        $inErodeSigma
echo
echo "outDir,  "        $outMuscleDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
#
#

cd ${outMuscleDir}



fslmaths $inMuscleLabels -mul 0 ${outMuscleLabels}

for ii in {1..9}; do 
     echo $ii; 


#     fslmaths $inMuscleLabels -thr $ii -uthr $ii -bin -kernel 2D  -ero  -mul ${ii}  ${ii}.muscles.nii.gz; 

      fslmaths $inMuscleLabels -thr $ii -uthr $ii -bin  label_${ii}.muscles.nii.gz; 
      ImageMath 3 label_${ii}.muscles.nii.gz ME label_${ii}.muscles.nii.gz ${inErodeSigma}

      fslmaths label_${ii}.muscles.nii.gz  -bin -mul ${ii} -add ${outMuscleLabels} ${outMuscleLabels}
done


rm -rf label_*.muscles.nii.gz

#
# Remove extra slices if necessary
#

nSlices=$(fslinfo muscleLabels.nii.gz | grep ^dim3 | awk '{print $2}')

if [ nSlices = 15 ]; then

    ImageMath 3 ${outMuscleLabels} PadImage ${outMuscleLabels} -5

fi