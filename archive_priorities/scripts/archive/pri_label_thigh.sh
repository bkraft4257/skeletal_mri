#!/bin/bash

rm -rf nohup.msk_label_thigh.log;
nohup /aging1/software/matlab/bin/matlab -nodisplay -nodesktop -nosplash < $SECRET2_SCRIPTS/msk_label_thigh_script.m > nohup.msk_label_thigh.log &

# cat nohup.msk_label_thigh.log

