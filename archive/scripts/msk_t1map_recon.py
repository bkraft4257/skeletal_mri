#!/bin/env python

import os
import argparse
import iwUtilities as util

#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     parser = argparse.ArgumentParser(prog='msk_t1map')

     parser.add_argument("subject_directory",              help="", default=os.getcwd() )

     parser.add_argument("-v","--verbose",  help="Verbose flag",     action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",       action="store_true", default=False )

     inArgs = parser.parse_args()


     subject_directory = os.path.abspath(inArgs.subject_directory)

     reorient_directory       = os.path.abspath(os.path.join(subject_directory, 'reorient' )) 
     t2w_results_directory    = os.path.abspath(os.path.join(subject_directory, 't2w', 'results' )) 

     t1map_directory          = os.path.abspath(os.path.join(subject_directory, 't1map' )) 
     t1map_input_directory    = os.path.join(t1map_directory, 'input')
     t1map_register_directory = os.path.join(t1map_directory, '01-register')
     

     print t1map_directory
     print t1map_input_directory
     print t1map_register_directory

     util.mkcd_dir( t1map_register_directory, False )
     util.mkcd_dir( t1map_input_directory, True ) 

     #
     # Gather inputs
     #

     input_files = [ os.path.join( reorient_directory,    't1map.nii.gz'), 
                     os.path.join( t2w_results_directory, 'mask.muscle.nii.gz')
                     ]
     
     util.link_inputs(input_files,      t1map_input_directory)
     util.link_inputs([ input_files[1] ], t1map_register_directory)


     util.iw_subprocess([ 'antsApplyTransforms', '-d', '3', '-i', input_files[0], 
                          '-o', os.path.join(t1map_register_directory, 't1map.nii.gz'), 
                          '-r', input_files[1], '-t', 'identity' ],
                        inArgs.verbose, inArgs.verbose )                     
