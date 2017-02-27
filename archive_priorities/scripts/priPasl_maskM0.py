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
import glob
import shutil
import subprocess

from  argparse import ArgumentParser

##  Define System Print
#
#

def runSystemCommand( systemCommand, debugFlag=False ) :

    if debugFlag:
        print systemCommand

    os.system(systemCommand)


##  Define QA function
#
#

def displayImages():

    filelist = sorted(glob.glob("[1-4]."+outFileName))
    qaDisplayIntermediateFiles = " "

    if inArgs.debug:

        for f in filelist:
            qaDisplayIntermediateFiles += f + ":visible=0 "
        

    sysCmd=("freeview " + m0.name + 
            qaDisplayIntermediateFiles +
            outFileName + ":colormap=jet:opacity=0.4")

    os.system(sysCmd + " 2> /dev/null &")    



## Parsing Arguments
#
#


usage = "usage: %prog [options] arg1 arg2"

parser = ArgumentParser(usage=usage)


parser.add_argument("-i","--inFileName",          default="m0.nii.gz",  type=file,        help="Function debugging argument" )
#parser.add_argument("outFileName",                   help="Function debugging argument", default="mask.vascular.nii.gz")
parser.add_argument("-t", "--threshold",     type=int, help="Percentage Threshold", default=30 )
parser.add_argument("-d", "--debug",         help="Function debugging argument", action='store_true', default=False )
parser.add_argument("-q", "--qa",            help="Function debugging argument", action='store_true', default=False )
parser.add_argument("--qaonly",        help="Function debugging argument", action='store_true', default=False )

inArgs = parser.parse_args()

if inArgs.debug:
    print parser.parse_args()


"""
Initialize arguments
"""

m0               = inArgs.inFileName          
threshold        = inArgs.threshold
outFileName      = "mask." + m0.name

if inArgs.debug:

    print
    print m0.name
    print threshold
    print outFileName

#
# Display images that already exist and exit
#

if inArgs.qaonly:
    displayImages()
    quit()


#
# Threshold M0 and binarize to create initial mask
#

sysCmd = "fslmaths " + m0.name + " -thrp " + str(threshold) + " -bin 1." + outFileName

runSystemCommand(sysCmd, inArgs.debug)


#
# Grab largest component
#
sysCmd = "ImageMath 3 2." + outFileName + " GetLargestComponent 1." + outFileName

runSystemCommand(sysCmd, inArgs.debug)

#
# Fill Holes
#
sysCmd = "ImageMath 3 3." + outFileName + " FillHoles 2." + outFileName

runSystemCommand(sysCmd, inArgs.debug)

#
# Dilate Mask 
#
sysCmd = "ImageMath 3 " + outFileName + " MD 3." + outFileName + " .5 "

runSystemCommand(sysCmd, inArgs.debug)


#
# Remove intermediate files. 
#

# shutil.copy2( '4.' + outFileName, outFileName )

filelist = sorted(glob.glob("[1-4]."+outFileName))

if not inArgs.debug:
    
    for f in filelist:
        os.remove(f)
            
#
# QA Results
#

if inArgs.qa:
    displayImages()

#
# Mask the M0 image based upon signal intensity.
#

#fslmaths  ${inM0FileName}  -thrp $inM0Threshold -bin 1.${inM0FileName}
#
#ImageMath 3 2.${inM0FileName}      FillHoles              1.${inM0FileName} 2

#ImageMath 3 4.${inM0FileName}      MC                     3.${inM0FileName} 1
#ImageMath 3 mask.${inM0FileName}   GetLargestComponent    4.${inM0FileName}

#rm [0-9].${inM0FileName}
