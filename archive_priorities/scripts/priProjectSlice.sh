#!/bin/bash

PIPELINE_NAME="regSliceBySlice"
PIPELINE_STAGE="01"
extension=".nii.gz"

inDir=${1-$PWD}

inT2wFileName=${2-t2w.nii.gz}
inT2wBaseFileName=$( basename ${inT2wFileName} ${extension} )

inLabelsFileName=${3-manCalfLabels.nii.gz}
inLabelsBaseFileName=$( basename ${inLabelsFileName} ${extension} )

# inT1wFileName=t1w.nii.gz
# inT1wBaseFileName=$( basename ${inT1wFileName} ${extension} )

outDir="${3-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inT2wFileName, "        $inT2wFileName
echo "inT2wBaseFileName, "    $inT2wBaseFileName
echo "inLabelsFileName, "     $inLabelsFileName
echo "inLabelsBaseFileName, " $inLabelsBaseFileName
echo
echo "outDir, " $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

cp -f ${inDir}/${inT2wFileName}      ${outDir}/
cp -f ${inDir}/${inLabelsFileName}   ${outDir}/


cd $outDir

#
# Split image to individual slices
#

fslslice ${inT2wFileName}     ${inT2wBaseFileName} 
fslslice ${inLabelsFileName}  ${inLabelsBaseFileName}

#
#
#

t2wCenterSlice=${inT2wBaseFileName}_slice_0002.nii.gz
labelCenterSlice=${inLabelsBaseFileName}_slice_0002.nii.gz


if true; then

for ii in ${inT2wBaseFileName}_slice_0000.nii.gz ; do

    iiOutPrefix=$( basename ${ii} ${extension} )

    antsRegistration -d 2 -o ${iiOutPrefix}_                \
                 -m CC[ $t2wCenterSlice, $ii, 1, 4 ]        \
                 -t BSplineSyN[0.1,26]                      \
                 -c 200x100x50x25 -f 8x4x2x1                \
                 -s 4x2x1x0                                 \
                 --restrict-deformation -v     


    antsApplyTransforms -d 2 -o regT2w_$ii                    \
                         -r $ii                               \
 			 -i ${t2wCenterSlice}                 \
 			 -t ${iiOutPrefix}_1Warp.nii.gz  -v   \
                         -t ${iiOutPrefix}_0GenericAffine.mat

    antsApplyTransforms -d 2 -o regLabel_$ii                  \
                         -r $ii                               \
 			 -i ${labelCenterSlice}               \
                         -n MultiLabel                        \
 			 -t ${iiOutPrefix}_1Warp.nii.gz  -v   \
                         -t ${iiOutPrefix}_0GenericAffine.mat


done

fi

exit

#
# Merge Slices
#

fslmerge -z reg2D.step1.nii.gz  t2w*_Warped.nii.gz
ImageMath 3 reg2D.step1.nii.gz  SetTimeSpacing reg2D.step1.nii.gz 6

fslmerge -z labelReg2D.step1.nii.gz  label2D_t2w*.nii.gz
ImageMath 3 labelReg2D.step1.nii.gz  SetTimeSpacing labelReg2D.step1.nii.gz 6

#
# Translate back to original Image
#

antsRegistrationSyNQuick.sh -f ${inT2wFileName} -m reg2D.step1.nii.gz -o reg2D.step2. -t t

antsRegistrationSyNQuick.sh -f ${inT2wFileName} -m labelReg2D.step1.nii.gz -o labelReg2D.step2. -t t

exit

# Threshold mask
# fslmaths       ${inT1wFileName}   -thrp 35   -bin mask.step1.${inT1wFileName} 

echo "Create  tissue mask from ${inT2wFileName}"

ImageMath     3 mask.step1.${inT2wFileName} ThresholdAtMean ${inT2wFileName} 2
ImageMath     3 mask.step2.${inT2wFileName}  FillHoles mask.step1.${inT2wFileName}

# Closing operation.  Erode mask just a little bit more than dilation to tighten mask.

fslmaths       mask.step2.${inT2wFileName} -kernel boxv 5  -dilF -ero mask.step3.${inT2wFileName}

ImageMath      3 mask.step4.${inT2wFileName}  GetLargestComponent mask.step3.${inT2wFileName}

fslmaths       mask.step4.${inT2wFileName} -nan mask.${inT2wFileName}


#
# Find Perimeter of calf
#

echo "Find perimeter from mask"

fslmaths  mask.${inT2wFileName} -kernel boxv 3  -ero              perimeter.step1.${inT2wFileName}
fslmaths  mask.${inT2wFileName} -sub perimeter.step1.${inT2wFileName} perimeter.${inT2wFileName}


#
# 2 binary classification (1=fat, 0=everything else)
#

echo "Binary classification"

fslmaths     mask.${inT2wFileName} -mul ${inT2wFileName} otsu.step1.${inT2wFileName}

ThresholdImage 3 otsu.step1.${inT2wFileName}  otsu.step2.${inT2wFileName} Otsu 1

# Open operation
fslmaths       otsu.step2.${inT2wFileName} -kernel boxv 3    -ero   -dilF     otsu.step3.${inT2wFileName}
fslmaths       otsu.step3.${inT2wFileName} -add perimeter.${inT2wFileName}  -bin  otsu.step4.${inT2wFileName}

ImageMath      3 otsu.step5.${inT2wFileName}  GetLargestComponent otsu.step4.${inT2wFileName}


fslmaths       otsu.step5.${inT2wFileName} -kernel boxv 5  -dilF             otsu.step6.${inT2wFileName}

fslmaths       mask.${inT2wFileName}       -mul   otsu.step6.${inT2wFileName}       otsu.step7.${inT2wFileName}
fslmaths       otsu.step2.${inT2wFileName} -mul   otsu.step7.${inT2wFileName}       otsu.step8.${inT2wFileName}
fslmaths       otsu.step8.${inT2wFileName} -add   perimeter.${inT2wFileName}  -bin  otsu.${inT2wFileName}


#
# Close operation
#

ImageMath      3 subfat.step1.${inT2wFileName}  GetLargestComponent otsu.${inT2wFileName}
fslmaths       subfat.step1.${inT2wFileName} -kernel boxv 3    -dilF -ero  subfat2.${inT2wFileName}
fslmaths       subfat.step2.${inT2wFileName} -kernel boxv 3    -ero  -dilF subfat.${inT2wFileName}

#
# Remove Intermediate Steps
#

echo
# rm -rf *.step[0-9].*