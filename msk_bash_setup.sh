#!/usr/bin/env bash
### Infinite bash shell environment
#
#

#
# export RADCORE_PATH=/gandg/infinite3/infinite/icGit/release/ic/studies/infinite
#

export RADCORE_PYTHONPATH=${RADCORE_PATH}/radcore/
export RADCORE_ARCHIVE_PATH=${RADCORE_PATH}/archive/

export RADCORE_MATLAB=${RADCORE_ARCHIVE_PATH}/matlab/
export RADCORE_SCRIPTS=${RADCORE_ARCHIVE_PATH}/scripts/
export RADCORE_PROTOCOLS=${RADCORE_ARCHIVE_PATH}/protocols/

export RADCORE_MRI_SUBJECT_DATA=/RadCCORE_MRI/subjects/
export RADCORE_MRI_DATA=/RadCCORE_MRI/subjects/

export PATH=${RADCORE_PATH}:${RADCORE_SCRIPTS}:${PATH}	

source ${RADCORE_PATH}/other/radcore_aliases.sh

export PYTHONPATH=${RADCORE_PATH}:$PYTHONPATH

