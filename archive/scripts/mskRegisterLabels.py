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
import iwQa
import iwUtilities


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
     parser.add_argument("--t2wfull",        help="Input file name" )
     parser.add_argument("--t2w",            help="Single slice of t2w" )
     parser.add_argument("--labels",         help="Single slice of labels", default=None )
     parser.add_argument("-n", "--nslices",  help="Number of slices to project", default=5, type=int )
     parser.add_argument("--indir",          help="Input directory",   default = os.getcwd() )
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
         print "inArgs.t2w      = " +  str(inArgs.t2w)
         print "inArgs.labels   = " +  str(inArgs.labels)
         print "inArgs.display  = " +  str(inArgs.display)
         print "inArgs.debug    = " +  str(inArgs.debug)
         print "inArgs.debug    = " +  str(inArgs.verbose)


     input_files = [[ inArgs.t2w,    ":colormap=grayscale:grayscale=0,4096" ],
                    [ inArgs.labels, ":colormap=lut:lut=" + os.getenv("PRIORITIES_SCRIPTS") + "/labels.muscle.FreesurferLUT.txt:opacity=0.5" ]];

     optional_files = [[ inArgs.t2wfull,    ":colormap=grayscale:grayscale=0,4096" ]]

     if inArgs.debug:
         print input_files

     output_files = [[ 'project.' + inArgs.t2w,    ":colormap=grayscale:grayscale=0,4096" ],
                    [  'project.' + inArgs.labels, ":colormap=lut:lut=" + os.getenv("PRIORITIES_SCRIPTS") + "/labels.muscle.FreesurferLUT.txt" ]];


     # Quality Assurance input
     #
         
     if  inArgs.qi:
         iwQa.qa_exist( input_files, True )
         iwQa.freeview( input_files, True )    




     
     # Run    
     # 
   
     if  inArgs.run:

         if  iwQa.qa_input_files( input_files, False):

             try:
                 callCommand = ["mskRegisterLabels.sh", inArgs.indir,  inArgs.t2wfull, inArgs.t2w, inArgs.outdir ]
                 iwUtilities.iw_subprocess( callCommand, inArgs.verbose, inArgs.debug, inArgs.nohup)
             except:
                 quit()

         else:
             print "Unable to run mskRegisterLabels.py. Failed input QA."
             iwQa.qa_exist( input_files, True )
             print


     # Quality Assurance output
     #

     if  inArgs.qo:

         if  iwQa.qa_input_files( output_files, False):
             iwQa.freeview( optional_files + output_files )    
