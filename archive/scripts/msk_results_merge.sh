#!/bin/bash


displayDir=${1-$PWD}
resultsDir=$(readlink -f $displayDir/..)

[ -d $displayDir ] || mkdir $displayDir

#for ii in baseline fixed max; do
#    cp $ii/results/qa_background.slice_mean.mbf.csv $resultsDir/${ii}.qa_background.slice_mean.mbf.csv
#    cp $ii/results/mbf.index                        $resultsDir/${ii}.mbf.index.csv
#    cp $ii/results/m0_To_t2w.slice_mean.mbf.csv     $resultsDir/${ii}.m0_To_t2w.slice_mean.mbf.csv
#    cp $ii/results/m0_To_t2w.slice_mean.mbf.nii.gz  $resultsDir/${ii}.m0_To_t2w.slice_mean.mbf.nii.gz
#done


#
# Maximum
#




for ii in baseline fixed max; do
    ii_name=${ii}.m0_To_t2w.slice_mean.mbf.nii.gz

    echo FIRST $ii_name
    fslroi ${resultsDir}/${ii_name} ${displayDir}/first.${ii_name} 0 -1 0 -1  2 1 0 1
    dim4=$(fslval ${resultsDir}/$ii.m0_To_t2w.slice_mean.mbf.nii.gz dim4)

    echo LAST $ii_name

    fslroi ${resultsDir}/${ii_name} ${displayDir}/last.${ii_name} 0 -1 0 -1  2 1 $(( $dim4 -1 )) 1

done

fslmerge -x first.m0_To_t2w.slice_mean.mbf.nii.gz  first.{baseline,fixed,max}.m0_To_t2w.slice_mean.mbf.nii.gz
fslmerge -x last.m0_To_t2w.slice_mean.mbf.nii.gz   last.{baseline,fixed,max}.m0_To_t2w.slice_mean.mbf.nii.gz

fslmerge -y summary.m0_To_t2w.slice_mean.mbf.nii.gz  {last,first}.m0_To_t2w.slice_mean.mbf.nii.gz 


#
#
#
fslroi ${resultsDir}/t2w.nii.gz  slice.t2w.nii.gz  0 -1   0 -1  36 8     

fslmerge -x first.t2w.nii.gz slice.t2w.nii.gz slice.t2w.nii.gz slice.t2w.nii.gz
fslmerge -x last.t2w.nii.gz slice.t2w.nii.gz slice.t2w.nii.gz slice.t2w.nii.gz

fslmerge -y summary.t2w.nii.gz {last,first}.t2w.nii.gz

