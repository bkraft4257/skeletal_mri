#!/bin/bash
#
# icRegister2Mni.sh  is registers an 3D T1w image to the MNI template.  The location of the 
# MNI template is 
#
#  $IC_TEMPLATES/mni/mni_icbm152_nlin_sym_09a_nifti/mni_icbm152_nlin_sym_09a/mni_icbm152_t1_tal_nlin_sym_09a_brain.nii.gz
#
# icRegister2Mni.sh takes two input parameters.  The first input parameter is the T1w image that you want to register. The 
# second input parameter is the output directory.  If you want to  use the current output directory just enter $PWD
# 
# Output from icRegister2Mni.sh has the prefix ic_ to it.  The function produces many different 
# files.  The important files  are
#
#    ${prefix}1Warp.nii.gz        = Nonlinear Warping file used by ANTs
#    ${prefix}0GenericAffine.mat  = Affine Transformation file
#
# Generic Example :
#
#        icRegister2Mni.sh  <filename of T1image to be registered>  <output directory>
#
# Specific Example
#
#        icRegister2Mni.sh  T1w.nii.gz $PWD  
#



# Process inputs 

moving="$1"
fixed=${2}
outDir="${3-out}/"

# Create directory if it doesn't exist

if [ ! -d ${outDir} ]; then
  mkdir ${outDir}
fi

prefix=${outDir}syn_



if [ ! -f "${outDir}/${iniaTemplate}" ]; then

    # Use symbolic links to support cross platform file systems.

    ln -sf ${iniaTemplatePath}/${iniaTemplate} ${outDir}${iniaTemplate}
    ln -sf ${iniaTemplatePath}/${iniaMask}     ${outDir}${iniaMask}
fi

echo
echo ${moving}
echo ${outDir}${iniaTemplate}
echo ${outDir}${iniaMask}
echo ${prefix}
echo

## Registration
#

its=10x10x10
percentage=0.1
syn="10x5x0,0,5"
dim=3

antsRegistration -v  \
\
--dimensionality 3 \
--output [${prefix}, ${prefix}diff.nii.gz, ${prefix}inv.nii.gz] \
--initial-moving-transform [${fixed},${moving},1] \
\
--metric mattes[ ${fixed}, ${moving} , 1 , 32, regular, $percentage ] \
--transform translation[ 0.1 ] \
--convergence [$its,1.e-8,20] \
--smoothing-sigmas 4x2x1vox \
--shrink-factors 6x4x2  \
--use-estimate-learning-rate-once  1 \
\
--metric mattes[ ${fixed}, ${moving} , 1 , 32, regular, $percentage ] \
--transform rigid[ 0.1 ]      \
--convergence [$its,1.e-8,20] \
--smoothing-sigmas 4x2x1vox   \
--shrink-factors 3x2x1        \
--use-estimate-learning-rate-once  1 \
\
--metric mattes[ ${fixed}, ${moving} , 1 , 32, regular, $percentage ] \
--transform affine[ 0.1 ]     \
--convergence [$its,1.e-8,20] \
--smoothing-sigmas 4x2x1vox   \
--shrink-factors 3x2x1        \
--use-estimate-learning-rate-once  1 \
\
--metric mattes[ ${fixed}, ${moving} , 0.5 ]     \
--metric cc[ ${fixed}, ${moving} , 0.5 , 4 ]     \
--transform SyN[ .1, 3, 0 ]                      \
--convergence [ 10x20x40x80x160, 1.e-8, 20 ]            \
--smoothing-sigmas 12x8x4x2x1vox                     \
--shrink-factors   12x8x4x2x1                           \
--use-estimate-learning-rate-once  1 


echo; echo " >>>> Apply forward affine transform"; echo

antsApplyTransforms -v  \
  -d $dim                                      \
  -i ${moving} \
  -r ${fixed} \
  -n NearestNeighbor             \
  -t ${prefix}0GenericAffine.mat \
  -o ${prefix}forward_0warped.nii.gz

echo; echo " >>>> Apply forward affine and warp transform"; echo

antsApplyTransforms -v  \
  -d $dim                                      \
  -i ${moving} \
  -r ${fixed} \
  -n NearestNeighbor             \
  -t ${prefix}1Warp.nii.gz       \
  -t ${prefix}0GenericAffine.mat \
  -o ${prefix}forward_1warped.nii.gz


##
#
echo; echo " >>>> Apply inverse affine transform"; echo

antsApplyTransforms -v  \
  -d $dim                                      \
  -i ${fixed} \
  -r ${moving} \
  -n NearestNeighbor             \
  -t [ ${prefix}0GenericAffine.mat , 1 ] \
  -o ${prefix}_iniaTemplate_inverse_0warped.nii.gz

antsApplyTransforms -v  \
  -d $dim                                      \
  -i ${outDir}/${iniaMask} \
  -r ${moving} \
  -n NearestNeighbor             \
  -t [ ${prefix}0GenericAffine.mat , 1 ] \
  -o ${prefix}_iniaMask_inverse_0warped.nii.gz

echo; echo " >>>> Apply inverse affine and warping transform"; echo

antsApplyTransforms -v  \
  -d $dim                                      \
  -i ${fixed} \
  -r ${moving} \
  -n NearestNeighbor             \
  -t ${prefix}1InverseWarp.nii.gz       \
  -t [ ${prefix}0GenericAffine.mat , 1 ] \
  -o ${prefix}_iniaTemplate_inverse_1warped.nii.gz

antsApplyTransforms -v  \
  -d $dim                                      \
  -i ${outDir}/${iniaMask} \
  -r ${moving} \
  -n NearestNeighbor             \
  -t   ${prefix}1InverseWarp.nii.gz       \
  -t [ ${prefix}0GenericAffine.mat , 1 ] \
  -o ${prefix}_iniaMask_inverse_1warped.nii.gz




#antsRegistration uses the concept of \registration stages" to string together transforms 
#for normalization. Each stage is characterized by the following:
#
# - fixed and moving images,
# - transform,
# - shrink factors (i.e. by what factor are the fixed and moving images down-sampled at each resolution level),
# - smoothing factors (i.e. how much Gaussian smoothing is applied to each image at each resolution level),
# - similarity metric, and
# - convergence criteria (e.g. number of iterations per number of levels).
#
#  Note that different fixed and moving images can be specified for each stage and
#  multiple metrics/image pairs can be specified for a single stage.

# -c, --convergence MxNxO
#                       [MxNxO,<convergenceThreshold=1e-6>,<convergenceWindowSize=10>]
#
#          Convergence is determined from the number of iterations per level and is 
#          determined by fitting a line to the normalized energy profile of the last N 
#          iterations (where N is specified by the window size) and determining the slope 
#          which is then compared with the convergence threshold. 