#!/usr/bin/env python

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
import _utilities    as util
import labels    

import numpy        as np
import nibabel      as nb
import pandas       as pd
import matplotlib.pyplot   as plt

def stage7_stats():

     if inArgs.verbose:
          util.print_stage("Entering Stage 7 - Calculate statistics ", inArgs.verbose )
               
          
     #
     # Verify that all input files exist
     #


     util.verify_inputs( stage7_input_files )
          
     #
     # Make directory if it doesn't exist and create links to access data
     #

     util.mkcd_dir( stage7_directory )

     util.link_inputs(   stage7_input_files, stage7_directory )

     #
     #
     #

     util.iw_subprocess(["antsApplyTransforms","-d",3,"-i", "labels.t2w.nii.gz", "-o", 
                         "labels.mbf.nii.gz","-r", "n4.m0.nii.gz",  "-t", "identity", "-n", "MultiLabel"], 
                        inArgs.verbose, inArgs.verbose)

     util.iw_subprocess([  "fslmaths", "mask.center_slice.t2w.nii.gz", "-dilM", "dilM.mask.center_slice.t2w.nii.gz" ],
                        inArgs.verbose, inArgs.verbose )

     util.iw_subprocess(["antsApplyTransforms","-d",3, "-t", "identity", 
                         "-r", "n4.m0.nii.gz", 
                         "-i", "dilM.mask.center_slice.t2w.nii.gz", 
                         "-o", "mask.center_slice.m0.nii.gz", "-n", "Multilabel" ], 
                        inArgs.verbose, inArgs.verbose)

     util.iw_subprocess([  "fslmaths", "mask.center_slice.m0.nii.gz", "-bin", "mask.center_slice.m0.nii.gz" ],
                        inArgs.verbose, inArgs.verbose )

     #
     #
     #

     util.iw_subprocess([  "gunzip", "-f","mask.center_slice.m0.nii.gz"], inArgs.verbose, inArgs.verbose )

     cmd = ["matlab", "-nodisplay", "-nosplash", "-nodesktop", "-r", "iwQualityBackgroundMask('mask.center_slice.m0.nii', 0, [100 200] );  exit"]
     
     util.iw_subprocess(cmd, inArgs.verbose, inArgs.verbose )
     
     util.iw_subprocess([  "gzip", "-f", "mask.center_slice.m0.nii"], inArgs.verbose, inArgs.verbose )
     util.iw_subprocess([  "gzip", "-f", "qaBackgroundLabel.nii"], inArgs.verbose, inArgs.verbose )
     
     util.iw_subprocess([  "fslmaths", "center_slice.labels.mbf.nii.gz", "-uthr","5", "-bin", "center_slice.muscle.mbf.nii.gz" ], 
                        inArgs.verbose, inArgs.verbose )


     #
     #
     #
     

     try:
          df_stats = iw_labels.measure_image_stats( 'center_slice.labels.mbf.nii.gz', 'm0_To_t2w.slice_mean.mbf.nii.gz', [1,2,3,4,5], True)
          df_stats.to_csv('m0_To_t2w.slice_mean.mbf.csv', index=False)                 
     except:
          raise

     try:
          df_stats = iw_labels.measure_image_stats( 'center_slice.muscle.mbf.nii.gz', 'm0_To_t2w.slice_mean.mbf.nii.gz', [1,2,3,4,5])
          df_stats.to_csv('m0_To_t2w.total_slice_mean.mbf.csv', index=False)                 
     except:
          raise
     
     try:
          df_stats = iw_labels.measure_image_stats( 'center_slice.muscle.mbf.nii.gz', 'm0_To_t2w.slice_mean.norm_m0.tissue.nii.gz', [1,2,3,4,5])
          df_stats.to_csv('m0_To_t2w.slice_mean.norm_m0.tissue.csv', index=False)                 
     except:
          raise

     try:
          df_stats = iw_labels.measure_image_stats( 'center_slice.muscle.mbf.nii.gz', 'm0_To_t2w.slice_mean.norm_m0.tissue.nii.gz', [1,2,3,4,5])
          df_stats.to_csv('m0_To_t2w.total_slice_mean.norm_m0.tissue.csv', index=False)                 
     except:
          raise

     try:
          df_stats = iw_labels.measure_image_stats( 'qaBackgroundLabel.nii.gz', 'm0_To_t2w.slice_mean.mbf.nii.gz', [100,200])
          df_stats.to_csv('qa_background.slice_mean.mbf.csv', index=False)                 
     except:
          raise

     #
     # Verify that all output files were created
     #
     
     util.verify_outputs( stage7_output_files ) 
          
def stage8_curve_fitting():

     if inArgs.verbose:
          util.print_stage("Entering Stage 8 - Curve Fitting ", inArgs.verbose )


def figures():

     if inArgs.verbose:
          util.print_stage("Figures", inArgs.verbose )

     util.verify_inputs(figure_inputs)

     pcaslOptions=":colormap=heat:heatscale=0,200:opacity=.70:smoothed=1"

     tmp_directory    = os.path.abspath( os.path.join( figures_directory, 'tmp'))
     
     util.mkcd_dir( [ figures_directory, tmp_directory ]  )
     
     util.iw_subprocess([ 'fslsplit',  results_mbf, 'time', '-t' ] ,  inArgs.verbose, inArgs.verbose)
               
     for jj, ii in enumerate( sorted( glob.glob( str("time*.nii.gz") ) ) ) :
                    
          ii_png = ii.replace('.nii.gz','.png')
               
          if not os.path.exists( ii_png  ):

               util.iw_subprocess( [ 'freeview', 
                                     ii + pcaslOptions + ":visible=0",
                                     results_t2w + ":colormap=grayscale:grayscale=0,1500", 
                                     ii + pcaslOptions,
                                     '--zoom', 2.8, '--viewport', 'axial', '--colorscale',
                                     '--screenshot', ii_png, 1.0, '--quit' 
                                     ], inArgs.verbose, inArgs.verbose)
               
               command = [ 'convert', ii_png, '-pointsize', str(32),  '-draw', 
                           ' \"gravity south fill white  text 1,11 \' ' +  str(jj) + ' \'\" ', 'labeled.' + ii_png ]
               
               pipe = subprocess.Popen( " ".join(command), shell=True, stdout=subprocess.PIPE)
               

     png_labeled_time_points     =  sorted( glob.glob( str("labeled*.png") ) )

     util.iw_subprocess( [  'montage', '-background', 'black',  '-resize', '50%', '-mode', 'concatenate' ] + png_labeled_time_points +
                         [ figure_montage ], inArgs.verbose, inArgs.verbose)

     util.iw_subprocess( [  'convert', '-delay', '20' ] + png_labeled_time_points +
                         [ figure_animation ], inArgs.verbose, inArgs.verbose)


     shutil.copy(png_labeled_time_points[0],  figure_first )
     shutil.copy(png_labeled_time_points[-1], figure_last )

     util.verify_outputs(figure_outputs)


def qo_stage3():

     stage3_directory = stage_directory[3];

     os.chdir( stage3_directory )
     util.freeview( [ [ os.path.abspath( os.path.join( stage3_directory, 'n4.m0.nii.gz'      )), ':colormap=gray' ], 
                             [ os.path.abspath( os.path.join( stage3_directory,  'n4.cl.nii.gz'      )), ':colormap=gray' ], 
                             [ os.path.abspath( os.path.join( stage3_directory,  'mask.n4.m0.nii.gz' )), ':colormap=jet:opacity=0.5' ] 
                             ], True, inArgs.debug )


def qo_stage5():

     stage3_directory = stage_directory[5];

     os.chdir( stage5_directory )
     util.freeview( [ [ os.path.abspath( os.path.join( stage5_directory, 'n4.m0.nii.gz'      )), ':colormap=gray' ], 
                      [ os.path.abspath( os.path.join( stage5_directory, 'mask.n4.m0.nii.gz' )), ':colormap=jet:opacity=0.5' ],
                      [ os.path.abspath( os.path.join( stage5_directory, 'slice_mean.mbf_1-3.nii.gz' )), ':colormap=heat:heatscale=0,150:visible=0' ],
                      [ os.path.abspath( os.path.join( stage5_directory, 'slice_mean.mbf_1-4.nii.gz' )), ':colormap=heat:heatscale=0,150:visible=0' ],
                      [ os.path.abspath( os.path.join( stage5_directory, 'slice_mean.mbf_1-5.nii.gz' )), ':colormap=heat:heatscale=0,150:visible=0' ],
                      [ os.path.abspath( os.path.join( stage5_directory, 'slice_mean.mbf.nii.gz' )),     ':colormap=heat:heatscale=0,150:visible=1' ],

                             ], True, inArgs.debug )

def qo_stage7():

     os.chdir( stage_directory[7] )
               
     cmd = [ [ 't2w.nii.gz',        ':colormap=gray'],
             [ 'iw_labels.t2w.nii.gz', ':colormap=lut:lut=' + sm_lookup_table + ':opacity=0.5:visible=0' ],
             [ 'center_slice.labels.mbf.nii.gz', ':colormap=lut:lut=' + sm_lookup_table + ':opacity=0.5:visible=0' ],
             [ 'qaBackgroundLabel.nii.gz', ':colormap=jet:opacity=0.25' ],
             [ 'm0_To_t2w.slice_mean.mbf.nii.gz', ':colormap=heat:heatscale=0,150' ]
            ]
     
     util.freeview( cmd, True, inArgs.debug)


def qo_results():

     os.chdir( results_directory )
               
     cmd = [ [ 'qaBackgroundLabel.nii.gz', ':colormap=jet:opacity=0.25:visible=0' ],             
             [ 't2w.nii.gz',        ':colormap=gray'],
             [ 'labels.t2w.nii.gz', ':colormap=lut:lut=' + sm_lookup_table + ':opacity=0.5:visible=0' ],
             [ 'center_slice.labels.mbf.nii.gz', ':colormap=lut:lut=' + sm_lookup_table + ':opacity=0.5:visible=0' ],
             [ 'log.m0_To_t2w.slice_mean.mbf.nii.gz', ':colormap=jet:colorscale=200,800:visible=0' ],
             [ 'm0_To_t2w.slice_mean.mbf.nii.gz', ':colormap=heat:heatscale=0,150' ]
            ]
     
     util.freeview( cmd, True, inArgs.debug )

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



     stage_directory = [ os.path.abspath( os.path.join( output_directory, '00a-rename'        )), # Not used
                         os.path.abspath( os.path.join( output_directory, '01a-recon'         )), # Not used
                         os.path.abspath( os.path.join( output_directory, '02a-extract'       )),
                         os.path.abspath( os.path.join( output_directory, '03a-n4'            )),
                         os.path.abspath( os.path.join( output_directory, '04a-mcf'           )),
                         os.path.abspath( os.path.join( output_directory, '05a-pwi'           )),
                         os.path.abspath( os.path.join( output_directory, '06a-register'      )),
                         os.path.abspath( os.path.join( output_directory, '07a-stats'         )),
                         os.path.abspath( os.path.join( output_directory, '08a-curve_fitting' ))   ] 

     sm_lookup_table =  os.path.abspath( os.path.join(  os.path.dirname(os.path.abspath(__file__)),
                                                        'priorities.labels.muscle.FreesurferLUT.txt' ))
     util.verify_that_file_exists( sm_lookup_table )

     #
     # Check input files
     #

     raw_filename = os.path.abspath( os.path.join( input_directory, 'raw.nii.gz' ))

     input_files =      [   raw_filename,
                            os.path.abspath( os.path.join( input_directory, 'mask.muscle.nii.gz' )), 
                            os.path.abspath( os.path.join( input_directory, 'mask.center_slice.t2w.nii.gz' )), 
                            os.path.abspath( os.path.join( input_directory, 'labels.t2w.nii.gz' )), 
                            os.path.abspath( os.path.join( input_directory, 't2w.nii.gz' ))]

     #
     # Quality Assurance of Inputs
     #
         
     if  inArgs.qi:
          pass


     #
     # Run    
     # 

     stage2_directory     = stage_directory[2];

     stage2_input_files   = [ raw_filename ]

     stage2_output_files   = [ os.path.abspath( os.path.join( stage2_directory, 'cl.nii.gz'           )),
                               os.path.abspath( os.path.join( stage2_directory, 'm0.nii.gz'           ))
                             ]                                                     

     if  inArgs.run and ( 2 in inArgs.run_stage ):

          if inArgs.verbose:
               util.print_stage("Entering Stage 2 - Extraction ", inArgs.verbose )
          
          util.verify_inputs(stage2_input_files, inArgs.debug)

          util.mkcd_dir( stage2_directory )

          util.iw_subprocess( [ 'fslroi', stage2_input_files[0], os.path.join( stage2_directory, 'cl.nii.gz'), 1, -1],
                              inArgs.verbose, inArgs.verbose )

          util.iw_subprocess( [ 'fslroi', stage2_input_files[0], os.path.join( stage2_directory, 'm0.nii.gz'), 0, 1],
                              inArgs.verbose, inArgs.verbose )

     #
     #
     #


     stage3_directory     = stage_directory[3];

     stage3_input_files   = [ os.path.abspath( os.path.join( stage2_directory, 'm0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage2_directory, 'cl.nii.gz'      )),
                              ] 

     stage3_output_files   = [ os.path.abspath( os.path.join( stage3_directory, 'n4.m0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage3_directory,  'n4.cl.nii.gz'      )),
                              os.path.abspath( os.path.join( stage3_directory,  'mask.n4.m0.nii.gz' ))
                              ] 


     if  inArgs.run and ( 3 in inArgs.run_stage ):

          if inArgs.verbose:
               util.print_stage("Entering Stage 3 - N4 Correction ", inArgs.verbose )

          util.verify_inputs(stage3_input_files, inArgs.debug)

          #
          # Make directory, create links, and copy data for local processing
          #

          util.mkcd_dir( stage3_directory )
          util.link_inputs(  stage3_input_files,    stage3_directory)

          cmd = [[ 'N4BiasFieldCorrection', '-d', 3, '-i', 'm0.nii.gz', '-r', '-o', '[', 'n4.m0.nii.gz', ',', 'n4.bias.m0.nii.gz', ']',  '-v', '-s'  ],
                 [ 'fslmaths', 'n4.bias.m0.nii.gz', '-recip', '-mul', 'cl.nii.gz', 'n4.cl.nii.gz' ]]

          for ii in cmd:
               util.iw_subprocess(ii, verbose_flag=inArgs.verbose, debug_flag=inArgs.debug )

          # Create mask

          labels.create_mask('n4.m0.nii.gz', n4_flag=False, noglc_flag=True, verbose=inArgs.verbose)

          util.verify_outputs(stage3_output_files)


     #
     #
     #

     stage4_directory     = stage_directory[4];

     stage4_input_files   = [ os.path.abspath( os.path.join( stage_directory[3], 'n4.m0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[3], 'n4.cl.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[3], 'mask.n4.m0.nii.gz' ))
                            ] 

     stage4_output_files   = [ os.path.abspath( os.path.join( stage4_directory, 'mcf.n4.cl.nii.gz'          )),
                               os.path.abspath( os.path.join( stage4_directory, 'mcf.n4.cl.csv'             ))
                             ] 


     if  inArgs.run and ( 4 in inArgs.run_stage ):
 
          if inArgs.verbose:
               util.print_stage("Entering Stage 4 - Motion Correction ", inArgs.verbose )
               

          #
          # Verify that all input files exist
          #


          util.verify_inputs(stage4_input_files, inArgs.debug)

          #
          # Make directory, create links, and copy data for local processing
          #

          util.mkcd_dir( stage_directory[4] )
          util.link_inputs(  stage4_input_files,    stage4_directory)

          util.iw_subprocess( [ 'mcflirt', '-in', 'n4.cl', '-out', 'mcf.n4.cl',  '-reffile', 
                                'n4.m0.nii.gz', '-plots', '-report', '-rmsrel', '-rmsabs' ],
                              inArgs.verbose, inArgs.verbose )
          
          util.iw_subprocess( [ 'fslmerge', '-x', 'qa.mcf.n4.cl.nii.gz', 'n4.cl.nii.gz', 'mcf.n4.cl.nii.gz'],
                              inArgs.verbose, inArgs.debug )

          # This is a simple way to reformat the data from what is created with FSL to a simple CSV file

          mcf_par_data = pd.read_csv('mcf.n4.cl.par', names = ['roll','pitch','yaw','x','y','z'], delim_whitespace=True)
          mcf_par_data.to_csv('mcf.n4.cl.csv', index=False, float_format='%.8f')
          
          #
          # Plot data in pandas
          #
          # >> Translations (x,y,z) [mm] 
          # >> Rotation Angles (x,y,z) [rads] 
          
          if True:
               translation = mcf_par_data[['x','y','z']]
               ax     = translation.plot(title='Translation')
               ax.set_xlabel("index [-]")
               ax.set_ylabel("translation [mm]")
               figure = ax.get_figure()
               
               figure.savefig('translation.n4.cl.png', bbox_inches=0)
               
               rotation = mcf_par_data[['roll','pitch','yaw']]
               ax     = rotation.plot(title='Rotation')
               ax.set_xlabel("index [-]")
               ax.set_ylabel("rotation [rads]")
               figure = ax.get_figure()
               figure.savefig('rotation.n4.cl.png', bbox_inches=0)
               
               
               df_abs_rms_mcf = pd.read_csv('mcf.n4.cl_abs.rms', names = ['rms'], delim_whitespace=True)
               df_rel_rms_mcf = pd.read_csv('mcf.n4.cl_rel.rms', names = ['rms'], delim_whitespace=True)
               
               data_abs = df_abs_rms_mcf.as_matrix(columns=['rms'])
               data_rel = df_rel_rms_mcf.as_matrix(columns=['rms'])
               
               npoints  = int(df_abs_rms_mcf.count(axis=0))
               rel_npoints  = int(df_rel_rms_mcf.count(axis=0))

               marker_size=200
               ymax = 1.1
               
          if False: 
                    
               fig = plt.figure()
               plt.subplot(211)
               plt.plot( np.arange(0,npoints/2,0.5), data_abs,'r.') # , title='Absolute RMS')
               
               ax = fig.gca()
               ax.set_xticks(np.arange(0,npoints/2,0.5))
               plt.grid()
               
               plt.title('Absolute RMS')
               plt.xlabel('index [-]')
               plt.ylabel('abs_rms [-]')
               plt.tight_layout(pad=4.0, w_pad=0.5, h_pad=3.0)
               
               x_rel = np.arange(0,npoints/2,0.5)
               
               plt.subplot(212)
               plt.plot(x_rel[1:npoints], data_rel, 'b.') # , title='Absolute RMS')
               plt.title('Relative RMS')
               plt.xlabel('index [-]')
               plt.ylabel('rel_rms [-]')
               ax = fig.gca()
               ax.set_xticks(np.arange(0,npoints/2,1))
               plt.grid()
               
               plt.savefig('rms.n4.cl.png', bbox_inches=0)
               
               util.iw_subprocess( [  'display', 'rms.n4.cl.png' ] )
               #
               #
               #
               
          if True:
               data_abs = df_abs_rms_mcf.as_matrix(columns=['rms'])
               
               fig2 = plt.figure()
               plt.subplot(211)
               
               plt.scatter( np.arange(0,npoints/2,.5), data_abs, c='b', s=marker_size) # , title='Absolute RMS')
               
               plt.title('Absolute RMS')
               plt.xlabel('index [-]')
               plt.ylabel('abs_rms [-]')
               ax = fig2.gca()
               ax.set_xticks(np.arange(0,npoints/2,1))
               plt.grid()
               
               
               plt.subplot(212)

               data_abs = df_abs_rms_mcf.as_matrix(columns=['rms'])               
               diff2 = data_abs[::2]-data_abs[1::2]
               diff2[ diff2 >  1 ] = 1
               diff2[ diff2 < -1 ] = -1
               plt.scatter(np.arange(0,npoints/2,1), diff2, c='r', s=marker_size) # , title='Absolute RMS')
               
               plt.title('2 Difference')
               plt.xlabel('index [-]')
               plt.ylabel('abs_rms [-]')
               ax = fig2.gca()
               ax.set_xticks(np.arange(0,npoints/2,1))
               ax.set_ylim([-ymax,ymax])
               plt.grid()
               
               plt.tight_layout(pad=4.0, w_pad=0.5, h_pad=1.0)
               plt.savefig('diff_abs_rms.n4.cl.png', bbox_inches=0)
               
          #
          # Verify Output files
          #

          util.verify_outputs(stage4_output_files)


     #
     #
     #

     stage5_directory     = stage_directory[5];

     stage5_input_files   = [ os.path.abspath( os.path.join( stage_directory[4], 'n4.m0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[4], 'mask.n4.m0.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[4], 'n4.cl.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[4], 'mcf.n4.cl.nii.gz'  )),
                              os.path.abspath( os.path.join( stage_directory[4], 'mcf.n4.cl_abs.rms')) 
                              ]

     stage5_output_files   = [ os.path.abspath( os.path.join( stage5_directory,     'blood.nii.gz'   )),   
                               os.path.abspath( os.path.join( stage5_directory,     'fat.nii.gz'     )),     
                               os.path.abspath( os.path.join( stage5_directory,     'mbf.index'      ))
                               ] 


     if  inArgs.run and ( 5 in inArgs.run_stage ):

          if inArgs.verbose:
               util.print_stage("Entering Stage 5 - Calculating Muscle Blood Flow", inArgs.verbose )
               

          #
          # Verify that all input files exist
          #


          util.verify_inputs(stage5_input_files, inArgs.debug)


          #
          # Make directory, create links, and copy data for local processing
          #

          util.mkcd_dir( [ stage5_directory ] )
          util.link_inputs(  stage5_input_files,    stage5_directory)

          #
          #
          #

          df_abs_rms_mcf = pd.read_csv('mcf.n4.cl_abs.rms', names = ['rms'], delim_whitespace=True)
          data_abs = df_abs_rms_mcf.as_matrix(columns=['rms'])[:,0]
          diff2 = abs(data_abs[::2]-data_abs[1::2])
          sort_index = np.argsort(diff2)
          
          print(diff2)
          print(sort_index)

          cl_filename = 'n4.cl.nii.gz'

          nii_cl  = nb.load( cl_filename )
          cl      = nii_cl.get_data()

          pwi_array = cl[:,:,:,0::2] -  cl[:,:,:,1::2];

          sum_pwi_array = np.sum( np.absolute(pwi_array), axis=(0,1,2))
          sort_index = np.asarray(np.argsort( sum_pwi_array))

          print(sum_pwi_array)
          print(sum_pwi_array[sort_index])
          print(sort_index)
          
          sorted_pwi_array = pwi_array[:,:,:,sort_index]
          cumsum_pwi_array = np.cumsum( sorted_pwi_array, axis=3)

          print(cumsum_pwi_array.shape)

          for ii in range(0,7):
               cumsum_pwi_array[:,:,:,ii] = cumsum_pwi_array[:,:,:,ii]/(ii+1)

          nb.save( nb.Nifti1Image( sorted_pwi_array, None, nii_cl.get_header()), 'pwi.nii.gz')
          nb.save( nb.Nifti1Image( cumsum_pwi_array, None, nii_cl.get_header()), 'cumsum.pwi.nii.gz')
          
          #
          # Verify Output files
          #

 
          # util.verify_outputs(stage5_output_files)


     #
     #
     #

     stage6_directory     = stage_directory[6]

     stage6_input_files   = [ os.path.abspath( os.path.join( stage_directory[3], 'n4.m0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[3], 'mask.n4.m0.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[5], 'mbf.index' )), 
                              
                              os.path.abspath( os.path.join( input_directory, 'mask.muscle.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 'labels.t2w.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 't2w.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[5], 'slice_mean.norm_m0.tissue.nii.gz' )),
                              os.path.abspath( os.path.join( stage_directory[5], 'slice_mean.mbf.nii.gz' )) ] 

     stage6_output_files   = [ os.path.abspath( os.path.join( stage6_directory, 'm0_To_t2w_0Warp.nii.gz'              )),
                               os.path.abspath( os.path.join( stage6_directory, 'm0_To_t2w.slice_mean.mbf.nii.gz'     )),
                               os.path.abspath( os.path.join( stage6_directory, 'm0_To_t2w.slice_mean.norm_m0.tissue.nii.gz'     )),
                               os.path.abspath( os.path.join( stage6_directory, 'labels.mbf.nii.gz'                   )),
                               os.path.abspath( os.path.join( stage6_directory, 'muscle.label.mbf.nii.gz'             )),
                               os.path.abspath( os.path.join( stage6_directory, 'center_slice.muscle.mbf.nii.gz'      ))  ]

     if  inArgs.run and ( 6 in inArgs.run_stage ):

          if inArgs.verbose:
               util.print_stage("Entering Stage 6 - Registration", inArgs.verbose )
               

          #
          # Verify that all input files exist
          #


          util.verify_inputs(stage6_input_files)

          #
          # Make directory if it doesn't exist
          #

          util.mkcd_dir( stage6_directory )

          util.link_inputs(stage6_input_files, stage6_directory )

          #
          # Stage 6 : Processing
          #

          cmd = [ os.path.abspath( os.path.join( os.getenv('MSK_SCRIPTS'), 'msk_pcasl_recon_stage6.sh')) ]

          util.iw_subprocess(cmd,  inArgs.verbose, inArgs.verbose )


          #
          # Verify that all output files were created
          #
          
          util.verify_outputs(stage6_output_files)


     #
     # ---- Stage 7 Extract Mean and Standard Deviation from Muscles
     #

     stage7_directory     = stage_directory[7]

     stage7_input_files   = [ os.path.abspath( os.path.join( stage_directory[3], 'n4.m0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[3], 'mask.n4.m0.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[5], 'mbf.index' )), 
                              
                              os.path.abspath( os.path.join( input_directory, 'mask.muscle.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 'labels.t2w.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 't2w.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 'mask.center_slice.t2w.nii.gz' )), 
                              
                              os.path.abspath( os.path.join( stage_directory[6], 'm0_To_t2w.slice_mean.norm_m0.tissue.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[6], 'm0_To_t2w.slice_mean.mbf.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[6], 'center_slice.labels.mbf.nii.gz'     )) ] 
     
     stage7_output_files   = [ os.path.abspath( os.path.join( stage7_directory, 'mask.center_slice.m0.nii.gz'         )),
                               os.path.abspath( os.path.join( stage7_directory, 'qaBackgroundLabel.nii.gz'            )),
                               os.path.abspath( os.path.join( stage7_directory, 'mask.center_slice.m0.nii.gz'         )),
                               os.path.abspath( os.path.join( stage7_directory, 'center_slice.muscle.mbf.nii.gz'      )),
                               os.path.abspath( os.path.join( stage7_directory, 'm0_To_t2w.slice_mean.mbf.csv'        )),
                               os.path.abspath( os.path.join( stage7_directory, 'm0_To_t2w.total_slice_mean.mbf.csv'  )),
                               os.path.abspath( os.path.join( stage7_directory, 'qa_background.slice_mean.mbf.csv'    )),
                               os.path.abspath( os.path.join( stage7_directory, 'labels.mbf.nii.gz'                   )) ]


     if  inArgs.run and ( 7 in inArgs.run_stage ):
          stage7_stats()


     #
     # ---- Stage 8 Curve Fitting of Extracted Time Series Means
     #

     stage8_directory     = stage_directory[8]

     stage8_input_files   = [ os.path.abspath( os.path.join( stage_directory[3], 'n4.m0.nii.gz'      )),
                              os.path.abspath( os.path.join( stage_directory[3], 'mask.n4.m0.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[5], 'mbf.index' )), 
                              
                              os.path.abspath( os.path.join( input_directory, 'mask.muscle.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 'labels.t2w.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 't2w.nii.gz' )), 
                              os.path.abspath( os.path.join( input_directory, 'mask.center_slice.t2w.nii.gz' )), 
                              
                              os.path.abspath( os.path.join( stage_directory[6], 'm0_To_t2w.slice_mean.norm_m0.tissue.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[6], 'm0_To_t2w.slice_mean.mbf.nii.gz' )), 
                              os.path.abspath( os.path.join( stage_directory[6], 'center_slice.labels.mbf.nii.gz'     )) ] 
     
     stage8_output_files   = [ os.path.abspath( os.path.join( stage8_directory, 'mask.center_slice.m0.nii.gz'         )),
                               os.path.abspath( os.path.join( stage8_directory, 'qaBackgroundLabel.nii.gz'            )),
                               os.path.abspath( os.path.join( stage8_directory, 'mask.center_slice.m0.nii.gz'         )),
                               os.path.abspath( os.path.join( stage8_directory, 'center_slice.muscle.mbf.nii.gz'      )),
                               os.path.abspath( os.path.join( stage8_directory, 'm0_To_t2w.slice_mean.mbf.csv'        )),
                               os.path.abspath( os.path.join( stage8_directory, 'm0_To_t2w.total_slice_mean.mbf.csv'  )),
                               os.path.abspath( os.path.join( stage8_directory, 'qa_background.slice_mean.mbf.csv'    )),
                               os.path.abspath( os.path.join( stage8_directory, 'labels.mbf.nii.gz'                   )) ]


     if  inArgs.run and ( 8 in inArgs.run_stage ):
          stage8_curve_fitting()

     #
     # ---- Gather Results
     # 

     result_inputs  = [ os.path.abspath( os.path.join( input_directory,  't2w.nii.gz' )),
                        os.path.abspath( os.path.join( input_directory,  'labels.t2w.nii.gz' )),
                        os.path.abspath( os.path.join( stage3_directory, 'mask.n4.m0.nii.gz' )),
                        os.path.abspath( os.path.join( stage7_directory, 'm0_To_t2w.slice_mean.mbf.nii.gz' )),
                        os.path.abspath( os.path.join( stage7_directory, 'm0_To_t2w.slice_mean.mbf.csv' )),
                        os.path.abspath( os.path.join( stage7_directory, 'm0_To_t2w.slice_mean.norm_m0.tissue.csv' )),
                        os.path.abspath( os.path.join( stage7_directory, 'm0_To_t2w.slice_mean.norm_m0.tissue.nii.gz' )),
                        os.path.abspath( os.path.join( stage7_directory, 'mbf.index' )),
                        os.path.abspath( os.path.join( stage7_directory, 'qa_background.slice_mean.mbf.csv' )),
                        os.path.abspath( os.path.join( stage7_directory, 'center_slice.labels.mbf.nii.gz' )),
                        os.path.abspath( os.path.join( stage7_directory, 'qaBackgroundLabel.nii.gz' )),
                       ]

     results_t2w = os.path.abspath( os.path.join( input_directory, 't2w.nii.gz' ))
     results_mbf = os.path.abspath( os.path.join( results_directory, 'm0_To_t2w.slice_mean.mbf.nii.gz' ))

     if  inArgs.results:

          if inArgs.verbose:
               util.print_stage("Results", inArgs.verbose )
          
          util.verify_inputs(result_inputs)
          util.mkcd_dir( results_directory  )
          util.link_inputs(  result_inputs,    results_directory)

          util.iw_subprocess([ 'fslmaths',  results_mbf, '-abs', '-add', 1, '-log', '-mul', 100, 'log.' + 'm0_To_t2w.slice_mean.mbf.nii.gz' ] ,  inArgs.verbose, inArgs.verbose)

     #
     # ---- Figures
     # 
     
     figure_inputs  = [ results_t2w, results_mbf ]

     figure_montage   = os.path.abspath(os.path.join( figures_directory, 'mbf_montage.png' ))
     figure_animation = os.path.abspath(os.path.join( figures_directory, 'mbf_animation.gif' ))
     figure_first     = os.path.abspath(os.path.join( figures_directory, 'mbf_first.png' ))
     figure_last      = os.path.abspath(os.path.join( figures_directory, 'mbf_last.png' ))

     figure_outputs = [ figure_montage, figure_animation, figure_first, figure_last ]

     if  inArgs.figures:
          figures()


     #
     # ---- Quality Assurance output
     #


     if inArgs.qr:
          qo_results()

     if inArgs.qo and 3 in inArgs.qo_stage:
          qo_stage3()

     if inArgs.qo and 5 in inArgs.qo_stage:
          qo_stage5()

     if inArgs.qo and 7 in inArgs.qo_stage:
          qo_stage7()
