
###
## MSK Project
##
#

alias cds1='cd $SECRET1_BKRAFT_PATH/data'
alias cds2='cd $SECRET2_BKRAFT_PATH/data'
alias  cdp='cd $PRIORITIES_PATH/mriData'

alias cdmsk='cd $MSK_PATH/;echo;ls;echo'
alias cdmskm='cd $MSK_MATLAB/;echo;ls;echo'
alias cdmsks='cd $MSK_SCRIPTS/;echo;ls;echo'

alias remsk='source $MSK_PATH/msk_alias.sh'

alias cdsmp='cd $MSK_PATH; echo; ls;  echo'
alias cdsms='cd $MSK_SCRIPTS; echo; ls;  echo'
alias cdsmm='cd $MSK_MATLAB; echo; ls;  echo'
alias cdsmd='cd ${MSK_MRI_DATA}; echo; ls;  echo'

function smid { 
    
    dir=${1-$PWD}

    echo $dir | egrep 'sm0[0-9]{2}_[a-z]{5}/v[3-4]' --color -o
}


function cat_smwork {

    in_file=${1-work_comparison.csv}
    awk  'BEGIN { FS = "," }; {printf "%30s %5s %5s\n", $1, $2, $3}' $in_file
}


alias smqa6='freeview  mask.muscle.nii.gz mask.n4.m0.nii.gz:colormap=heat:opacity=0.4 m0_To_t2w_Warped.nii.gz:colormap=jet:opacity=0.5 &'

alias smqa7='freeview t2w.nii.gz                                                                            \
               labels.t2w.nii.gz:colormap=lut:lut=${MSK_SCRIPTS}/sm.labels.muscle.FreesurferLUT.txt:opacity=0.5:visible=0  \
               center_slice.labels.mbf.nii.gz:colormap=lut:lut=${MSK_SCRIPTS}/sm.labels.muscle.FreesurferLUT.txt:opacity=0.5:visible=0  \
               qaBackgroundLabel.nii.gz:colormap=jet:opacity=0.25                                           \
               m0_To_t2w.slice_mean.mbf.nii.gz:colormap=heat:heatscale=0,150      &'

alias smqar='freeview t2w.nii.gz                                                                            \
            labels.t2w.nii.gz:colormap=lut:lut=${MSK_SCRIPTS}/sm.labels.muscle.FreesurferLUT.txt:opacity=0.5:visible=0  \
              center_slice.labels.mbf.nii.gz:colormap=lut:lut=${MSK_SCRIPTS}/sm.labels.muscle.FreesurferLUT.txt:opacity=0.5:visible=0  \
              baseline.m0_To_t2w.slice_mean.mbf.nii.gz:colormap=heat:heatscale=0,150     \
              fixed.m0_To_t2w.slice_mean.mbf.nii.gz:colormap=heat:heatscale=0,150     \
              max.m0_To_t2w.slice_mean.mbf.nii.gz:colormap=heat:heatscale=0,150     '

function msk_t2w_center_slice_mask {

        gunzip project.roi.t2w.nii.gz
        matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_slice_scale('project.roi.t2w.nii', [], 'center_slice.t2w.nii'); exit"
        gzip *.nii
	iwCreateMask.py center_slice.t2w.nii.gz --thr 50 -r --qo --act

	cp mask.center_slice.t2w.nii.gz ../results
	cp t2w.nii.gz ../results
}


function qat1() { cd $(awk -v inLine=$1 'NR==inLine {print $0};' /cenc/other/msk/secret1/data/output.list); echo; pwd; echo; ls; echo; frv t1w_36ms_n4.nii t1w_36ms_n4_finalLabels.nii.gz:colormap=lut:opacity=0.4:lut=mskColorLut.txt 2> /dev/null & } 


##alias mskitk '/aging1/software/itksnap-3.2.0-20141023-Linux-x86_64/bin/itksnap -s msk_tissue_labels.nii -l /kitzman/Priorities/scripts/msk_tissue_label#s_itksnap3.txt -g t2w.nii'

#alias mskreport  "CompROI.sh \!:1.nii /kitzman/Priorities/scripts/CompROI_msk_muscle_labels.txt \!:2 \!:1.csv"



###
##  MSK Fat/Water 
##
#

#alias mskFwClean     "rm -f *gcH20* *gcFAT* *IP* *OP* *T2S* *R2S* *moco* *pwi* *cbf* final_nii.list *cbf*"
#alias mskFwList      "mskFwList.sh \!:1 ."
#alias mskFwOtsu      "mskOtsuFW.sh t2w; mskOtsuFW.sh rt1w"
#alias mskFwCheck "freeview t2w.nii rt1w.nii rfw1_gcFFAT.nii fOtsuN4_t2w_mask.nii  fOtsuN4_rt1w_mask.nii msk_fatwater_tissue_s33_labels.nii:colormap=lut:opacity=0.4  msk_fatwater_tissue_s24_labels.nii:colormap=lut:opacity=0.4  &"

#alias mskFwStats "mskFwStatsAll.sh"




