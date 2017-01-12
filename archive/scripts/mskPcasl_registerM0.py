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

     parser = argparse.ArgumentParser(prog='mskPcasl')
     parser.add_argument("fromMask",        help="from mask" )
     parser.add_argument("toMask",          help="to mask" )
     parser.add_argument("image",           help="Image that matches from mask")
     parser.add_argument("--indir",          help="Input directory", default = os.getcwd() )
     parser.add_argument("--outdir",          help="Output directory", default = os.getcwd() )
     parser.add_argument("--outprefix",       help="Output prefix", default = "antsCT_" )
     parser.add_argument("-d","--display",  help="Display Results", action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",      action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",      action="store_true", default=False )
     parser.add_argument("--clean",         help="Clean directory by deleting intermediate files",      action="store_true", default=False )
     parser.add_argument("--qi",            help="QA inputs",      action="store_true", default=False )
     parser.add_argument("--qo",            help="QA outputs",      action="store_true", default=False )
     parser.add_argument("-r", "--run",     help="Run processing pipeline",      action="store_true", default=False )
     parser.add_argument("--nohup",         help="Run processing pipeline with no hangups",      action="store_true", default=False )

     skip = [ 1, 7 ] 

     inArgs = parser.parse_args()

     if inArgs.debug:
         print "inArgs.display  = " +  str(inArgs.display)
         print "inArgs.debug    = " +  str(inArgs.debug)
         print "inArgs.debug    = " +  str(inArgs.verbose)


     input_files = [[ toMask, ":colormap=jet:opacity=0.5"],
                    [ fromMask, ":colormap=jet:opacity=0.5"]]

     optional_files = [[ inArgs.toImage, ":colormap=grayscale:grayscale=0,4096" ],
                       [ inArgs.fromImage, ":colormap=grayscale:grayscale=0,4096" ]];

     output_files   = [[]]


     # Quality Assurance input
     #
         
     if  inArgs.qi:
         iwQa.qa_exist( input_files, True )


     # Run    
     # 
   
     if  inArgs.run or inArgs.nohup:

         if  iwQa.qa_input_files( input_files, False):

             # priPaslRegisterM0_v3.sh . m0.raw.nii.gz mask.m0.raw.nii.gz ac.mask.labels.roi.t2w.nii.gz mean.pwi.nii.gz

             iwUtilities.iw_subprocess( ["priPaslRegisterM0_v3", inArgs.indir, inArgs.from_mask, inArgs.to_mask, inArgs.fromImage, inArgs.toImage, inArgs.outdir ], 
                                         inArgs.verbose, inArgs.debug,  inArgs.nohup ):

         else:
             print "Unable to run mskPcasl.py. Failed input QA."
             iwQa.qa_exist( input_files, True )
             print


     # Quality Assurance output
     #

     if  inArgs.qo:
         iwQa.freeview( optional_files + output_files )    

     if inArgs.stats:

         stats( inArgs.labels, "pwi.nii.gz" )
