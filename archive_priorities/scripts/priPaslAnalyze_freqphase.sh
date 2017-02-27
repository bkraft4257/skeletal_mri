#!/bin/bash

inDir=${1-$PWD}
inDir=$(readlink -f $inDir)

cd $inDir

inT2wMaskFileName=${2-mask.t2w.nii.gz}

extension=".nii.gz"

outDir=${inDir}"/../01-register/"
[ -d $outDir ] || mkdir $outDir
outDir=$( readlink -f ${outDir} )

resultsDir=${inDir}"/../results/"
[ -d $resultsDir ] || mkdir $resultsDir
resultsDir=$( readlink -f ${resultsDir} )

maskT2wExistFlag=true
[ -f $inT2wMaskFileName ]          || maskT2wExistFlag=false;


if [ ! -f ${resultsDir}/frequencyBackground.${inT2wMaskFileName} ]; then 

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inT2wMaskFileName, "      $inT2wMaskFileName    	$maskT2wExistFlag   
echo
echo "outDir, "     $outDir
echo "resultsDir, " $resultsDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


if $maskT2wExistFlag; then   

   echo
   echo "Passes test and may proceed"
   echo

else

   echo
   echo "Missing input files necessary to run script"
   echo
   exit

fi

#
# Create Frequency and Phase Background Quality Masks
#



    echo ${resultsDir}/frequencyBackground.${inT2wMaskFileName} " does not exists "

    if true; then
	cd $outDir;
    
	gunzip -f ${inT2wMaskFileName}  #Unzip files because Matlab code can only read NII files. 
	
	niiT2wMaskFileName=$(basename $inT2wMaskFileName .gz)
	
	matlab -nodisplay -nosplash -nodesktop -r "iwCreateFreqPhaseBackgroundMask('${niiT2wMaskFileName}',5); exit"
	
	gzip -f *.nii
	
	cp {phase,frequency}Background.${inT2wMaskFileName} $resultsDir
	
    fi

else

    echo ${resultsDir}/frequencyBackground.${inT2MaskFileName} " exists "
fi