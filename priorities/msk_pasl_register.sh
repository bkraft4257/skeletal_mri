#!/bin/bash

    # Pad M0 mask image to improve registration at edges.
    ImageMath 3 pad.mask.n4.m0.nii.gz PadImage mask.n4.m0.nii.gz 5

    # Register m0 Mask to t2w Muscle Mask. Decided to perform the registration this way so all
    # Three experiments are in the same space (T2 anatomical space). This helps with comparisons.

    if [ ! -f m0_To_t2w_0Warp.nii.gz ]; then 
	mskRegisterSyNQuick2D.sh -d 3 -m pad.mask.n4.m0.nii.gz -f mask.muscle.nii.gz -o m0_To_t2w_ | tee  mskRegistrationSyNQuick2D.log
    fi


    #
    # Perform Transformation on the MBF images in 4D
    #

    mbf=slice_mean.mbf.nii.gz
    nVolumes=$(fslval ${mbf} dim4)
  

    for ii in $(seq 0 1 $(( $nVolumes - 1)) ); do

        jj=$(printf %02g $ii)
        fslroi $mbf ${jj}.$mbf $ii 1
        
        antsApplyTransforms -d 3 -r n4.m0.nii.gz -i ${jj}.${mbf} -o m0_To_t2w.${jj}.${mbf} -t m0_To_t2w_0Warp.nii.gz  -v

    done

    fslmerge -t m0_To_t2w.${mbf} m0_To_t2w.[0-9][0-9].${mbf}
    rm -rf   *[0-9][0-9].${mbf}

    #
    # Perform Transformation on the norm_m0.tissue images in 4D
    #

    tissue=slice_mean.norm_m0.tissue.nii.gz
    nVolumes=$(fslval ${tissue} dim4)
  
    for ii in $(seq 0 1 $(( $nVolumes - 1)) ); do

        jj=$(printf %02g $ii)
        cmd="fslroi $tissue ${jj}.$tissue $ii 1"

	echo $cmd
	$cmd

        antsApplyTransforms -d 3 -r n4.m0.nii.gz -i ${jj}.${tissue} -o m0_To_t2w.${jj}.${tissue} -t m0_To_t2w_0Warp.nii.gz  -v

    done

    fslmerge -t m0_To_t2w.${tissue}  m0_To_t2w.[0-9][0-9].${tissue}
    rm -rf   *[0-2][0-9].${tissue}

    # Transform Labels to M0 Resolution

    antsApplyTransforms -d 3 -r n4.m0.nii.gz -i labels.t2w.nii.gz       -o labels.mbf.nii.gz           -t identity                -v -n MultiLabel
    antsApplyTransforms -d 3 -r n4.m0.nii.gz -i pad.mask.n4.m0.nii.gz   -o muscle.label.mbf.nii.gz     -t  m0_To_t2w_0Warp.nii.gz -v -n MultiLabel

    # Restrict M0 Labels to Center Slice

    gunzip labels.mbf.nii.gz muscle.label.mbf.nii.gz
    /aging1/software/matlab/bin/matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_slice_scale('labels.mbf.nii', [], 'center_slice.labels.mbf.nii'); mskPcasl_slice_scale('muscle.label.mbf.nii', [], 'center_slice.muscle.mbf.nii'); exit"
    gzip -f *.nii

    fslmaths center_slice.labels.mbf.nii.gz -thr 7  -uthr 7  -bin mask.fibula.nii.gz
    fslmaths center_slice.labels.mbf.nii.gz -thr 11 -uthr 11 -bin mask.tibia.nii.gz

    fslmaths mask.fibula.nii.gz -add mask.tibia.nii.gz -binv -mul center_slice.muscle.mbf.nii.gz  center_slice.muscle.mbf.nii.gz
