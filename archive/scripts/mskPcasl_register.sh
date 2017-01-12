
#!/bin/bash

#
#  The following script was created following the ANTS example script explain at http://stnava.github.io/fMRIANTs/
#

#in=${1}             # Generic Input File Name
#nVolumes=${2}        # Number of Volumes to process


inDir=$(readlink -f ${1-$PWD})
pcasl_raw=spwi_08.nii.gz

echo
echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo
echo "funcName:"     $FUNCNAME
echo "date:"         $(date)
echo "user:"         $(whoami)
echo "pwd: "         $(pwd)
echo "inDir:"        ${inDir}
echo
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> <<<IW "
echo


echo "####################################################################################################"
echo ">>>>> Read Header and dump out contents"
echo "####################################################################################################"
echo

#
#  Create a 4D target image for 4D deformable motion correction.    
#  First, parse the header info to find the number of time points.  

nVolumes=`PrintHeader ${pcasl_raw} | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
tr=`PrintHeader ${pcasl_raw} | grep "Voxel Spac" | cut -d ',' -f 4 | cut -d ']' -f 1`

echo "Number of Volumes = " $nVolumes
echo "TR                = " $tr
echo 


echo "####################################################################################################"
echo ">>>>> Collapse the transformations to a displacement field"
echo "####################################################################################################"
echo

#
# Use antsApplyTransforms to combine the displacement field and affine matrix into a single
# concatenated transformation stored as a displacement field.
#

echo
echo "-- Combine Transform displacement fields from T1 Native space to MNI space ------"
echo

affine=syn.m0_To_t2w.0GenericAffine.mat
warp=syn.m0_To_t2w.0Warp.nii.gz 
t2labels=labels.t2w.nii.gz

if [ ! -f affine.warp.nii.gz ]; then 
antsApplyTransforms -d 3 -o [ affine.warp.nii.gz ,1] \
                            -t ${warp}                                              \
                            -t ${affine}                                            \
                            -r ${t2labels} -v

fi

echo
echo "####################################################################################################"
echo ">>>>> Replicate the 3D template and 4D Displacement field"
echo "####################################################################################################"
echo 

if [ ! -f 4d.labels.t2w.nii.gz ]; then 
ImageMath 3 4d.labels.t2w.nii.gz  ReplicateImage labels.t2w.nii.gz $nVolumes $tr 0
fi

if [ ! -f 4d.affine.warp.nii.gz ]; then 
ImageMath 3 4d.affine.warp.nii.gz ReplicateDisplacement affine.warp.nii.gz $nVolumes $tr 0
fi

echo
echo "####################################################################################################"
echo ">>>>> Apply all the transformations to the original BOLD data."
echo "####################################################################################################"
echo 

antsApplyTransforms -d 4 -o warped.${pcasl_raw}             \
    -t 4d.affine.warp.nii.gz                                \
    -r 4d.labels.t2w.nii.gz -i  ${pcasl_raw}


 

