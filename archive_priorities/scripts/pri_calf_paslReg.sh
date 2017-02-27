#!/bin/bash

PIPELINE_NAME="paslReg"
PIPELINE_STAGE="01"
extension=".nii.gz"

inDir=${1-$PWD}

inT1wFileName=${2-t1w.nii.gz}
inT1wBaseFileName=$( basename ${inT1wFileName} ${extension} )

outDir="${3-${inDir}/../${PIPELINE_STAGE}-${PIPELINE_NAME} }"

[ -d $outDir ] || mkdir -p $outDir
outDir=$(readlink -f ${outDir})

outDirSyN="${inDir}/../02-antsRegSyn"
outDirSyN=$(readlink -f ${outDirSyN})

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir,                " $inDir
echo "inT1wFileName,        " $inT1wFileName
echo "inT1wBaseFileName,    " $inT1wBaseFileName
echo
echo "outDir, "      $outDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

inLabelsFileName=calfLabels.nii.gz
smMaskFileName=smMask.nii.gz
calfLabelNumber=2

m0FileName=m0.nii.gz
pwiFileName=pwi.nii.gz

#
# Mask out T1w Skeletal Muscle
#

cp ${m0FileName} ${inLabelsFileName} ${inT1wFileName} ${outDir}/

cd ${outDir}

smT1wFileName=muscle.${inT1wFileName}

# Mask t1w image 
fslmaths ${inLabelsFileName} -thr $calfLabelNumber -uthr $calfLabelNumber -bin ${smMaskFileName}
fslmaths ${inT1wFileName} -mul ${smMaskFileName} ${smT1wFileName}


fslmaths ${m0FileName} -thrp 40 -bin ${outDir}/step1.${m0FileName}

ImageMath 3 step2.${m0FileName} GetLargestComponent  step1.$m0FileName
ImageMath 3 mask.${m0FileName} FillHoles             step2.$m0FileName 2

fslmaths ${m0FileName} -mul mask.${m0FileName} ${m0FileName}

rm -rf step*.${m0FileName};


#
# Register perfusion to T1w Skeletal Muscle
#

N4BiasFieldCorrection -d 3 -i ${m0FileName} -s -o ${m0FileName}

msk_calf_paslRegister3DSyN.sh ${outDir} ${smT1wFileName} ${m0FileName} ${outDirSyN}

#
# Apply Transformation to pwi Image
#

outFileName=${outDir}/reg.${pwiBaseFileName}${extension}
interp=HammingWindowedSinc

cmd="antsApplyTransforms -d 3 -o ${outFileName}                        \
                         --interpolation $interp                       \
                    	 -r ${inT1wFileName}                                \
                    	 -i ${inDir}${pwiFileName}                          \
                    	 -t ${prefix}_SyN_1Warp.nii.gz                      \
                    	 -t ${prefix}_SyN_0GenericAffine.mat -v"


