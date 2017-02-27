#!/usr/bin/env bash

if [ ! -f "$HOME/bin/workflow-common.sh" ]; then
   echo "Unable to locate '$HOME/workflow-common.sh'"
   exit 1
fi

PIPELINE_STAGE="msk_calf_Register3DSyN"

. "$HOME/bin/workflow-common.sh"

if [ ! -x "$(which sbatch &> /dev/null)" ]; then
	module load slurm
fi

inputDir="${1-$PWD}"
fixed="$2"
moving="$3"

outputDir="../01-antsRegSyn"
[ -d $outputDir ] || mkdir ${outputDir}


cmdSbatch="${HOME}/bin/msk_calf_Register3DSyN.sh ${inputDir} $fixed $moving"

sbatch \
  --output=${inputDir}/stdout-${PIPELINE_STAGE}_%j.txt \
  --error=${inputDir}/stderr-${PIPELINE_STAGE}_%j.txt \
  --job-name=${PIPELINE_STAGE} \
  --nodes=1 \
  --cpus-per-task=1 \
   ${cmdSbatch}

