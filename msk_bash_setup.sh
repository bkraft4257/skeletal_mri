#!/usr/bin/env bash
### Skeletal MRI bash shell environment
#
#   Priorities bash shell environment was the first MSK set of tools. It
#   has been loaded seperately because eventually PRIORITIES is going to be 
#   over.  
#
#
# export MSK_MRI_PATH=${TIC_PATH}/studies/msk/
#

export MSK_PYTHONPATH=${MSK_PATH}/radcore/
export MSK_ARCHIVE_PATH=${MSK_PATH}/archive/

export MSK_MATLAB=${MSK_ARCHIVE_PATH}/matlab/
export MSK_SCRIPTS=${MSK_ARCHIVE_PATH}/scripts/
export MSK_PROTOCOLS=${MSK_ARCHIVE_PATH}/protocols/

export MSK_MRI_DATA=${MSK_DISK}/studies/pepper/skeletal_mri/

export PATH=${MSK_PATH}:${MSK_SCRIPTS}:${MSK_PATH}/bin:${PATH}	

source ${MSK_PATH}/other/msk_aliases.sh

export PYTHONPATH=${MSK_PATH}/:$PYTHONPATH

