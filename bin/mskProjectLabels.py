#!/aging1/software/anaconda/bin/python

"""
"""

import sys      
import os                                               # system functions
import glob
import shutil
import distutils

import argparse
import subprocess
import _qa_utilities as qa_util
import _utilities as util


#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     usage = "usage: %prog [options] arg1 arg2"

     parser = argparse.ArgumentParser(prog='mskProjectLabels')
     parser.add_argument("--t2w",            help="Input file name" )
     parser.add_argument("--labels",         help="Input file name" )
     parser.add_argument("-n", "--nslices",  help="Number of slices to project", default=5, type=int )
     parser.add_argument("--indir",          help="Input directory", default = os.getcwd() )
     parser.add_argument("--outdir",          help="Output directory", default = os.getcwd() )
     parser.add_argument("--outprefix",       help="Output prefix", default = "antsCT_" )
     parser.add_argument("-d","--display",  help="Display Results", action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",      action="store_true", default=False )
     parser.add_argument("--nohup",           help="nohup",           action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",      action="store_true", default=False )
     parser.add_argument("--clean",         help="Clean directory by deleting intermediate files",      action="store_true", default=False )
     parser.add_argument("--qi",            help="QA inputs",      action="store_true", default=False )
     parser.add_argument("--qo",            help="QA outputs",      action="store_true", default=False )
     parser.add_argument("-r", "--run",           help="Run processing pipeline",      action="store_true", default=False )

     inArgs = parser.parse_args()

     if inArgs.debug:
         print("inArgs.t2w      = " +  str(inArgs.t2w))
         print("inArgs.labels   = " +  str(inArgs.labels))
         print("inArgs.display  = " +  str(inArgs.display))
         print("inArgs.debug    = " +  str(inArgs.debug))
         print("inArgs.debug    = " +  str(inArgs.verbose))


     input_files = [[ inArgs.t2w,    ":colormap=grayscale:grayscale=0,4096" ],
                    [ inArgs.labels, ":colormap=lut:lut=" + os.getenv("PRIORITIES_SCRIPTS") + "/labels.muscle.FreesurferLUT.txt:opacity=0.5" ]];


     if inArgs.debug:
         print(input_files)

     output_files = [[ 'project.' + inArgs.t2w,    ":colormap=grayscale:grayscale=0,4096" ],
                    [  'project.' + inArgs.labels, ":colormap=lut:lut=" + os.getenv("PRIORITIES_SCRIPTS") + "/labels.muscle.FreesurferLUT.txt" ]];


     # Quality Assurance input
     #
         
     if  inArgs.qi:
         qa_util.qa_exist( input_files, True )
         qa_util.freeview( input_files, True )    




     
     # Run    
     # 
   
     if  inArgs.run:

         if  qa_util.qa_input_files( input_files, False):

             util.tic_subprocess([ 'gunzip', inArgs.labels ], inArgs.verbose, inArgs.debug, inArgs.nohup)
             util.tic_subprocess([ 'gunzip', inArgs.t2w    ], inArgs.verbose, inArgs.debug, inArgs.nohup)

             try:
                 callCommand = ["matlab", "-noFigureWindows", "-nosplash", "-nodesktop", "-r", "mskProjectLabels( '" + 
                                os.path.splitext(inArgs.labels)[0] + "','"+ os.path.splitext(inArgs.t2w)[0]  + "'); exit" ]

                 print(callCommand)

                 util.tic_subprocess( callCommand, inArgs.verbose, inArgs.debug, inArgs.nohup)

             finally:
                 util.tic_subprocess(['gzip', os.path.splitext(inArgs.labels)[0], os.path.splitext(inArgs.t2w)[0] ], inArgs.verbose, inArgs.debug, inArgs.nohup)


             util.tic_subprocess(['gzip', 'project.' + os.path.splitext(inArgs.labels)[0], 
                                        'project.' + os.path.splitext(inArgs.t2w)[0] ], inArgs.verbose, inArgs.debug, inArgs.nohup)

         else:
             print("Unable to run mskProjectLabels.py. Failed input QA.")
             qa_util.qa_exist( input_files, True )
             print('\n')


     # Quality Assurance output
     #

     if  inArgs.qo:
          qa_util.freeview( output_files, True, True )    
