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
import distutils

import  argparse


#
#
#
def define_labels():

     labels    = [[ 1, 'gastroc_medial'],
                  [ 2, 'gastroc_lateral'],
                  [ 3, 'soleus'],
                  [ 4, 'peroneus'],
                  [ 5, 'tibialis_anterior'  ],
                  [ 6, 'tibialis_posterior' ],
                  [ 7, 'fibia'  ],
                  [ 8, 'flexor_digitorum_longus'  ],
                  [ 9, 'fibularis'  ]]

     return labels



def define_muscle_masks():
     masks = []

     labels = define_labels()
     del labels[6]

     for ii in labels:
          masks.append(  [ ii[0], ii[1], 'mask.labels.' + ii[1] + '.nii.gz'] )

     masks.append( [ 'all', 'muscle', 'mask.labels.muscle.nii.gz'] )     

     return masks


def create_muscle_masks(labelName, masks):

     # Break up labels into invidual masks.

     muscleMask = masks[-1][2];

     subprocess.call(['fslmaths', labelName , '-mul', '0', muscleMask ])

     for ii in masks[:-1]:
          print ii[0], ii[1], ii[2]
          subprocess.call(["fslmaths", labelName, "-thr", str(ii[0]), "-uthr", str(ii[0]), '-bin', ii[2]  ])
          subprocess.call(["fslmaths",  muscleMask,"-add", ii[2],  muscleMask  ])

     
#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     usage = "usage: %prog [options] arg1 arg2"

     class MyParser(argparse.ArgumentParser):
         def error(self, message):
             sys.stderr.write('error: %s\n' % message)
             self.print_help()
             sys.exit(2)

     parser = argparse.ArgumentParser(prog='priCalfLabels')
     parser.add_argument("--debug",             help="Debug flag", action="store_true", default=False )
     parser.add_argument('-d', "--display",             help="Debug flag", action="store_true", default=False )
     parser.add_argument('-m', "--mask",              help="Labels to individual mask", action="store_true", default=False )

     inArgs = parser.parse_args()

     if inArgs.debug:
         print "inArgs.debug = " +  str(inArgs.debug)
         print "inArgs.mask = " +  str(inArgs.debug)

     labelName = 'labels.muscle.nii.gz'
     labelLUT  = os.environ.get('PRIORITIES_SCRIPTS') + '/labels.muscle.FreesurferLUT.txt'

     masks = define_muscle_masks()

     if inArgs.mask:
         create_muscle_masks(labelName, masks)

     if inArgs.display:
         subprocess.Popen(['freeview', labelName+':colormap=lut:lut='+labelLUT])

       

