#!/usr/bin/env bash
### PRIORITIES bash shell environment
#
#

#
# export PRIORITIES_PATH=/cenc/tic_bkraft/studies/msk/
#

export PRIORITIES_PYTHONPATH=${PRIORITIES_PATH}/priorities/
export PRIORITIES_ARCHIVE_PATH=${PRIORITIES_PATH}/archive/

export PRIORITIES_MATLAB=${PRIORITIES_ARCHIVE_PATH}/matlab/
export PRIORITIES_SCRIPTS=${PRIORITIES_ARCHIVE_PATH}/scripts/
export PRIORITIES_PROTOCOLS=${PRIORITIES_ARCHIVE_PATH}/protocols/

export PRIORITIES_MRI_SUBJECT_DATA=/cenc/other/msk/priorities/mriData/
export PRIORITIES_MRI_DATA=/cenc/other/msk/priorities/mriData/

export PATH=${PRIORITIES_PATH}:${PRIORITIES_SCRIPTS}:${PATH}	

source ${PRIORITIES_PATH}/other/priorities_aliases.sh

export PYTHONPATH=${PRIORITIES_PATH}:$PYTHONPATH

