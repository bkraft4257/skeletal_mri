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

import argparse
import subprocess
import iwQa
import iwUtilities


def extract_volumes_from_raw_images( rawPcasl, verboseFlag=False ):
    
    from nipype.interfaces.fsl import ExtractROI

    fslroi_m0                 = ExtractROI()
    fslroi_m0.inputs.in_file  = rawPcasl;

    # M0 1st volume
    fslroi_m0.inputs.roi_file = "m0." + rawPcasl
    fslroi_m0.inputs.t_min     = 0;
    fslroi_m0.inputs.t_size    = 1;

    iwQa.display_command( fslroi_m0.cmdline, verboseFlag )

    if not os.path.isfile( fslroi_m0.inputs.roi_file):
        fslroi_m0.run()
    

    # Control Label Pairs volume

    pipe = subprocess.Popen([ "fslval", inArgs.raw, "dim4"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    nVolumes = int( pipe.stdout.read() )

    fslroi_cl                  = ExtractROI()
    fslroi_cl.inputs.in_file   = rawPcasl;
    fslroi_cl.inputs.roi_file  = "cl." + rawPcasl
    fslroi_cl.inputs.t_min     = 1;
    fslroi_cl.inputs.t_size    = nVolumes - 7 - 1;  # 7 for the post scans.  -1 for fsl starting point  

    iwQa.display_command( fslroi_cl.cmdline, verboseFlag )

    if not os.path.isfile( fslroi_cl.inputs.roi_file):
        fslroi_cl.run()
        
    out_list = [fslroi_m0.inputs.roi_file, fslroi_cl.inputs.roi_file]
    
    return out_list




def mcflirt( clPcasl, verboseFlag=False ):
   
    from nipype.interfaces.fsl import MCFLIRT
 
    mcflirt = MCFLIRT()
    
    mcflirt.inputs.in_file    = clPcasl
    mcflirt.inputs.cost       = 'mutualinfo'
    mcflirt.inputs.out_file   = "mcf." + mcflirt.inputs.in_file
    mcflirt.inputs.ref_vol    = 0
    mcflirt.inputs.save_mats  = True
    mcflirt.inputs.save_plots = True

    iwQa.display_command(mcflirt.cmdline, verboseFlag )

    if not os.path.isfile( mcflirt.inputs.out_file):
        res = mcflirt.run()

    return mcflirt.inputs.out_file


def plot_motion_parameters( clPcasl, verboseFlag=False ):

    import nipype.interfaces.fsl as fsl

    plotter                  = fsl.PlotMotionParams()
    plotter.inputs.in_file   = "mcf." + clPcasl +".par"
    plotter.inputs.in_source = 'fsl'

    for ii in ["rotations", "displacement", "translations"]:

        plotter.inputs.plot_type = ii

        if inArgs.verbose:
            print plotter.cmdline

        res = plotter.run() 


def calc_mean_m0( m0_filename, mask,  verboseFlag=False, debugFlag=True ):

    callCommand = [ "fslstats", m0_filename, "-k", mask, "-M"]

    pipe = subprocess.Popen(callCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    mean_m0 = pipe.stdout.read()

    if debugFlag:
        print
        print " ".join(callCommand)
        print "mean_m0 = " + mean_m0
        print

    return float(mean_m0)


def mean_pwi( raw_pwi_filename, nCLPairsToAverage,  out_pwi_filename,  verboseFlag=False, debugFlag=False ):

    from nipype.interfaces import fsl

    if debugFlag:
        print "Entering mean_pwi"

    pipe                = subprocess.Popen([ "fslval", raw_pwi_filename, "dim4"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    nVolumes            = int( pipe.stdout.read() )
    nVolumesCalibration = 7

    # Control Label Pairs volume
    fslroi = fsl.ExtractROI()

    for ii,jj in enumerate( xrange(0,nVolumes,nCLPairsToAverage)):

        ii_base_filename =  str(jj).rjust(3,'0') + "." + raw_pwi_filename
        ii_filename      = "00.fslroi." + ii_base_filename

        fslroi.inputs.in_file   = raw_pwi_filename
        fslroi.inputs.roi_file  = ii_filename
        fslroi.inputs.t_min     = jj;
        fslroi.inputs.t_size    = nCLPairsToAverage;  # Need to find maximum volume

        iwQa.display_command( fslroi.cmdline, verboseFlag )

        fslroi.run()

        fslmaths = fsl.ImageMaths(in_file=fslroi.inputs.roi_file, op_string= '-Tmean', out_file="01.fslroi.mean." + ii_base_filename )
        iwQa.display_command(fslmaths.cmdline)
        fslmaths.run()


    # Merge Mean PWI images into a single file

    iwUtilities.iw_subprocess([ "fslmerge", "-t", out_pwi_filename] + 
                              sorted(glob.glob("01.fslroi.mean.*.nii.gz")),  inArgs.verbose)


    for ii_files in glob.glob("00.fslroi.*.nii.gz"):
        os.remove(ii_files)
        
    for ii_files in glob.glob("01.fslroi.mean.*.nii.gz"):
        os.remove(ii_files)

    return 


def calc_pwi( clPairs, pwi, out_cl_filename ):

    subprocess.call(["ImageMath","4", pwi, "TimeSeriesSimpleSubtraction", clPairs])

    mean_pwi( pwi, out_cl_filename )


def stats( labelFile, pwi, verboseFlag = False, debugFlag = True ):

     if not os.path.isfile(labelFile):
          print "Label file %s does not exist"  % labelFile
          quit()

#$Id: FreeSurferColorLUT.txt,v 1.70.2.7 2012/08/27 17:20:08 nicks Exp $

# No. Label Name:               
#   0   Clear_Label             
#   1   Gastroc_medial          
#   2   Gastroc_lateral         
#   3   Soleus                  
#   4   Peroneus                
#   5   Tibialis_anterior       
#   6   Tibialis_posterior       
#   7   Fibula                   
#   8   Flexor_digitorum_longus 
#   9   Fibularis               
#  10 
# 100   Background 

     labels   = ( ( "gastroc_medial",     1),
                  ( "gastroc_lateral",    2),
                  ( "soleus",             3),
                  ( "peroneous",          4),
                  ( "tibalis_anterior",   5),
                  ( "background",        100) )

     pwiStats  = []

     for ii in labels:

          iiMaskFileName = "mask." + ii[0] + "." + labelFile

          callCommand = ["fslmaths", labelFile, "-thr", str(ii[1]), "-uthr", str(ii[1]), "-bin", iiMaskFileName ]
          iwUtilities.iw_subprocess(callCommand, verboseFlag)

          callCommand = ["fslstats","-t", pwi, "-k", iiMaskFileName, "-M"]

          if inArgs.verbose or inArgs.debug:
              print " ".join(callCommand)          

          fslstats = subprocess.Popen(callCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
          rawOutput = fslstats.communicate()[0]

          output    = map(float, rawOutput.rstrip().split())

          pwiStats.append(output)

          if not inArgs.debug:
              os.remove(iiMaskFileName)

     raw_string = str(pwiStats)
     print raw_string.replace("[","{").replace("]","}")



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
     parser.add_argument("--raw",           help="Raw pCASL data" )
     parser.add_argument("--cl",            help="Control label pair only time series")
     parser.add_argument("--nclavg",        help="Number of CL pairs to average", nargs= "*", type = int, default = [2] )
     parser.add_argument("--pwi",           help="Pwi file name", default="pwi.nii.gz" )
     parser.add_argument("--m0",            help="M0 image" )
     parser.add_argument("--m0_mask",       help="M0 mask" )
     parser.add_argument("--m0_scale",      help="M0 scale (default = 0.00001)", type=float, default=0.0001 )
     parser.add_argument("--labels",        help="Labels" )
     parser.add_argument("-d","--display",  help="Display Results", action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",      action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",      action="store_true", default=False )
     parser.add_argument("--clean",         help="Clean directory by deleting intermediate files",      action="store_true", default=False )
     parser.add_argument("--qi",            help="QA inputs",      action="store_true", default=False )
     parser.add_argument("--qo",            help="QA outputs",      action="store_true", default=False )
     parser.add_argument("-r", "--run",     help="Run processing pipeline",      action="store_true", default=False )
     parser.add_argument("--stats",         help="Measure PWI muscle means",      action="store_true", default=False )

     skip = [ 1, 7 ] 

     inArgs = parser.parse_args()

     if inArgs.debug:
         print "inArgs.pwi       = " +  str(inArgs.pwi)
         print "inArgs.m0_mask   = " +  str(inArgs.m0_mask)
         print "inArgs.m0_scale  = " +  str(inArgs.m0_scale)
         print "inArgs.nclavg    = " +  str(inArgs.nclavg)
         print "inArgs.display   = " +  str(inArgs.display)
         print "inArgs.debug     = " +  str(inArgs.debug)
         print "inArgs.debug     = " +  str(inArgs.verbose)

     input_files = [[ inArgs.cl,     ":colormap=grayscale:grayscale=0,4096" ],
                    [ inArgs.m0_mask, ":colormap=jet:opacity=0.5" ]]

     optional_files = [[ "t2w.nii.gz",            ":colormap=grayscale:grayscale=0,3096" ]];

     output_files   = [[ inArgs.pwi,            ":colormap=heat:heatscale=0,50,100:opacity=0.4"]]

     # Quality Assurance input
     #
         
     if  inArgs.qi:
         iwQa.qa_exist( input_files, True )
         iwQa.freeview( input_files )    
     # Run    
     # 
   
     if  inArgs.run:

         if  iwQa.qa_input_files( input_files, False):

             # Realign images
             #mcflirt_filename = mcflirt( inArgs.cl, inArgs.verbose )
             #plot_motion_parameters( inArgs.cl, inArgs.verbose )


             mean_m0 = calc_mean_m0( inArgs.m0, inArgs.m0_mask, inArgs.verbose, inArgs.debug)

             print mean_m0

             #
             # Blood im
             # 
             pwi_filename = 'spwi_02.' + inArgs.cl
             subprocess.call(["ImageMath","4", pwi_filename, "TimeSeriesSimpleSubtraction", inArgs.cl ])

             iwUtilities.iw_subprocess([ "fslmaths", pwi_filename, "-div",  str(mean_m0), "-div", 
                                         str(inArgs.m0_scale), pwi_filename ], inArgs.verbose)
    

             out_pwi_filename  = "spwi_" + str(2*inArgs.nclavg[0]).rjust(2,'0') + "." + inArgs.cl
             mean_pwi( pwi_filename, inArgs.nclavg[0], out_pwi_filename, inArgs.verbose )

             #  iwUtilities.iw_subprocess([ "fslmaths", out_pwi_filename, "-abs",  "place." + out_pwi_filename ], inArgs.verbose)


             #  Process data as if PLACE Fat Filtering did not exist
             #

             # iwUtilities.iw_subprocess([ "fslmaths", pwi_filename, "-abs",  "abs." + pwi_filename ], inArgs.verbose)

             # out_pwi_filename  = "abs.spwi_" + str(2*inArgs.nclavg[0]).rjust(2,'0') + ".nii.gz"
             #  mean_pwi( "abs." + pwi_filename, inArgs.nclavg[0], out_pwi_filename, inArgs.verbose )


     
         else:
             print "Unable to run mskPcasl.py. Failed input QA."
             iwQa.qa_exist( input_files, True )
             print


     # Quality Assurance output
     #

     if  inArgs.qo:
         iwQa.freeview( optional_files + output_files, True )    

     

     if inArgs.stats:

         stats( inArgs.labels, inArgs.pwi )
