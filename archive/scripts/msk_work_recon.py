#!/aging1/software/anaconda/bin/python

"""

"""

import sys      
import os                                               # system functions
import glob
import shutil
import distutils

import argparse
import iwUtilities

import pandas             as pd
import numpy              as np
import nibabel            as nib
import matplotlib.pyplot  as plt
import matplotlib.patches as mpatches


#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     usage = "usage: %prog [options] arg1 arg2"

     parser = argparse.ArgumentParser(prog='msk_pcasl_recon')

     parser.add_argument("--indir",           help="Input  directory", default = os.getcwd() )
     parser.add_argument("--outdir",          help="Output directory", default = '../results' )
     parser.add_argument("--acrostic",        help="Participant's acrostic", default = None )

     parser.add_argument("-d","--display",  help="Display Results",  action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",     action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",       action="store_true", default=False )
     parser.add_argument("--qi",            help="QA inputs",        action="store_true", default=False )
     parser.add_argument("--qo",            help="QA outputs",       action="store_true", default=False )
     parser.add_argument("--figures",       help="Save png figures", action="store_true", default=False )

     parser.add_argument("-r", "--run",     help="Run processing pip>eline",      action="store_true", default=False )


     inArgs = parser.parse_args()

     input_directory  = os.path.abspath(inArgs.indir)
     
     if os.path.isabs(inArgs.outdir):
          output_directory = inArgs.outdir
     else:
          output_directory = os.path.abspath(os.path.join(input_directory, inArgs.outdir )) 


     if inArgs.debug:
          print
          print "inArgs.indir     = " +  inArgs.indir
          print "inArgs.outdir    = " +  inArgs.outdir
          print
          print "input_directory  = " + input_directory
          print "output_directory = " + output_directory
          print
          print "inArgs.debug     = " +  str(inArgs.debug)
          print "inArgs.verbose   = " +  str(inArgs.verbose)
          print



     input_files = [ os.path.abspath( os.path.join( input_directory, 'fix_analysis_row.txt')),
                     os.path.abspath( os.path.join( input_directory, 'max_analysis_row.txt')), 
                     os.path.abspath( os.path.join( input_directory, 'fix_mean_valid_waveform.txt')), 
                     os.path.abspath( os.path.join( input_directory, 'max_mean_valid_waveform.txt'))]
     
     iwUtilities.verify_inputs( input_files )
     

     output_files = [ os.path.abspath( os.path.join( output_directory, 'work_comparison.csv' )), 
                      os.path.abspath( os.path.join( output_directory, 'waveform_comparison.png')) ]

     
     if inArgs.run:

          #
          # Verify Input files
          #


          iwUtilities.verify_inputs ( input_files )
          iwUtilities.mkcd_dir( output_directory  )

          #
          #
          #

          fix_analysis =  pd.read_csv( input_files[0] )
          max_analysis =  pd.read_csv( input_files[1] )

          analysis     =  fix_analysis.append(max_analysis)
          column_list  = analysis.columns.tolist()

          if inArgs.display:
               print analysis[ column_list[1:]].transpose()


          save_analysis = analysis[ column_list[1:]].transpose()
          save_analysis.to_csv( output_files[0], index_label=['parameter', 'fix', 'work'])
          

          #
          # Waveform Plot
          #

          fix_waveform =  pd.read_csv( input_files[2], names=["time","height"]).as_matrix()
          max_waveform =  pd.read_csv( input_files[3], names=["time","height"]).as_matrix()

          fix_plot, = plt.plot(fix_waveform[:,0], fix_waveform[:,1] - min(fix_waveform[:,1]), 
                   color="blue", linewidth=2.5, linestyle='-', label='Fixed')

          max_plot, = plt.plot(max_waveform[:,0], max_waveform[:,1] - min(max_waveform[:,1]), 
                   color="red", linewidth=2.5, linestyle='-', label='Maximum')

          plt.xlabel('time [s]', fontsize=16, fontweight='bold')
          plt.ylabel('Height [mm]', fontsize=16, fontweight='bold')
          plt.ylim(0., 70.)
          plt.grid()

          if not inArgs.acrostic == None:
               plt.title(str(inArgs.acrostic), fontsize=20, fontweight='bold')

          plt.tick_params(labelsize=16)

          plt.legend( handles=[ fix_plot, max_plot ] )
          plt.savefig( output_files[1])

          if inArgs.display:
               plt.show()



          #
          # Verify Output files
          #
               
          iwUtilities.verify_outputs( output_files )
