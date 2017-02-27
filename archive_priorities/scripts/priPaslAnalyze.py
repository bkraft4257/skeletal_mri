#!/aging1/software/anaconda/bin/python


import sys      
import os                                               # system functions
import glob
import shutil
import subprocess

import  argparse

"""
  icFsSkullStrip.py  strips the skull for a range of watershed threshold values.  Default value is 25.
  This code will apply transformation from a threshold of 20 to 30.  The results will be written to 
  the directory mri/skullstrip.  Files will be converted from MGZ format to NIFTI.GZ format.  Once 
  converted files will be concatenated to NIFTI for easy viewing. 

  More information can be found at https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/SkullStripFix_freeview
"""

#
# First Quality Assurance Test 1
#

def qaRegistrationTest():
    qaList1 = [ 't2w.nii.gz',              
                'labels.muscle.nii.gz',
                'mask.muscle.nii.gz',              
                'translation.mask.m0_To_mask.muscle.nii.gz',     # M0 image
                'syn.mask.m0_To_mask.muscle.nii.gz',
                'frequencyBackground.mask.t2w.nii.gz',
                'phaseBackground.mask.t2w.nii.gz' ]
    
    
    qaTest1=True
    
    print
    
    for f in qaList1:
        fileExist = os.path.isfile(f)
    	qaTest1   = qaTest1 & fileExist
        
        
    if qaTest1:
        print "QA Warp Test : All files are present"
        
        systemCommand = ("freeview " +
                         qaList1[0]  + " " +
                         qaList1[1]  + ":visible=0:colormap=lut " +
                         qaList1[2]  + ":visible=0:colormap=lut " +
                         qaList1[3]  + ":visible=1:colorscale=0.1,1:opacity=0.4 " +
                         qaList1[4]  + ":colormap=jet:colorscale=0.1,1:opacity=0.4 " +
                         qaList1[5]  + ":colormap=jet:colorscale=0.1,0.5:opacity=0.2 " +
                         qaList1[6]  + ":colormap=jet:opacity=0.2 ")
        
# print systemCommand
        
        if inArgs.nodisplay:
            os.system( systemCommand + " 2> /dev/null &")    
            
    else:
        print "QA Warp Test : Files missing "
        
        for f in qaList1:
            if not os.path.isfile(f):
                print "\t " +  f + " does not exist"
                print
                    
                    
                    
                    
#
# Second Quality Assurance Test 2
#
def qaInspectionTest():

    qaList2 = [ 't2w.nii.gz',
                'labels.muscle.nii.gz',
                'translation.m0_To_mask.muscle.nii.gz',     # M0 image
                'translation.pwi_To_mask.muscle.nii.gz',
                'syn.m0_To_mask.muscle.nii.gz',     # M0 image
                'syn.pwi_To_mask.muscle.nii.gz' ]
    
    
    qaTest2=True
    
    for f in qaList2:
        fileExist = os.path.isfile(f)
    	qaTest2   = qaTest2 & fileExist
        
        
    if qaTest2:
            
        print "QA Results Inspection : All files are present"
            
        systemCommand = ( "freeview "  +
                          qaList2[0] + " " +
                          qaList2[1] + ":colormap=lut  " +
                          qaList2[2] + ":visible=0:colormap=heat"  +
                          qaList2[3] + ":visible=0:colorscale=0.1,1:opacity=0.4" +
                          qaList2[4] + ":visible=0:colormap=heat" +
                          qaList2[5] + ":colormap=jet:colorscale=0,300:opacity=0.4" )
        
#    print systemCommand
            
        if inArgs.nodisplay:
            os.system( systemCommand + " 2> /dev/null &")    
            
    else:
        print "QA Results Inspection : Files are missing "
        
        for f in qaList2:
            if not os.path.isfile(f):
                print "\t " + f + " does not exist"
                
                print        


###########################################################################################
## Parsing Arguments
#
#


usage = "usage: %prog [options] arg1 arg2"

class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

parser = MyParser()

parser.add_argument("-n", "--nodisplay",   help="Do not display results in freeview", action='store_false', default=True )
parser.add_argument("--qaout",             help="Run QA on functions output", action='store_false', default=True )

inArgs = parser.parse_args()

#
# QA Output Tests
#

if inArgs.qaout:
    qaRegistrationTest()
    qaInspectionTest()

#
# Return from function
#

print


