#!/bin/bash

echo  $IMAGEWAKE2_PATH



resultsDir=${1-$PWD}
displayDir=$(readlink -f $resultsDir/display)

lutFileName="${resultsDir}/sm.labels.muscle.FreesurferLUT.txt"


[ -d $displayDir ] || mkdir $displayDir


pcaslOptions="colormap=heat:heatscale=0,150:opacity=0.5:smoothed=1"


iwLabelExtract.py labels.t2w.nii.gz              muscle.labels.t2w.nii.gz              --labels 1 2 3 4 5 --mask
iwLabelExtract.py center_slice.labels.mbf.nii.gz muscle.center_slice.labels.mbf.nii.gz --labels 1 2 3 4 5 --mask

cd $displayDir




#
# Label Files
#


if true; then
opacity=0.5

freeview ${resultsDir}/t2w.nii.gz \
         ${resultsDir}/label.muscle.center_slice.labels.mbf.nii.gz:colormap=lut:lut=${lutFileName}:opacity=${opacity} \
            --screenshot "labels.axial.mbf.png" 1.0 --zoom 2 --viewport axial

freeview ${resultsDir}/t2w.nii.gz \
         ${resultsDir}/label.muscle.center_slice.labels.mbf.nii.gz:colormap=lut:lut=${lutFileName}:opacity=${opacity} \
            --screenshot "labels.coronal.mbf.png" 1.0 --zoom 2 --viewport coronal

freeview ${resultsDir}/t2w.nii.gz \
         ${resultsDir}/label.muscle.labels.t2w.nii.gz:colormap=lut:lut=${lutFileName}:opacity=${opacity} \
            --screenshot "labels.axial.t2w.png" 1.0 --zoom 2 --viewport axial

freeview ${resultsDir}/t2w.nii.gz \
         ${resultsDir}/label.muscle.labels.t2w.nii.gz:colormap=lut:lut=${lutFileName}:opacity=${opacity} \
            --screenshot "labels.coronal.t2w.png" 1.0 --zoom 2 --viewport coronal

fi

#
# Time Series
#


for ii in baseline fixed max; do

    ii_name=${ii}.m0_To_t2w.slice_mean.mbf.nii.gz
    echo FIRST $ii_name
    fslroi ${resultsDir}/${ii_name} ${displayDir}/first.${ii_name} 0 -1 0 -1  2 1 0 1

    dim4=$(fslval ${resultsDir}/$ii.m0_To_t2w.slice_mean.mbf.nii.gz dim4)
    echo LAST $ii_name $dim4

    fslroi ${resultsDir}/${ii_name} ${displayDir}/last.${ii_name} 0 -1 0 -1  2 1 $(( $dim4 -1 )) 1

done


cd ${displayDir}

for ii in baseline fixed max; do

    ii_name=${ii}.m0_To_t2w.slice_mean.mbf.nii.gz

    for jj in first last; do

	freeview ${resultsDir}/t2w.nii.gz                                            \
	    "${jj}.${ii_name}:${pcaslOptions}"      \
	    --screenshot "${jj}.${ii}.png" 1.0 --zoom 2 --viewport axial --colorscale

    done
done



