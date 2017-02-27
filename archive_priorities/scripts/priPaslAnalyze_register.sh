#!/bin/bash

inDir=${1-$PWD}
inDir=$(readlink -f $inDir)

inM0FileName=${2-m0.nii.gz}
inM0MaskFileName=${3-mask.m0.nii.gz}
inMuscleMaskFileName=${4-mask.muscle.nii.gz}
inPwiFileName=${5-pwi.nii.gz}
inT2wFileName=${6-t2w.nii.gz}
inT2wMaskFileName=${7-mask.t2w.nii.gz}
inT2wLabelsFileName=${8-labels.t2w.nii.gz}

extension=".nii.gz"

inMuscleMaskBaseFileName=$(basename $inMuscleMaskFileName $extension)


outDir=${inDir}"/../01-register/"
[ -d $outDir ] || mkdir $outDir
outDir=$( readlink -f ${outDir} )

resultsDir=${inDir}"/../results/"
[ -d $resultsDir ] || mkdir $resultsDir
resultsDir=$( readlink -f ${resultsDir} )

cp $inT2wFileName ${inT2wLabelsFileName} $inT2wMaskFileName $inMuscleMaskFileName ${resultsDir}
cp $inT2wFileName $inT2wMaskFileName $inMuscleMaskFileName ${outDir}

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inM0FileName, "           $inM0FileName
echo "inPwiFileName, "          $inPwiFileName
echo "inM0MaskFileName, "       $inM0MaskFileName
echo "inMuscleMaskFileName, "   $inMuscleMaskFileName
echo "inT2wFileName, "          $inT2wFileName
echo "inT2wMaskFileName, "      $inT2wMaskFileName
echo "inT2wLabelsFileName, "      $inT2wLabelsFileName
echo
echo "outDir, "     $outDir
echo "resultsDir, " $resultsDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

#
# Create Frequency and Phase Background Quality Masks
#

cd $outDir;

gunzip -f ${inT2wMaskFileName}  #Unzip files because Matlab code can only read NII files. 

niiT2wMaskFileName=$(basename $inT2wMaskFileName .gz)

matlab -nodisplay -nosplash -nodesktop -r "iwCreateFreqPhaseBackgroundMask('${niiT2wMaskFileName}',20); exit"

gzip -f *.nii

cp {phase,frequency}Background.${inT2wMaskFileName} $resultsDir


#
# Pad images for better registration
#

ImageMath 3 ${inM0MaskFileName}     PadImage   ${inDir}/${inM0MaskFileName} 2
ImageMath 3 ${inMuscleMaskFileName} PadImage   ${inDir}/${inMuscleMaskFileName} 2

#
# INIT registraiton parameters
#

DIM=3
FIXEDIMAGES=${inMuscleMaskFileName}
MOVINGIMAGES=${inM0MaskFileName}
OUTPUTNAME=output
NUMBEROFTHREADS=1
SPLINEDISTANCE=26
TRANSFORMTYPE='s'
PRECISIONTYPE='d'
CCRADIUS=32
PRECISION="--float 0"


#
# Translation only registration
#

OUTPUTNAME="maskM0_To_${inMuscleMaskBaseFileName}_translation_"

TRANSLATIONSTAGE="--initial-moving-transform [${FIXEDIMAGES},${MOVINGIMAGES},1] \
                  --transform TRANSLATION[0.1] \
                  --restrict-deformation     0x0x0x0x0x0x0x0x0x1x1x1                  \
                  --metric MI[${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1,32,Regular,0.25] \
                  --convergence $RIGIDCONVERGENCE \
                  --shrink-factors $RIGIDSHRINKFACTORS \
                  --smoothing-sigmas $RIGIDSMOOTHINGSIGMAS"

  COMMAND="antsRegistration -v --dimensionality $DIM $PRECISION \
                            --output [$OUTPUTNAME,${OUTPUTNAME}Warped.nii.gz,${OUTPUTNAME}InverseWarped.nii.gz] \
                            --interpolation Linear \
                            --use-histogram-matching ${USEHISTOGRAMMATCHING} \
                            --winsorize-image-intensities [0.005,0.995] \
                            $TRANSLATIONSTAGE"


echo $COMMAND
$COMMAND

#
# Apply Transforms to Muscle Mask
#


cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/$inM0MaskFileName  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_translation_0GenericAffine.mat          \
                            -o translation.mask.m0_To_${inMuscleMaskBaseFileName}.nii.gz \
                            -n MultiLabel"       

echo $cmd

$cmd



#
# Apply Transforms to Perfusion Weighted Image
#

cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/$inPwiFileName  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_translation_0GenericAffine.mat         \
                            -o translation.pwi_To_${inMuscleMaskBaseFileName}.nii.gz"       

echo $cmd

$cmd


#
# Apply Transforms to M0
#

cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/${inM0FileName}  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_translation_0GenericAffine.mat       \
                            -o translation.m0_To_${inMuscleMaskBaseFileName}.nii.gz"

echo $cmd

$cmd

cp       translation*.nii.gz         ${resultsDir}

#
# Register Masks. Only do the registration if the Warp Field is not present.
#

transform=sr

# if [ ! -f maskM0_To_${inMuscleMaskBaseFileName}_1Warp.nii.gz ]; then

   echo
   echo "Registering M0 mask to Muscle mask"
   echo 


  OUTPUTNAME="maskM0_To_${inMuscleMaskBaseFileName}_"

RIGIDSTAGE="--initial-moving-transform [${FIXEDIMAGES},${MOVINGIMAGES},1] \
            --transform RIGID[0.1] \
            --restrict-deformation     0x0x0x0x0x0x0x0x0x1x1x1                  \
            --metric MI[${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1,32,Regular,0.25] \
            --convergence $RIGIDCONVERGENCE \
            --shrink-factors $RIGIDSHRINKFACTORS \
            --smoothing-sigmas $RIGIDSMOOTHINGSIGMAS"

AFFINESTAGE="--transform Affine[0.1] \
             --metric MI[${FIXEDIMAGES},${MOVINGIMAGES},1,32,Regular,0.25] \
             --restrict-deformation      1x1x1x1x1x1x1x1x1x1x1x1                 \
             --convergence $AFFINECONVERGENCE \
             --shrink-factors $AFFINESHRINKFACTORS \
             --smoothing-sigmas $AFFINESMOOTHINGSIGMAS"

    SYNMETRICS="$SYNMETRICS --metric MI[${FIXEDIMAGES},${MOVINGIMAGES},1,${CCRADIUS}]"
    SYNCONVERGENCE="[400x300x200x100x100x100,1e-4,40]"
    SYNSHRINKFACTORS="16x8x6x4x2x1"
    SYNSMOOTHINGSIGMAS="16x8x4x2x1x0vox"
  
    SYNSTAGE="${SYNMETRICS} \
          --convergence $SYNCONVERGENCE \
          --shrink-factors $SYNSHRINKFACTORS \
          --smoothing-sigmas $SYNSMOOTHINGSIGMAS"

    SYNSTAGE="--transform SyN[0.1,3,0] $SYNSTAGE"

    STAGES="$RIGIDSTAGE $AFFINESTAGE $SYNSTAGE"

    COMMAND="antsRegistration --dimensionality $DIM $PRECISION \
                 --output [$OUTPUTNAME,${OUTPUTNAME}Warped.nii.gz,${OUTPUTNAME}InverseWarped.nii.gz] \
                 --interpolation Linear \
                 --use-histogram-matching ${USEHISTOGRAMMATCHING} \
                 --winsorize-image-intensities [0.005,0.995] \
                 $STAGES"
  

   echo 
   echo $COMMAND
   $COMMAND -v

# fi


#
# Apply Transforms to Perfusion Weighted Image
#

cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/$inM0FileName  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_1Warp.nii.gz               \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_0GenericAffine.mat         \
                            -o syn.m0_To_${inMuscleMaskBaseFileName}.nii.gz"       

echo $cmd
$cmd

#
# Apply Transforms to Muscle Mask
#


cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/$inPwiFileName  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_1Warp.nii.gz                \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_0GenericAffine.mat          \
                            -o syn.pwi_To_${inMuscleMaskBaseFileName}.nii.gz"       

echo $cmd
$cmd


#
# Apply Transforms to M0
#

cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/mask.${inM0FileName}  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_1Warp.nii.gz                \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_0GenericAffine.mat          \
                            -o syn.mask.m0_To_${inMuscleMaskBaseFileName}.nii.gz -n MultiLabel "     

echo $cmd
$cmd

#
# Copy images to results directory.
#

cp       syn*.nii.gz         ${resultsDir}

#
# List contents of results directory
#


cd ${resultsDir}

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME "COMPLETED"
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inM0FileName, "           $inM0FileName
echo "inPwiFileName, "           $inPwiFileName
echo "inMuscleMaskFileName, "   $inMuscleMaskFileName
echo
echo "outDir, "     $outDir
echo "resultsDir, " $resultsDir
echo

ls -l

echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
