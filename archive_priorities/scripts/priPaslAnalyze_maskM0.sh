
#!/bin/bash

inM0FileName=${1-m0.nii.gz}
inM0Threshold=${2-40}

extension=".nii.gz"

inMuscleMaskBaseFileName=$(basename $inMuscleMaskFileName $extension)


echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $FUNCNAME
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inM0FileName, "  $inM0FileName
echo "inM0Threshold,"  $inM0Threshold
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo
echo


#
# Mask the M0 image based upon signal intensity.
#

fslmaths  ${inM0FileName}  -thrp $inM0Threshold -bin 1.${inM0FileName}

ImageMath 3 2.${inM0FileName}      FillHoles              1.${inM0FileName} 2
ImageMath 3 3.${inM0FileName}      GetLargestComponent    2.${inM0FileName}
ImageMath 3 4.${inM0FileName}      MC                     3.${inM0FileName} 1
ImageMath 3 mask.${inM0FileName}   GetLargestComponent    4.${inM0FileName}

rm [0-9].${inM0FileName}


