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

## Parsing Arguments
#
#


usage = "usage: %prog [options] arg1 arg2"

class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

parser = argparse.ArgumentParser(prog='priPaslResults')
parser.add_argument("-d", "--display",     help="Display results in freeview",        action='store_true',  default=True )
parser.add_argument("-n", "--no-display",  help="Do not display results in freeview", action='store_false', default=False, dest="display" )
parser.add_argument("-1", "--qa1",               help="Perform test 1", default=False, action="store_true",  dest="qa1" )
parser.add_argument("-2", "--qa2",               help="Perform test 2", default=False, action="store_true",  dest="qa2" )
parser.add_argument("-3", "--qa3",               help="Perform test 3", default=False, action="store_true",  dest="qa3" )
parser.add_argument("--debug",             help="Debug flag", action="store_true", default=False )

#qa1 = parser.add_mutually_exclusive_group(required=False)
#qa1.add_argument('--qa1',    dest='qa1', action='store_true')
#qa1.add_argument('--no-qa1', dest='qa1', action='store_false')

#parser.set_defaults(['--qa1'])



inArgs = parser.parse_args()

if inArgs.debug:
    print "inArgs.display = " +  str(inArgs.display)
    print "inArgs.qa1       = " + str(inArgs.qa1  )
    print "inArgs.qa2       = " + str(inArgs.qa2 )
    print "inArgs.debug     = " + str(inArgs.debug)

qa1Flag = (inArgs.qa1 == True)

print 

#
# First Quality Assurance Test 1
#

if inArgs.qa1:

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
                         qaList1[2]  + ":visible=0 " +
                         qaList1[3]  + ":visible=1:colorscale=0.1,1:opacity=0.4 " +
                         qaList1[4]  + ":colormap=jet:colorscale=0.1,1:opacity=0.4 " +
                         qaList1[5]  + ":colormap=jet:colorscale=0.1,0.5:opacity=0.2 " +
                         qaList1[6]  + ":colormap=jet:opacity=0.2 ")
        
        if inArgs.debug:
            print
            print systemCommand
            print

        if inArgs.display:
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

if inArgs.qa2:
   
    qaList2 = [ 't2w.nii.gz',
                'labels.muscle.nii.gz',
                'mask.muscle.nii.gz',
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
                          qaList2[1] + ":colormap=lut:visible=0 " +
                          qaList2[2] + ":visible=0 " +
                          qaList2[3] + ":visible=0:colormap=heat "  +
                          qaList2[4] + ":visible=0:colorscale=0.1,1:opacity=0.4 " +
                          qaList2[5] + ":visible=0:colormap=heat " +
                          qaList2[6] + ":colormap=heat:heatscale=0,150,300:opacity=0.5" )
        if inArgs.debug:
            print
            print systemCommand
            print

        if inArgs.display:
            os.system( systemCommand + " 2> /dev/null &")    
            
    else:
        print "QA Results Inspection : Files are missing "
        
        for f in qaList2:
            if not os.path.isfile(f):
                print "\t " + f + " does not exist"
                
        print        


#
# Third Quality Assurance Test 3. Intended for 4D files.
#

if inArgs.qa3:
   
    qaList3 = [ 't2w.nii.gz',
                'labels.muscle.nii.gz',
                'mask.muscle.nii.gz',
                'syn.mask.m0_To_mask.muscle.nii.gz',     # M0 image
                'syn.m0_To_mask.muscle.nii.gz',          # M0 image
                'syn.pwi_To_mask.muscle.nii.gz' ]    
    
    qaTest3=True
    
    for f in qaList3:
        fileExist = os.path.isfile(f)
	qaTest3   = qaTest3 & fileExist
        
        
    if qaTest3:
            
        print "QA Results 4D Inspection : All files are present"
        
        systemCommand = ( "freeview "  +
                          qaList3[0] + " " +
                          qaList3[1] + ":colormap=lut:visible=0 " +
                          qaList3[2] + ":visible=0 " +
                          qaList3[3] + ":colormap=jet:visible=0 " +
                          qaList3[4] + ":visible=0 "  + 
                          qaList3[5] + ":colormap=heat:heatscale=0,150,300:opacity=0.5" )
        if inArgs.debug:
            print
            print systemCommand
            print

        if inArgs.display:
            os.system( systemCommand + " 2> /dev/null &")    
            
    else:
        print "QA Results 4D Inspection : Files are missing "
        
        for f in qaList3:
            if not os.path.isfile(f):
                print "\t " + f + " does not exist"
                
        print        
                    
                        

#
# Return from function
#

print
