 #!/bin/bash

 rm -rf  class1 btClass1 chClass1 diffClass1
 mkdir   btClass1 chClass1 diffClass1

## chClass1
#
#
 cd chClass1/
 ln ../segment/t2w_n4.nii .; ln ../segment/t2w_n4_atLCC.nii .; ln ../segment/t2w_n4_chAutoLabels.nii .
 msk_fix_labels.sh t2w_n4_chAutoLabels.nii
 msk_classify_thigh.sh t2w_n4 t2w_n4_chAutoLabels t2w_n4_atLCC
 fslmaths t2w_n4_chAutoLabels.nii -mul 10 -add t2w_n4_smSegment_01.nii t2w_n4_finalChAutoLabels

## btClass1
#
#
 ls
 cd ../btClass1/
 cp ../../../segment/${1}* .
 ln ../segment/t2w_n4.nii .; ln ../segment/t2w_n4_atLCC.nii .; ln ../segment/t2w_n4_chAutoLabels.nii .
 msk_classify_thigh.sh t2w_n4 ${1}_t2w_n4_chLabels t2w_n4_atLCC
 fslmaths ${1}_t2w_n4_chLabels.nii -mul 10 -add t2w_n4_smSegment_01.nii t2w_n4_finalBtLabels

## diffClass1
#
#
 cd ../diffClass1/
 ln ../btClass1/t2w_n4_finalBtLabels.nii.gz .
 ln ../segment/t2w_n4.nii .
 ln ../chClass1/t2w_n4_finalChAutoLabels.nii.gz .
 fslmaths t2w_n4_finalBtLabels.nii.gz -sub t2w_n4_finalChAutoLabels.nii.gz t2w_n4_diffLabels
 freeview *
