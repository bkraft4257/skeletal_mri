#!/bin/bash

ext='nii.gz'

t2w=t2w.${ext}
t2w_muscle_mask=t2w_muscle_mask.${ext}
t2w_lowSignal_mask=t2w_lowSignal_mask.${ext}
labels=t2w_labels.${ext}
outFilename=histogram.txt


t2w_muscle=t2w_muscle.${ext}
t2w_muscle_norm=t2w_muscle_norm.${ext}

t2w_otsu_sm=t2w_otsu_sm.${ext}
t2w_otsu_fat=t2w_otsu_fat.${ext}


t2w_background=t2w_background.${ext}

nOtsu=5
t2w_otsu=t2w_otsu${nOtsu}.${ext}


# Create Muscle Mask
#
#

fslmaths ${labels} -thr 2 -uthr 2 -bin ${t2w_muscle_mask}
fslmaths ${t2w} -mul ${t2w_muscle_mask}  ${t2w_muscle}

rm -rf ${outFilename}
touch ${outFilename}

ImageMath 3 ${t2w_muscle_norm} Normalize ${t2w_muscle}

ThresholdImage 3 ${t2w_muscle_norm} ${t2w_otsu} Otsu ${nOtsu}

fslmaths ${t2w_otsu} -thr     1    -uthr     1    -bin ${t2w_otsu_sm}
fslmaths ${t2w_otsu} -thr ${nOtsu} -uthr ${nOtsu} -bin ${t2w_otsu_fat}


fslstats ${t2w_muscle_norm} -k ${t2w_otsu_sm}  -M -S  >> ${outFilename}
fslstats ${t2w_muscle_norm} -k ${t2w_otsu_fat} -M -S >> ${outFilename}
fslstats ${t2w_muscle_norm} -h 100 | cat -n | head -100  >> ${outFilename}

echo
cat ${outFilename}
echo