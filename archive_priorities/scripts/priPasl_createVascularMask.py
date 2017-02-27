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

#inFileName=${1-syn.pwi_To_${inMuscleMaskBaseFileName}.nii.gz}
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
parser.add_argument("-t", "--inThreshold",       type=int, help="Function debugging argument", default=500 )
parser.add_argument("-b", "--inKernelBoxV",      type=int, help="Function debugging argument", default=5 )
parser.add_argument("-d", "--debugFlag",         help="Function debugging argument", action='store_true', default=False )

inArgs = parser.parse_args()

if inArgs.debugFlag:
    print parser.parse_args()


"""
Initialize arguments
"""

pwi              = inArgs.inFileName
threshold        = inArgs.inThreshold
boxv             =inArgs.inKernelBoxV
outFileName      = "mask.vascular.nii.gz"  # inArgs.outFileName

if inArgs.debugFlag:

    print
    print fileName
    print threshold
    print boxv

#
# Create Vascular Map
#

sysCmd = "fslmaths " + pwi.name + " -abs -thr " + str(threshold) + " -bin -kernel boxv " + str(boxv) + " -dilM " + outFileName

print
print sysCmd 
print

os.system(sysCmd)
