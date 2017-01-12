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
import iwQa
import iwUtilities    as util
import iw_labels    
import iw_image_stats

import numpy        as np
import nibabel      as nb
import pandas       as pd
import matplotlib.pyplot   as plt

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

     parser.add_argument("-d","--display",  help="Display Results",  action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",     action="store_true", default=False )

     inArgs = parser.parse_args()


     #
     #
     #

     input_directory = os.path.abspath(inArgs.in_dir)

     stage4_directory     = os.path.abspath( os.path.join(input_directory, '../02-mcflirt'))
     stage4_input_files   = [ os.path.abspath( os.path.join(input_directory, 'raw.nii.gz'   )),
                              os.path.abspath( os.path.join(input_directory, 'm0.nii.gz'   )) ]

     #
     # Make directory, create links, and copy data for local processing
     #

     util.mkcd_dir( stage4_directory, True )
     util.link_inputs(  stage4_input_files,    stage4_directory)

     util.iw_subprocess( [ 'fslroi', stage4_input_files[0], os.path.join( stage4_directory, 'cl.nii.gz'), 1, -1],
                         inArgs.verbose, inArgs.verbose )

     #
     #
     #

     util.iw_subprocess( [ 'mcflirt', '-in', 'cl', '-out', 'mcf.cl',  '-reffile', 
                           'm0.nii.gz', '-plots', '-report', '-rmsrel', '-rmsabs' ],
                         inArgs.verbose, inArgs.verbose )
          
     # This is a simple way to reformat the data from what is created with FSL to a simple CSV file

     mcf_par_data = pd.read_csv('mcf.cl.par', names = ['roll','pitch','yaw','x','y','z'], delim_whitespace=True)
     mcf_par_data.to_csv('mcf.cl.csv', index=False, float_format='%.8f')

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
          
          figure.savefig('translation.cl.png', bbox_inches=0)
          
          rotation = mcf_par_data[['roll','pitch','yaw']]
          ax     = rotation.plot(title='Rotation')
          ax.set_xlabel("index [-]")
          ax.set_ylabel("rotation [rads]")
          figure = ax.get_figure()
          figure.savefig('rotation.cl.png', bbox_inches=0)


     df_abs_rms_mcf = pd.read_csv('mcf.cl_abs.rms', names = ['rms'], delim_whitespace=True)
     df_rel_rms_mcf = pd.read_csv('mcf.cl_rel.rms', names = ['rms'], delim_whitespace=True)
     
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
          
          plt.savefig('rms.cl.png', bbox_inches=0)
                    
          util.iw_subprocess( [  'display', 'rms.cl.png' ] )
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
          plt.savefig('diff_abs_rms.cl.png', bbox_inches=0)


#          util.iw_subprocess( [  'display', 'diff_abs_rms.cl.png' ] )
