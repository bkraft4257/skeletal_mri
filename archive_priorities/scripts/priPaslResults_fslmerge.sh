#!/bin/bash

#
# inDir should be the subject's directory
#

inDir=${1-$PWD}


resultsDir=${inDir}/results
[ -d $resultsDir ] || mkdir $resultsDir

cd ${inDir}

for ii in $(ls -1d [1]); do     # Loop over visits

       iiDir="${inDir}/$ii/pasl"
       echo ${iiDir}
       cd ${iiDir}
       
       if true; then
       [ -d results ]             || mkdir results

       [ -f results/t2w.nii.gz ]                           || cp ${iiDir}/0/results/t2w.nii.gz                               results
       [ -f results/mask.t2w.nii.gz ]                      || cp ${iiDir}/0/results/mask.t2w.nii.gz                               results
       [ -f results/mask.muscle.nii.gz ]                   || cp ${iiDir}/0/results/mask.muscle.nii.gz                       results
       [ -f results/labels.muscle.nii.gz ]                 || cp ${iiDir}/0/results/labels.muscle.nii.gz                     results
       [ -f results/frequencyBackground.mask.t2w.nii.gz ]  || cp ${iiDir}/0/results/frequencyBackground.mask.t2w.nii.gz      results
       [ -f results/phaseBackground.mask.t2w.nii.gz ]      || cp ${iiDir}/0/results/phaseBackground.mask.t2w.nii.gz          results

       fi 

       if false; then
       
       find [0-3] -path "*/results/*" -name "translation.m0*.gz"      | sort | xargs fslmerge -t results/translation.m0_To_mask.muscle.nii.gz
       find [0-3] -path "*/results/*" -name "translation.pwi*gz"      | sort | xargs fslmerge -t results/translation.pwi_To_mask.muscle.nii.gz
       find [0-3] -path "*/results/*" -name "translation.mask.m0*gz"  | sort | xargs fslmerge -t results/translation.mask.m0_To_mask.muscle.nii.gz

       find [0-3] -path "*/results/*" -name "syn.m0*.gz"      | sort | xargs fslmerge -t results/syn.m0_To_mask.muscle.nii.gz
       find [0-3] -path "*/results/*" -name "syn.pwi*gz"      | sort | xargs fslmerge -t results/syn.pwi_To_mask.muscle.nii.gz
       find [0-3] -path "*/results/*" -name "syn.mask.m0*gz"  | sort | xargs fslmerge -t results/syn.mask.m0_To_mask.muscle.nii.gz


       cd results

       fslroi syn.m0_To_mask.muscle.nii.gz syn.m0_reference.nii.gz 0 1
       fslmaths    labels.muscle.nii.gz -thr 7 -uthr 7 -binv -mul labels.muscle.nii.gz -bin mask.labels.muscle.nii.gz
       
       m0scale=$( fslstats syn.m0_reference.nii.gz -k mask.labels.muscle.nii.gz -M ) 
          
       cmd="fslmaths syn.pwi_To_mask.muscle.nii.gz -div $m0scale -mul  1391.37 syn.rsmbf_To_mask.muscle.nii.gz"
       echo $cmd
       $cmd

       fi

#      meanRsmbfscale=$( fslstats syn.rsmbf_reference.nii.gz -k mask.labels.muscle.nii.gz -M ) 

       echo
done

cd ${inDir}

