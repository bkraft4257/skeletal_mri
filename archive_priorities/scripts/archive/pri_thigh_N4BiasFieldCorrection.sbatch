#!/usr/bin/env bash

if [ ! -f "$HOME/bin/workflow-common.sh" ]; then
   echo "Unable to locate '$HOME/workflow-common.sh'"
   exit 1
fi

PIPELINE_STAGE="msk_n4Bias"

. "$HOME/bin/workflow-common.sh"


if [ ! -x "$(which sbatch &> /dev/null)" ]; then
	module load slurm
fi



IMAGES_TO_PROCESS=$@

for iiInputDir in $IMAGES_TO_PROCESS; do

    cmdSbatch="${HOME}/bin/msk_thigh_N4BiasFieldCorrection.sh ${iiInputDir}" 

   sbatch \
      --output=${iiInputDir}/stdout-n4Bias_%j.txt \
      --error=${iiInputDir}/stderr-n4Bias_%j.txt \
      --job-name=n4Bias \
      --nodes=1 \
      --cpus-per-task=1 \
       $cmdSbatch

done

echo "Submitted $(echo "$IMAGES_TO_PROCESS" | wc -w) n4BiasCorrection jobs."
