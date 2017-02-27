
#!/bin/bash

inDir=${1-$PWD}
inM0FileName=${2-m0.nii.gz}
inMuscleMaskFileName=${4-mask.muscle.nii.gz}

outDir=${inDir}/../01-maskM0
[ -d $outDir ] || mkdir $outDir
outDir=$( readlink -f ${outDir} )

resultsDir=${inDir}/../results
[ -d $resultsDir ] || mkdir $resultsDir
resultsDir=$( readlink -f ${resultsDir} )


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, " $inDir
echo "inM0FileName, "           $inM0FileName
echo "inMuscleMaskFileName, "   $inT1wMuscleMaskFileName
echo
echo "outDir, " $outDir
echo "resultsDir, " $resultsDir
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo

cp ${inDir}/$inMuscleMaskFileName ${outDir}

cd $outDir;

#
# Mask the M0 image based upon signal intensity.
#

fslmaths ${inDir}/${inM0FileName}  -thrp 40 -bin 1.${inM0FileName}

ImageMath 3 2.${inM0FileName}    FillHoles            1.${inM0FileName} 2
ImageMath 3 3.${inM0FileName}    GetLargestComponent  2.${inM0FileName}
ImageMath 3 mask.${inM0FileName} MD                   3.${inM0FileName} 0.5

rm [0-9].${inM0FileName}

fslmaths ${inDir}/${inM0FileName} -mas mask.${inM0FileName} ${inM0FileName}



