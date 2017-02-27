#!/usr/bin/env bash

if [ ! -f "$HOME/bin/workflow-common.sh" ]; then
   echo "Unable to locate '$HOME/workflow-common.sh'"
   exit 1
fi

PIPELINE_STAGE="projectLabel"

. "$HOME/bin/workflow-common.sh"

if [ ! -x "$(which sbatch &> /dev/null)" ]; then
	module load slurm
fi

DIRS_TO_PROCESS=$@

for iiInputDir in $DIRS_TO_PROCESS; do

    cmdSbatch="priCalfProject.sh ${iiInputDir}"

    sbatch \
      --output=${iiInputDir}/stdout-${PIPELINE_STAGE}_%j.txt \
      --error=${iiInputDir}/stderr-${PIPELINE_STAGE}_%j.txt \
      --job-name=${PIPELINE_STAGE} \
      --nodes=1 \
      --cpus-per-task=1 \
       ${cmdSbatch}

done

echo "Submitted $(echo "$DIRS_TO_PROCESS" | wc -w) $PIPELINE_STAGE jobs."
