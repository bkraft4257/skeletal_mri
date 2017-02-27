#!/usr/bin/env bash

if [ ! -f "$HOME/bin/workflow-common.sh" ]; then
   echo "Unable to locate '$HOME/workflow-common.sh'"
   exit 1
fi

PIPELINE_STAGE="N4BiasCorrection"

. "$HOME/bin/workflow-common.sh"

inImage=t1w_36ms.nii.gz
outImage=t1w_36ms_n4.nii.gz



if [ ! -x "$(which sbatch &> /dev/null)" ]; then
	module load slurm
fi

IMAGES_TO_PROCESS=$@

for iiInputDir in $IMAGES_TO_PROCESS; do
   sbatch \
      --output=${iiInputDir}/stdout-%j.txt \
      --error=${iiInputDir}/stderr-%j.txt \
      --job-name=n4biascorrect \
      --nodes=1 \
      --cpus-per-task=1 \
       ${HOME}/bin/n4BiasFieldCorrection.sh "${iiInputDir}" 

done

echo "Submitted $(echo "$IMAGES_TO_PROCESS" | wc -w) n4BiasCorrection jobs."
