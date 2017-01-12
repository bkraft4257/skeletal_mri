#!/usr/bin/env python

"""

"""
import time
import sys      
import os                                               # system functions
import glob
import shutil
import distutils

import argparse
import subprocess
import iwQa
import iwUtilities    as util
import iw_labels    
import iw_image_stats

import numpy        as np
import nibabel      as nb
import pandas       as pd
import matplotlib.pyplot   as plt


def figures():

     zoom_factor = 1
     results_mbf = os.path.join(results_directory, 'syn.rsmbf_To_mask.muscle.nii.gz')
     results_t2w = os.path.join(results_directory, 't2w.nii.gz')
     figure_montage   = os.path.abspath(os.path.join( figures_directory, 'mbf_montage.png' ))

     if inArgs.verbose:
          util.print_stage("Figures", inArgs.verbose )

     pcaslOptions=":colormap=heat:heatscale=0,500:opacity=.70:smoothed=1"

     tmp_directory    = os.path.abspath( os.path.join( figures_directory, 'tmp'))
     
     util.mkcd_dir( [ figures_directory, tmp_directory ], True  )

     util.iw_subprocess([ 'fslsplit',  results_mbf, 'time', '-t' ] ,  inArgs.verbose, inArgs.verbose)

     glob_files =  sorted( glob.glob( str("time*.nii.gz") ) )
     print(glob_files)

     for jj, ii in enumerate( glob_files ):
                    
          ii_png = ii.replace('.nii.gz','.png')

          print(ii_png)

          if not os.path.exists( ii_png  ):

               util.iw_subprocess( [ 'freeview', 
                                     ii + pcaslOptions + ":visible=0",
                                     results_t2w + ":colormap=grayscale:grayscale=0,1500", 
                                     ii + pcaslOptions,
                                     '--zoom', zoom_factor, '--viewport', 'axial', '--colorscale',
                                     '--screenshot', ii_png, 1.0, '--quit' 
                                     ], inArgs.verbose, inArgs.verbose)
               
               command = [ 'convert', ii_png, '-pointsize', str(32),  '-draw', 
                           ' \"gravity south fill white  text 1,11 \' ' +  str(jj) + ' \'\" ', 'labeled.' + ii_png ]
               
               pipe = subprocess.Popen( " ".join(command), shell=True, stdout=subprocess.PIPE)
               

     # Create Montage
 
     time.sleep(5)


     os.chdir(figures_directory)
     glob_string = tmp_directory + '/'+ str("labeled*.png")

     png_labeled_time_points  =  sorted( glob.glob( glob_string ))

     print("")
     print(png_labeled_time_points)
     print("")


     util.iw_subprocess( [  'montage', '-background', 'black',  '-resize', '50%', '-mode', 'concatenate', '-tile', '4x1' ] + png_labeled_time_points +
                         [ figure_montage ], inArgs.verbose, inArgs.verbose)

     util.iw_subprocess( [  'display', figure_montage ] )



#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     usage = "usage: %prog [options] arg1 arg2"

     parser = argparse.ArgumentParser(prog='msk_pcasl_recon')

     parser.add_argument("--in_dir",           help="Input  directory", default = os.getcwd() )
     parser.add_argument("--out_dir",          help="Output directory (absolute or relative to inpput directory)", default = '../' )
     parser.add_argument("--results_dir",      help="Results directory (absolute or relative to input directory)", default = '../results' )
     parser.add_argument("--figures_dir",      help="Figures directory (absolute or relative to input directory)", default = '../figures' )

     parser.add_argument("-d","--display",  help="Display Results",  action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",     action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",       action="store_true", default=False )

     parser.add_argument("--qi",            help="QA inputs",        action="store_true", default=False )

     parser.add_argument("--qo",            help="QA outputs. Use --qo_stage to select specific output stages to QA",        action="store_true", default=False )
     parser.add_argument("--qo_stage",      help="Stages to run in the processing pipeline", type=int, nargs='*', default = [ 3, 7 ], choices=[3,5,7]  )

     parser.add_argument("--qr",            help="QA results",       action="store_true", default=False )


     parser.add_argument("--figures",       help="Save png figures", action="store_true", default=False )
     parser.add_argument("--results",       help="Gather results after QC",   action="store_true", default=False )

     parser.add_argument("-r", "--run",     help="Run processing pipeline",      action="store_true", default=False )

     parser.add_argument("--run_stage",     help="Stages to run in the processing pipeline", type=int, nargs='*', default = [ 1,2,3,4,5,6,7,8 ],
                         choices = [ 1,2,3,4,5,6,7,8 ] )

     parser.add_argument("--recon",            help="Recon method (default = offline)", choices=['offline', 'online'],  default = 'offline')
     parser.add_argument("--recon_raw_images", help="Recon raw images (default = raw.nii.gz) ",  default = 'raw.nii.gz')
     parser.add_argument("--recon_raw_data",   help="Recon raw data (default = meas_raw.dat)",    default = 'meas_raw.dat')
     parser.add_argument("--recon_mode",       help="Recon method (default = sos )", choices=['sos', 'vbc'],  default = 'sos')
     parser.add_argument("--recon_flip",       help="Recon flip flag (default = [ 1,0,1 ])",  nargs=3, default = [ 1,0,1])
     parser.add_argument("--recon_filter",     help="Recon bandpass filter for mid to low frequency noise (default=False)",      action="store_true", default=False )
     parser.add_argument("--recon_rotate",     help="Recon rotation in increments of 90 degrees (default=0)",  nargs=1, default = 0)

     inArgs = parser.parse_args()


     #
     #
     #

     input_directory = os.path.abspath(inArgs.in_dir)

     if os.path.isabs(inArgs.out_dir):
          output_directory = inArgs.out_dir
     else:
          output_directory = os.path.abspath(os.path.join(input_directory, inArgs.out_dir )) 


     if os.path.isabs(inArgs.results_dir):
          results_directory = inArgs.results_dir
     else:
          results_directory = os.path.abspath(os.path.join(input_directory, inArgs.results_dir )) 


     if os.path.isabs(inArgs.figures_dir):
          figures_directory = inArgs.figures_dir
     else:
          figures_directory = os.path.abspath(os.path.join(input_directory, inArgs.figures_dir )) 



     if inArgs.debug:

          if inArgs.verbose:
               util.print_stage("Debug dump initialization ", inArgs.verbose )

          print
          print "inArgs.in_dir     = " +  inArgs.in_dir
          print "inArgs.in_dir     = " +  inArgs.out_dir
          print 
          print "input_directory   = " + input_directory
          print "output_directory  = " + output_directory
          print "results_directory = " + results_directory
          print "figures_directory = " + figures_directory
          print
          print "inArgs.run_stage  = " +  str(inArgs.run_stage)
          print "inArgs.qo_stage  = " +  str(inArgs.qo_stage)
          print
          print input_directory
          print output_directory
          print
          print "inArgs.debug     = " +  str(inArgs.debug)
          print "inArgs.verbose   = " +  str(inArgs.verbose)
          print



     stage_directory = [ os.path.abspath( os.path.join( output_directory, '00-rename'        )),
                         os.path.abspath( os.path.join( output_directory, '01-recon'         )),
                         os.path.abspath( os.path.join( output_directory, '02-extract'       )),
                         os.path.abspath( os.path.join( output_directory, '03-n4'            )),
                         os.path.abspath( os.path.join( output_directory, '04-mcf'           )),
                         os.path.abspath( os.path.join( output_directory, '05-pwi'           )),
                         os.path.abspath( os.path.join( output_directory, '06-register'      )),
                         os.path.abspath( os.path.join( output_directory, '07-stats'         )),
                         os.path.abspath( os.path.join( output_directory, '08-curve_fitting' ))   ] 

     sm_lookup_table =  os.path.abspath( os.path.join( os.getenv('MSK_MRI_DATA'), 'sm.labels.muscle.FreesurferLUT.txt' ))
     util.verify_that_file_exists( sm_lookup_table )


     # ---- Figures
     # 

     figures()


