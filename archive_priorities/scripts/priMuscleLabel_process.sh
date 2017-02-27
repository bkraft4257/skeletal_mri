#!/bin/bash

inDir=${1-$PWD}
inDir=$( readlink -f ${inDir} )

inMuscleLabels=${2-$(ls *reorient_t2w_seg.nii.gz)}
inMC=${3-13}
inME=${4-2}
inPadImage=${5-"0"}


outDir=${inDir}/../01-segment
[ -d $outDir ] || mkdir $outDir
outDir=$( readlink -f ${outDir} )


resultsDir=${inDir}/../results
[ -d $resultsDir ] || mkdir $resultsDir
resultsDir=$( readlink -f ${resultsDir} )

cmd="cp ${inDir}/* ${resultsDir}"
$cmd

outMuscleLabels=labels.muscle.nii.gz

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inLabelImage, " $inMuscleLabels
echo "inMC, "         $inMC
echo "inME, "         $inME
echo "inPadImage, "   $inPadImage
echo
echo "outDir, " $outDir
echo "resultsDir, " $resultsDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

cd $outDir;

fslmaths ${inDir}/${inMuscleLabels} -bin 1.muscle.${inMuscleLabels}

ImageMath 3 2.muscle.${inMuscleLabels}  MC                  1.muscle.${inMuscleLabels} $inMC
ImageMath 3 3.muscle.${inMuscleLabels}  GetLargestComponent 2.muscle.${inMuscleLabels}
ImageMath 3 4.muscle.${inMuscleLabels}  FillHoles           3.muscle.${inMuscleLabels}
ImageMath 3 5.muscle.${inMuscleLabels}  ME                  4.muscle.${inMuscleLabels} $inME

if [ ${inPadImage}  -ne 0 ]; then
    ImageMath 3   mask.muscle.nii.gz      PadImage          5.muscle.${inMuscleLabels} $inPadImage
else
    mv 5.muscle.${inMuscleLabels} mask.muscle.nii.gz
fi

# rm -rf [1-9].muscle.${inMuscleLabels}

#
#  Create hard link to results directory
#

cp -f ${outDir}/mask.muscle.nii.gz ${resultsDir}/mask.muscle.nii.gz




#
# Erode Muscle Mask
#

cd ${outDir}

fslmaths ${inDir}/$inMuscleLabels -mul 0 ${outMuscleLabels}

for ii in {1..10}; do 
     echo $ii; 


#     fslmaths $inMuscleLabels -thr $ii -uthr $ii -bin -kernel 2D  -ero  -mul ${ii}  ${ii}.muscles.nii.gz; 

      fslmaths ${inDir}/$inMuscleLabels -thr $ii -uthr $ii -bin  label_${ii}.muscles.nii.gz; 
      ImageMath 3 label_${ii}.muscles.nii.gz ME label_${ii}.muscles.nii.gz ${inErodeSigma}

      fslmaths label_${ii}.muscles.nii.gz  -bin -mul ${ii} -add ${outMuscleLabels} ${outMuscleLabels}
done


# rm -rf label_*.muscles.nii.gz

#
# Remove extra slices if necessary
#

nSlices=$(fslinfo ${inDir}/${inMuscleLabels} | grep ^dim3 | awk '{print $2}')

if [ ${nSlices}  -eq 15 ]; then

    ImageMath 3 ${outMuscleLabels} PadImage ${outMuscleLabels} -5

fi

cp -f ${outDir}/${outMuscleLabels} ${resultsDir}