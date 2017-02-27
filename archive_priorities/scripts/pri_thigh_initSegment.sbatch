#!/usr/bin/env bash

if [ ! -f "$HOME/bin/workflow-common.sh" ]; then
   echo "Unable to locate '$HOME/workflow-common.sh'"
   exit 1
fi

PIPELINE_STAGE="msk_initSegment"

. "$HOME/bin/workflow-common.sh"

if [ ! -x "$(which sbatch &> /dev/null)" ]; then
	module load slurm
fi


outputDir="../02-initSegment"

DIRS_TO_PROCESS=$@

for iiInputDir in $DIRS_TO_PROCESS; do

    iiOutputDir=${iiInputDir}/${outputDir}

    cmdSbatch="${HOME}/bin/msk_thigh_initSegment.sh ${iiInputDir} ${iiOutputDir}"

    sbatch \
      --output=${iiInputDir}/stdout-initSegment_%j.txt \
      --error=${iiInputDir}/stderr-initSegment_%j.txt \
      --job-name=initSegment \
      --nodes=1 \
      --cpus-per-task=1 \
       ${cmdSbatch}

done

echo "Submitted $(echo "$DIRS_TO_PROCESS" | wc -w) msk_initSegment jobs."
