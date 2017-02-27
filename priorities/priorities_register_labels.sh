
#!/bin/bash

#
#  The following script was created following the ANTS example script explain at http://stnava.github.io/fMRIANTs/
#

#in=${1}             # Generic Input File Name
#nVolumes=${2}        # Number of Volumes to process


inDir=$(readlink -f ${1-$PWD})
subjectID=$( echo ${inDir}  | grep -o 'inf0[12][0-9][0-9][f|b]' )


# Create Output Directory
#

outDir="${inDir}/../02-output"

[ -d $outDir ] || mkdir -p ${outDir}

outDir=$(readlink -f ${outDir})

#
# Create Results Directory
#
resultsDir="${inDir}/../results"
[ -d $resultsDir ] || mkdir -p ${resultsDir}

resultsDir=$(readlink -f ${resultsDir})

echo
echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo
echo "funcName:"     $FUNCNAME
echo "date:"         $(date)
echo "user:"         $(whoami)
echo "subjectID:"    $(subjectID)
echo "pwd: "         $(pwd)
echo "inDir:"        ${inDir}
echo "outDir:"       ${outDir}
echo "resultsDir:"   ${resultsDir}
echo
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> <<<IW "
echo


#
# Hard link input files and links to output directory. This allows easy access
#

for ii in $( ls ${inDir}); do ln -sf ${inDir}/$ii ${outDir}/$ii; done

cd ${outDir}

echo "Analyzing bold2Mni for ${subjectID}"

ext='.nii.gz'

inPrefix=bold2Mni
mniReference=${inPrefix}_mniLowResTemplate.nii.gz

gmLabelThreshold=0.8;
wmLabelThreshold=0.8;
csfLabelThreshold=0.9;

fmri=fmri.nii.gz

prefix=bold2Mni

avgFmri=${prefix}_avg.nii.gz
fxd=${prefix}_fixed.nii.gz

t1Native=T1w_brain.nii.gz               # Native Brain Image 

t1Gm=T1w_brain_gm.nii.gz               # Native Brain Image 
t1GmCortical=T1w_brain_gm_cortical.nii.gz               # Native Brain Image 
t1GmSubcortical=T1w_brain_gm_subcortical.nii.gz               # Native Brain Image 

# Add Cortical and Subcortical GM structures together
fslmaths ${t1GmCortical} -add ${t1GmSubcortical} ${t1Gm}


t1Wm=T1w_brain_wm.nii.gz               # Native Brain Image 
t1Csf=T1w_brain_csf.nii.gz               # Native Brain Image 
t1Mask=T1w_brain_mask.nii.gz


t1GroupTemplate=${inPrefix}_t1GroupTemplate.nii.gz                         # Group Template Image for Infinite Study
                    
native2GtGenericMat=T1w_native2Template_0GenericAffine.mat 
native2GtWarp=T1w_native2Template_1Warp.nii.gz 

mniTemplate=${inPrefix}_mniHighResTemplate.nii.gz


#if [ $# -eq 3 ]; then
#    mniReference=$3
#else
#    mniReference=${inPrefix}_mniLowResTemplate.nii.gz
#fi


gt2MniGenericMat=${inPrefix}_mni_0GenericAffine.mat
gt2MniWarp=${inPrefix}_mni_1Warp.nii.gz

echo
echo "#####################################################################################################"
echo ">>>>> Display Information about BOLD fMRI data file"
echo "#####################################################################################################"

echo

echo ${fmri}
echo

fslinfo ${fmri}
echo 


if [ ! -f ${avgFmri} ]; then
echo "#####################################################################################################"
echo ">>>>> Create a target (average) image"
echo "#####################################################################################################"
echo

 antsMotionCorr -d 3 -a ${fmri} -o ${avgFmri}

fi


if [ ! -f ${prefix}_${fmri} ] ; then
echo "#####################################################################################################"
echo ">>>>> Mask Bold Image"
echo "#####################################################################################################"
echo

antsApplyTransforms -d 3 -r ${avgFmri} -i ${t1Mask} -o ${prefix}_bold_${t1Mask} -t identity

fslmaths ${prefix}_bold_${t1Mask} -bin -mul ${fmri} ${prefix}_masked_${fmri}

fi

maskFmri=${prefix}_masked_${fmri}


echo "####################################################################################################"
echo ">>>>> Read Header and dump out contents"
echo "####################################################################################################"
echo

#
#  Create a 4D target image for 4D deformable motion correction.    
#  First, parse the header info to find the number of time points.  

nVolumes=`PrintHeader ${maskFmri} | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
tr=`PrintHeader ${maskFmri} | grep "Voxel Spac" | cut -d ',' -f 4 | cut -d ']' -f 1`

echo "Number of Volumes = " $nVolumes
echo "TR                = " $tr
echo 




if [ ! -f  ${prefix}_avg.nii.gz ]; then
echo "####################################################################################################"
echo ">>>>> Replicate the fixed 3D image nVolumes times to make a new 4D fixed image"
echo "####################################################################################################"
echo 


ImageMath 3 $fxd ReplicateImage ${prefix}_avg.nii.gz $nVolumes $tr 0


fi




if [ ! -f ${prefix}_native2mni_mask.nii.gz ]; then
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

 antsApplyTransforms -d 3 -o [${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz,1] \
                     -t ${gt2MniWarp}                                  \
                     -t ${gt2MniGenericMat}                            \
                     -t ${native2GtWarp}                               \
                     -t ${native2GtGenericMat}                         \
                     -r $mniReference -v

antsApplyTransforms -d 3 -o ${prefix}_native2mni.nii.gz       -r ${mniReference} -i ${t1Native} 	-t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz
antsApplyTransforms -d 3 -o ${prefix}_native2mni_gm.nii.gz    -r ${mniReference} -i ${t1Gm}     	-t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz
antsApplyTransforms -d 3 -o ${prefix}_native2mni_gmc.nii.gz   -r ${mniReference} -i ${t1GmCortical}     -t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz
antsApplyTransforms -d 3 -o ${prefix}_native2mni_gmsc.nii.gz  -r ${mniReference} -i ${t1GmSubcortical}  -t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz
antsApplyTransforms -d 3 -o ${prefix}_native2mni_wm.nii.gz    -r ${mniReference} -i ${t1Wm}     	-t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz
antsApplyTransforms -d 3 -o ${prefix}_native2mni_csf.nii.gz   -r ${mniReference} -i ${t1Csf}    	-t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz
antsApplyTransforms -d 3 -o ${prefix}_native2mni_mask.nii.gz  -r ${mniReference} -i ${t1Mask}   	-t ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz

fi



if [ ! -f  ${prefix}_bold2MniTemplateDiff4DCollapsedWarp.nii.gz  ]; then
echo
echo "####################################################################################################"
echo ">>>>> Replicate the 3D template and 4D Displacement field"
echo "####################################################################################################"
echo 

ImageMath 3 ${prefix}_mniReference4D.nii.gz  ReplicateImage $mniReference     $nVolumes $tr 0


ImageMath 3 ${prefix}_bold2MniTemplateDiff4DCollapsedWarp.nii.gz ReplicateDisplacement \
 ${prefix}_bold2MniTemplateDiffCollapsedWarp.nii.gz $nVolumes $tr 0

fi



if [ ! -f ${prefix}_fmri_mask.nii.gz ]; then
   echo
   echo "####################################################################################################"
   echo ">>>>> Apply all the transformations to the original BOLD data."
   echo "####################################################################################################"
   echo 

     antsApplyTransforms -d 4 -o ${prefix}_fmri.nii.gz \
                         -t ${prefix}_bold2MniTemplateDiff4DCollapsedWarp.nii.gz \
                         -r ${prefix}_mniReference4D.nii.gz -i ${maskFmri}


   fslmaths ${prefix}_fmri.nii.gz      -Tmean ${prefix}_fmri_mean.nii.gz
   fslmaths ${prefix}_fmri_mean.nii.gz -bin   ${prefix}_fmri_mask.nii.gz
      
fi
 

if [ ! -f ${prefix}_native2mni_labels.nii.gz ]; then

   echo "####################################################################################################"
   echo ">>>> Applying transforms to brain labels"
   echo "####################################################################################################"
   echo 


   # Threshold each tissue type to create GM, WM, and CSF tissue mask

   gmLabelNumber=1;
   wmLabelNumber=2;
   csfLabelNumber=3;

   fslmaths ${prefix}_native2mni_gm.nii.gz   -thr ${gmLabelThreshold}  -bin -mul $gmLabelNumber  ${prefix}_native2mni_gm_mask.nii.gz 
   fslmaths ${prefix}_native2mni_gmc.nii.gz  -thr ${gmLabelThreshold}  -bin -mul $gmLabelNumber  ${prefix}_native2mni_gmc_mask.nii.gz 
   fslmaths ${prefix}_native2mni_gmsc.nii.gz -thr ${gmLabelThreshold}  -bin -mul $gmLabelNumber  ${prefix}_native2mni_gmsc_mask.nii.gz 
   fslmaths ${prefix}_native2mni_wm.nii.gz   -thr ${wmLabelThreshold}  -bin -mul $wmLabelNumber  ${prefix}_native2mni_wm_mask.nii.gz 
   fslmaths ${prefix}_native2mni_csf.nii.gz  -thr ${csfLabelThreshold} -bin -mul $csfLabelNumber ${prefix}_native2mni_csf_mask.nii.gz

   # Combine tissue masks to create a label image.
   fslmaths ${prefix}_native2mni_gm_mask.nii.gz -add ${prefix}_native2mni_wm_mask.nii.gz -add \
            ${prefix}_native2mni_csf_mask.nii.gz -mas ${prefix}_fmri_mask.nii.gz          \
            ${prefix}_native2mni_labels.nii.gz

      
fi

#
# Touch important output so it is last is a ls -lrt 
#

touch ${prefix}_fmri.nii.gz

#
# Gather important file into results dir
#

lnFiles="${prefix}_fmri.nii.gz                ${prefix}_native2mni_gm_mask.nii.gz  
	 ${prefix}_native2mni_gmc_mask.nii.gz ${prefix}_native2mni_gmsc_mask.nii.gz 
	 ${prefix}_native2mni_wm_mask.nii.gz  ${prefix}_native2mni_csf_mask.nii.gz"

for ii in $lnFiles; do
    ln -sf ${outDir}/$ii    ${resultsDir}/$ii
done

