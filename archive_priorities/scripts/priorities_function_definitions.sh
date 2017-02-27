
alias msk_source='source ${MSK_SCRIPTS}/msk_function_definitions.sh'

function msk_n4_bias_correction() {

         inBaseFileName=${1-t1w_36ms}
	 extension=nii.gz

	 inFileName=${inBaseFileName}.${extension}

	 n4BaseFileName=${inBaseFileName}_n4
	 inSegmentThreshold=${2-3}


	 if [ ! -e ${inFileName} ]; then

	     echo
	     echo "${inFileName} not found"
	     echo
	     return
	 fi

	 cmd="N4BiasFieldCorrection -d 3 -i ${inBaseFileName}.${extension} -o ${inBaseFileName}_n4.${extension} -r -s"
	 echo $cmd
	 $cmd

	 
}

function msk_all() {

  	   INPUT_DIR=${1-$PWD}
	   inSegmentThreshold=${2-[]}

	 # Resegment data based upon label. This is done again to correct for manual edits 
	   inDir="${INPUT_DIR}/"
	   outDir="${INPUT_DIR}/../03-segment"
	   

	   # echo $inDir
	   # echo $outDir
	   # echo $inSegmentThreshold
	   
	    msk_segment_thigh  ${inDir} ${outDir} ${inSegmentThreshold}
	  
	 # Classify Skeletal Intramuscular Muscle and Skeletal Intramuscular Fat
	   inDir="${INPUT_DIR}/../03-segment"
	   outDir="${INPUT_DIR}/../04-classify"

           msk_classify_thigh ${inDir} ${outDir}

	 # Combine labels into a single ROI.  IMM and IMF are added to original label after it is multipled by 10

	   inDir=./04-classify
	   outDir=./05-combine

	   cd ${inDir}
	   cp -r $inDir $outDir
	   cd $outDir

           msk_combine_labels ${n4BaseFileName}_labels         ${n4BaseFileName}_smSegment_01 ${n4BaseFileName}_finalLabels
           msk_combine_labels ${n4BaseFileName}_chAutoLabels   ${n4BaseFileName}_smSegment_01 ${n4BaseFileName}_finalChLabels

	 # Calculate statistics using CompROI for volume label and slice label
	   msk_comproi_v2 ${n4BaseFileName}_finalLabels ${n4BaseFileName}_finalLabels.raw.csv
	   msk_comproi_v2 ${n4BaseFileName}_finalChLabels ${n4BaseFileName}_finalChLabels.raw.csv


	 # Clean up statistics by selecting only volumes of interest
	 msk_clean ${n4BaseFileName}_finalLabels
	 msk_clean ${n4BaseFileName}_finalChLabels
}

function msk_clean() {
    

    inFileName=${1}.raw.csv      #
    mskTmp1=${1}.tmp    #
    mskStats=${1}.csv

    rm -f $mskTmp1
    
    echo 'fileName,' $(head -1 ${inFileName})  > ${mskTmp1}
    grep -vH ID *.csv >> ${mskTmp1}
    cat ${mskTmp1} | tr ":" "," > ${mskTmp1}

    cut -d ',' -f 1,2,3,6,7,14,15,18,19,22,23,26,27,30,31 ${mskTmp1} | tee ${mskStats}
    
}

function msk_comproi_v2() {

      inFileName=$1
      outStats=${2}

      echo "msk_comproi_v2():  ${inFileName}"


      imageList=image.list
      roiList=roi.list
      sliceMask=sliceMask.nii.gz
      volumeMask=volumeMask.nii.gz
     
      subjectID=$(echo $PWD | cut -d "/" -f 8)
      echo ${subjectID}

      msk_create_volume_mask ${inFileName} $volumeMask
      msk_create_slice_mask  ${inFileName} $sliceMask

      msk_write_image_list ${imageList}
      msk_write_roi_list ${roiList}


      echo "outStats =" ${outStats}

      msk_comproi.sh  ${inFileName} ${roiList}  ${imageList}  ${outStats}

      echo
      cat ${outStats}
      echo

}



function msk_label_thigh() {
	 matlab -noFigureWindows -nosplash -nodesktop -r "msk_label_thigh('${1}'); exit"
}

function msk_segment_thigh() {
	 matlab -noFigureWindows -nosplash -nodesktop -r "msk_segment_thigh_v3('${1}', '${2}', ${3}, false); exit"
}


function msk_estimate_fat_fraction() {
	 matlab -noFigureWindows -nosplash -nodesktop -r "msk_estimate_fat_fraction('${1}'); exit"
}

function msk_classify_thigh() {

    # $1 inN4T2w='t2w_n4';
    # $2 inLabels='t2w_n4_labels';
    # $3 inAtLcc='t2w_n4_atLCC';

    matlab -noFigureWindows -nosplash -nodesktop -r "msk_classify_thigh_v1('${1}', '${2}'); exit"
}

function msk_combine_labels() {

    #  
    # $1 = btMask
    # $2 = Labels (subFat, Muscle, Cortex, Marrow)
    # $3 = Output file
 
    # Range should be from 0 to 40.  


   fslmaths $1 -mul 10 -add $2 $3
}





function msk_write_roi_list() {

      roiList=$1

      rm -rf $roiList

      echo "ID,    LabelName"        	 >  ${roiList}
      echo "10,    subcutaneousFat"  	 >> ${roiList}
      echo "20,    skeletalMuscle"       >> ${roiList}
      echo "21+22, skeletalMuscle2"      >> ${roiList}
      echo "21,    intraMuscularMuscle"  >> ${roiList}
      echo "22,    intraMusclarFat"      >> ${roiList}
      echo "30,    boneCortex"           >> ${roiList}
      echo "40,    boneMarrow"           >> ${roiList}

      echo
      cat ${roiList}
      echo

}


function msk_write_image_list() {

      imageList=$1
     
      rm -f ${imageList}

      echo "ID, absoluteFileName"            >  ${imageList}
      echo ${subjectID}, ${PWD}/$volumeMask  >> ${imageList}
      echo ${subjectID}, ${PWD}/$sliceMask   >> ${imageList}

      echo
      cat ${imageList}
      echo
}

function msk_create_volume_mask() {

      echo msk_create_volume_mask

      inFileName=$1
      volumeMask=$2

      rm -f ${volumeMask}
      fslmaths ${inFileName} -mul 0 -binv ${volumeMask}

}


function msk_create_slice_mask() {

      echo msk_create_slice_mask

      inFileName=$1
      sliceMask=$2
      tmpFile=mskTmp1.nii
      
      rm -f ${sliceMask} ${tmpFile} mskTmp*.nii.gz 

      fslmaths ${inFileName} -mul 0 ${tmpFile}
      fslslice ${tmpFile}.gz
      fslmaths mskTmp1_slice_0002.nii.gz -add 1 mskTmp1_slice_0002.nii.gz
      fslmerge -z ${sliceMask} mskTmp1_slice_000*

      rm -f mskTmp*.nii.gz 
}


function msk_gather() {

    find . -name "*finalLabels.csv" | xargs lnflatten.sh
#    mv tmpFlat compare
#    cd compare
#    head 
}


function msk_comproi_chauto() {

      echo "msk_comproi_chauto()"

      atLccFileName=t2w_n4_atLCC.nii
      labelFileName=t2w_n4_chAutoLabels.nii
      imageList=chImageList.txt

      fslmaths $atLccFileName -binv -mul $labelFileName t2w_n4_chInnerLabels.nii	
      msk_comproi_ch_image_list.sh $1 $PWD > ${imageList}
      msk_comproi.sh t2w_n4_chAutoLabels.nii ${SECRET2_SCRIPTS}/roiLabels.txt  ${imageList}  compRoi_chLabels.csv
      msk_comproi.sh t2w_n4_chInnerLabels.nii ${SECRET2_SCRIPTS}/roiLabels.txt ${imageList}  compRoi_chInnerLabels.csv
}

function msk_comproi_diff() {

      echo "msk_comproi_diff()"

      diffLabels=t2w_n4_diffLabels.nii.gz
 
      btLabels=t2w_n4_btFinalLabels.nii.gz
      chLabels=t2w_n4_chFinalLabels.nii.gz

      t2w=t2w_n4.nii
      imageList=imageList.txt
      roiList=roiList.txt
      sliceMask=sliceMask.nii.gz
      volumeMask=volumeMask.nii.gz

      btStats=t2w_n4_finalBtLabels.csv
      chStats=t2w_n4_finalChAutoLabels.csv
      mskStats=t2w_n4_finalLabelStats.csv
     
      subjectID=$(echo $PWD | cut -d "/" -f 8)

      msk_create_volume_mask $volumeMask
      msk_create_slice_mask  $sliceMask

      rm -f ${volumeStats} ${sliceStats}

      msk_write_image_list ${imageList}
      msk_write_roi_list ${roiList}

      msk_comproi.sh  ${btLabels} ${roiList}  ${imageList}  ${btStats}

      echo
      cat ${btStats}
      echo


      msk_comproi.sh  ${chLabels}  ${roiList}  ${imageList}  ${chStats}
      echo
      cat ${chStats}
      echo

# 
# Combine stats
#
      mskTmp=mskTmp.csv
      mskTmp1=mskTmp1.csv

      rm -f ${mskStats} ${mskTmp} ${mskTmp1}

      echo 'fileName,' $(head -1 ${chStats}) > ${mskTmp}
      grep -vH ID ${btStats} >> ${mskTmp}
      grep -vH ID ${chStats} >> ${mskTmp}
      cat ${mskTmp} | tr ":" "," > ${mskTmp1}

      cut -d ',' -f 1,2,3,7,11,15,19,23,27 ${mskTmp1} | tee ${mskStats}

      rm -f ${mskTmp} ${mskTmp1}
}
