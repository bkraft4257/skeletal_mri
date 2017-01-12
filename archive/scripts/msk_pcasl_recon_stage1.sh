#
# 01-extract  03-n4  03-mcf  04-pwi  05-cbf  06-register  07-stats  input#
#

mkdir  ../02-extract
cd     ../02-extract
gunzip -c $inputDir/raw.nii.gz > ./raw.nii

matlab -nodisplay -nosplash -nodesktop -r "mskPcasl_extract; exit"

