#!/bin/bash

inDir=${1-$PWD}
inDir=$(readlink -f $inDir)

muscleLabels=${2-"${inDir}/../../labels/muscleLabels.nii.gz"}
muscleLabels=$(readlink -f $muscleLabels)

subjectID=$(echo $inDir | grep -o "pri[0-1][0-9]_[a-z][a-z][a-z][a-z][a-z]")

visit=$(echo -n $inDir | grep -o "pri[0-1][0-9]_[a-z][a-z][a-z][a-z][a-z]\/[1-3]" | grep -o "[0-9]$" )

paslAcquisition=$(echo $inDir | grep -o "pasl\/[0-3]\/results" | grep -o "[0-3]" )

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inDir, "    	$inDir
echo "muscleLabels",    $muscleLabels
echo "subjectID," 	$subjectID
echo "visit,"           $visit
echo "paslAcquisition," $paslAcquisition
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo

#
# Measure mean, standard deviation and volume for each ROI
#
#  One ROI per line per measurement
#

CompROI.sh $muscleLabels ${PRIORITIES_SCRIPTS}/priPaslAnalyze_comproi_labels.txt ${PRIORITIES_SCRIPTS}/priPaslAnalyze_comproi_images.txt 1.results.csv

#
# Transpose results from COMPROI. I want to put the results for each ROI on a single line
#

~/bin/transpose --fsep "," -t 1.results.csv > 2.results.csv

sed "1,2d" 2.results.csv > 3.results.csv

grep  "nV"            3.results.csv | sed 's/\-nV//'                       >  3.nv.csv   
grep  "std"           3.results.csv | sed 's/\-std//' | cut -d "," -f 2,3  >  3.std.csv
grep -v "\-std\|\-nV" 3.results.csv                   | cut -d "," -f 2,3  >  3.mean.csv

#for ii in nv; do
awk -v type=${ii} -v visit=${visit} -v paslAcquisition=${paslAcquisition} -v subjectID="${subjectID}" ' BEGIN {FS=","; OFS=",";}; NR==1 {a=$3/$2}; \
{printf "%s,%s,%s,%s%s\n", subjectID, visit, paslAcquisition, type, $0 }' 3.nv.csv > 4.nv.csv

#done

echo

echo "subjectID,visit,paslTime,type,region,m0_nV,pwi_nV,m0_std,pwi_std,m0_mean,pwi_mean" > results.csv
paste -d "," 4.nv.csv 3.std.csv 3.mean.csv | sed 's/ //g' >> results.csv

echo
echo "From results.csv"
echo
cat results.csv
echo
echo

rm -rf [0-9].{results,std,mean,nv}.csv


