#!/bin/bash


resultsDir=results
mkdir $resultsDir

baselineDir=baseline/results

for ii in  center_slice.labels.mbf.nii.gz labels.t2w.nii.gz qaBackgroundLabel.nii.gz t2w.nii.gz sm.labels.muscle.FreesurferLUT.txt; do
    cp ${baselineDir}/${ii} $resultsDir
done


cp ../t2w/results/t2w.nii.gz $resultsDir

for ii in baseline fixed max; do
    cp $ii/results/qa_background.slice_mean.mbf.csv  $resultsDir/${ii}.qa_background.slice_mean.mbf.csv
    cp $ii/results/mbf.index                         $resultsDir/${ii}.mbf.index.csv
    cp $ii/results/m0_To_t2w.slice_mean.mbf.csv      $resultsDir/${ii}.m0_To_t2w.slice_mean.mbf.csv
    cp $ii/results/m0_To_t2w.slice_mean.mbf.nii.gz   $resultsDir/${ii}.m0_To_t2w.slice_mean.mbf.nii.gz
done




