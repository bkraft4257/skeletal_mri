#!/bin/bash

#
# inDir should be the subject's directory
#

inDir=${PWD}

resultsDir=${inDir}/results
[ -d $resultsDir ] || mkdir $resultsDir

for ii in $(ls -1d [1-3]); do     # Loop over visits

       iiDir="${inDir}/$ii/pasl"
       echo ${iiDir}

       for jj in 0 1 2 3; do             # Loop over pasl time points
           cd "${iiDir}/${jj}/results"
	   pwd
           priPaslAnalyze_comproi.sh
       done

       cd ${iiDir}
       
       [ -d results ] || mkdir results

       find [0-3] -name "results.csv" | sort | xargs cat | sed -e '1b;/subjectID/d' > results/results.csv

       find [0-3] -path "*results*" -name "syn.m0*.gz"      | sort | xargs fslmerge -t results/syn.m0_To_mask.muscle.nii.gz
       find [0-3] -path "*results*" -name "syn.pwi*gz"      | sort | xargs fslmerge -t results/syn.pwi.m0_To_mask.muscle.nii.gz
       find [0-3] -path "*results*" -name "syn.mask.m0*gz"  | sort | xargs fslmerge -t results/syn.mask.m0_To_mask.muscle.nii.gz

done

cd ${inDir}

find [0-3] -path "*pasl/results/*" -name "results.csv" | sort | xargs cat | sed -e '1b;/subjectID/d' > results/results.csv