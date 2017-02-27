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
import distutils

import  argparse
import  priCalfLabels

import subprocess


def  fslstats_display():

     qaList2 = [ 't2w.nii.gz',
                 'labels.muscle.nii.gz',
                 'syn.m0_To_mask.muscle.nii.gz',             # M0 image
                 'syn.rsmbf_To_mask.muscle.nii.gz' ]
     
     labelLUT  = os.environ.get('PRIORITIES_SCRIPTS') + '/labels.muscle.FreesurferLUT.txt'

     systemCommand = ( "freeview "  +
                       qaList2[0] + " " +
                       qaList2[1] + ":colormap=lut:opacity=0.2:visible=0:lut=" + labelLUT + " " +
                       qaList2[2] + ":visible=0 " +
                       qaList2[3] + ":visible=1:colormap=heat:heatscale=0,300,600:opacity=1.0" )
     

     os.system( systemCommand + " 2> /dev/null &")    
#
# fslstats
#

def get_subject_id():


         sysCommand="pwd | grep -o 'pri[0-9][0-9]_[a-z][a-z][a-z][a-z][a-z]\/[1-3]'"
         pipe = subprocess.Popen([sysCommand], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

         (out, err) = pipe.communicate()

         fullID    = str(out)
         subjectID = fullID[:-3]
         visit     = fullID[-2:-1]

         return [ subjectID, visit];


def fslstats_header():
     print ('%10s, %8s, %25s,  %8s,  %8s,  %8s,  %8s,\t  %8s,  %8s,  %8s,  %8s') % ('subjectID', 'visit', 'mask', '0','1','2','3', '1-0','1-3','2-3', '3-0' )


def  fslstats( fileName, masks, subjectID, visit ):

     returnStats = [];

     for ii in masks:

         sysCommand='fslstats -t '+ fileName  + ' -k ' + ii[2] + ' -M' 
         pipe = subprocess.Popen([sysCommand], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True) 

         (out, err) = pipe.communicate()

         meanStat   = map( float, out.splitlines() )

         stats = [ meanStat[0], meanStat[1], meanStat[2], meanStat[3], meanStat[1]-meanStat[0], meanStat[1]-meanStat[3], meanStat[2]-meanStat[3], meanStat[3]-meanStat[0] ]

         print ('%10s, %8s, %25s,  %8.2f,  %8.2f,  %8.2f,  %8.2f,\t  %8.2f,  %8.2f,  %8.2f,  %8.2f') % ( subjectID, str(visit),
                                  ii[1],  stats[0], stats[1], stats[2], stats[3], stats[4], stats[5], stats[6], stats[7] )



         returnStats.append(stats)

     return returnStats
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

     parser = argparse.ArgumentParser(prog='priPaslResults')
     parser.add_argument('--inDirectory',       help='directory to use', action='store', default=os.getcwd())
     parser.add_argument("--uthr",       type=int, help="Upper threshold", default=10000000000)
     parser.add_argument("--thr",        type=int, help="Lower threshold", default=-10000000000)
     parser.add_argument("--abs",        type=int, help="Lower threshold", default=False)
     parser.add_argument("--debug",       help="Debug flag", action="store_true", default=False )
     parser.add_argument("--subjectID",   help="Debug flag", action="store", default='auto' )
     parser.add_argument("--visit",       help="Debug flag", action="store", default='auto' )
     parser.add_argument("-d","--display",       help="Debug flag", action="store_true", default=False )
     parser.add_argument("-m","--muscle",       help="Debug flag", action="store_true", default=False )
     parser.add_argument("-b","--background",       help="Debug flag", action="store_true", default=False )

     #qa1 = parser.add_mutually_exclusive_group(required=False)
     #qa1.add_argument('--qa1',    dest='qa1', action='store_true')
     #qa1.add_argument('--no-qa1', dest='qa1', action='store_false')

     #parser.set_defaults(['--qa1'])

     inArgs = parser.parse_args()

     if inArgs.debug:
         print "inArgs.inDirectory = " +  str(inArgs.inDirectory)
         print "inArgs.debug       = " +  str(inArgs.debug)

     os.chdir(inArgs.inDirectory)

     #
     # Break Up Labels
     #

     masks = priCalfLabels.define_muscle_masks()

     fileName='syn.rsmbf_To_mask.muscle.nii.gz'

     # FSL Stats for muscles

     [autoSubjectID, autoVisit ] = get_subject_id();


     if inArgs.subjectID == 'auto':
         subjectID = autoSubjectID
     else:
         subjectID = inArgs.subjectID

   
     if inArgs.visit == 'auto':
         visit = autoVisit
     else:
         visit = inArgs.visit
         

     if inArgs.muscle or inArgs.background:
         fslstats_header()

     if inArgs.muscle:

         statsFileName1 = 'threshold.' + fileName    

         sysCommand='fslmaths ' + fileName  + ' -uthr ' + str(inArgs.uthr) + ' -thr ' + str(inArgs.thr) + " " + statsFileName1
         pipe = subprocess.Popen([sysCommand], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True) 
         (out, err) =  pipe.communicate()
         
         fslstats( statsFileName1, masks, subjectID, visit )

     if inArgs.display:
         fslstats_display()

     #
     #
     #

     # FSL Stats for background

     if inArgs.background:

         statsFileName2 = 'abs.' + 'threshold.' + fileName    
         absBackgroundStats = []

         sysCommand='fslmaths ' + fileName  + ' -uthr ' + str(inArgs.uthr) + ' -thr ' + str(inArgs.thr) + ' -abs ' + statsFileName2
         pipe = subprocess.Popen([sysCommand], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True) 
         (out, err) =  pipe.communicate()
         
         bstats = fslstats( statsFileName2, [[ 0, 'phase_background',     'phaseBackground.mask.t2w.nii.gz'], 
                                    [ 0, 'frequency_background', 'frequencyBackground.mask.t2w.nii.gz']], subjectID, visit ) 

         print ('%10s, %8s, %25s,  %8.2f,  %8.2f,  %8.2f,  %8.2f,\t  %8.2f,  %8.2f,  %8.2f,  %8.2f') % ( subjectID, str(visit),
                                  'ratio_background',  bstats[0][0]/bstats[1][0], bstats[0][1]/bstats[1][1], bstats[0][2]/bstats[1][2], 
                                                       bstats[0][3]/bstats[1][3], bstats[0][4]/bstats[1][4], bstats[0][5]/bstats[1][5],
                                                       bstats[0][6]/bstats[1][6], bstats[0][7]/bstats[1][7] )

    

