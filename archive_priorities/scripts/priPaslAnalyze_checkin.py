#!/aging1/software/anaconda/bin/python

"""
  icFsSkullStrip.py  strips the skull for a range of watershed threshold values.  Default value is 25.
  This code will apply transformation from a threshold of 20 to 30.  The results will be written to 
  the directory mri/skullstrip.  Files will be converted from MGZ format to NIFTI.GZ format.  Once 
  converted files will be concatenated to NIFTI for easy viewing. 

  More information can be found at https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/SkullStripFix_freeview
"""

import sys      
import os                                               # system functions
import shutil

from  argparse import ArgumentParser

## Parsing Arguments
#
#

#inFileName=${1-syn.m0_To_${inMuscleMaskBaseFileName}.nii.gz}
#inVascularThreshold=${2-500};
#inKernelBoxV=${3-5}
#outFileName=${3-mask.vascular.nii.gz}

#fslmaths $inFileName  -abs -thr $inVascularThreshold -bin -kernel boxv $inKernelBoxV -dilM $outFileName


"""
positional arguments:
  square                display a square of a given number

optional arguments:
  -h, --help            show this help message and exit
  -v {0,1,2}, --verbosity {0,1,2}
                        increase output verbosity
"""

usage = "usage: %prog [options] arg1 arg2"

parser = ArgumentParser(usage=usage)


parser.add_argument("inFileName",  type=file,        help="Function debugging argument" )
#parser.add_argument("outFileName",                   help="Function debugging argument", default="mask.vascular.nii.gz")
parser.add_argument("-t", "--inThreshold",       type=int, help="Percentage Threshold", default=40 )
parser.add_argument("-d", "--debugFlag",         help="Function debugging argument", action='store_true', default=False )

inArgs = parser.parse_args()

if inArgs.debugFlag:
    print parser.parse_args()


"""
Initialize arguments
"""

m0               = inArgs.inFileName
threshold        = inArgs.inThreshold
outFileName      = "mask.m0.nii.gz"  # inArgs.outFileName

if inArgs.debugFlag:

    print
    print fileName
    print threshold

#
# Create Vascular Map
#

sysCmd = "fslmaths " + m0.name + " -thrp " + str(threshold) + " " + outFileName

print
print sysCmd 
print

os.system(sysCmd)

#
# Mask the M0 image based upon signal intensity.
#

#fslmaths  ${inM0FileName}  -thrp $inM0Threshold -bin 1.${inM0FileName}
#
#ImageMath 3 2.${inM0FileName}      FillHoles              1.${inM0FileName} 2
#ImageMath 3 3.${inM0FileName}      GetLargestComponent    2.${inM0FileName}
#ImageMath 3 4.${inM0FileName}      MC                     3.${inM0FileName} 1
#ImageMath 3 mask.${inM0FileName}   GetLargestComponent    4.${inM0FileName}

#rm [0-9].${inM0FileName}
