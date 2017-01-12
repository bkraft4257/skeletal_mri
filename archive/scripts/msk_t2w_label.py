#!/usr/bin/env python

"""

"""
import sys
import os                                               # system functions
import re
import pandas
import json
import argparse
import iwUtilities as util
import cenc
import iw_labels
import datetime
from collections import OrderedDict
import getpass

def participant_id(in_dir, msk_dir=os.getenv('MSK_MRI_DATA'), acrostic_flag=True, directory_flag=True, exist_flag=True, verbose=False):
     
     pattern    = 'sm0\d{2}_[a-z]{5}' 
     re_pattern = re.compile('sm0\d{2}_[a-z]{5}')

     if re_pattern.match(in_dir) and not os.path.isdir(in_dir):
          in_dir = os.path.join(msk_dir, in_dir)

     in_abs_dir = os.path.abspath(in_dir)     
     msk_participant_id     = util.extract_participant_id( in_abs_dir, pattern)
     msk_participant_dir    = os.path.abspath( os.path.join( msk_dir, msk_participant_id))
     msk_participant_exists = os.path.isdir(msk_participant_dir)

     msk_results = []

     if acrostic_flag:
          msk_results += [msk_participant_id]

     if directory_flag:
          msk_results += [msk_participant_dir]

     if exist_flag:
          msk_results += [msk_participant_exists]

     if verbose:
          print(msk_results)

     return msk_results

     

def msk_get_info(in_dir, verbose=False):

     msk_participant_id, msk_participant_dir, msk_participant_exists = participant_id( in_dir, verbose=verbose )
     t2w_dir =  util.path_relative_to( msk_participant_dir, 't2w')


def main():

     ## Parsing Arguments

     usage = "usage: %prog [options] arg1 arg2"

     parser = argparse.ArgumentParser(prog='cenc_freesurfer')

     parser.add_argument("--in_dir",       help="Participant directory", default = os.getcwd() )
     parser.add_argument("--visit",        help="Participant visit", default = None )

     parser.add_argument("--prepare",    help="Gather necessary inputs for MT analysis", action="store_true", default=False )
     parser.add_argument("--methods",        help="Run Magnetization Transfer Analysis", action="store_true", default=False )
     parser.add_argument("--results",    help="Gather results",  action="store_true", default=False )
     parser.add_argument("--redcap",     help="Calculate RedCap results",  action="store_true", default=False )

     parser.add_argument("--status",          help="Check if MT has been run on this participant",  action="store_true", default=False )
     parser.add_argument("--force",     help="Force processing action to run",  action="store_true", default=False )

     parser.add_argument('-v','--verbose', help="Verbose flag",  action="store_true", default=False )


     inArgs = parser.parse_args()

     #
     #
     #

     msk_info = msk_get_info(inArgs.in_dir, inArgs.verbose)

     if inArgs.prepare:

          util.mkcd_dir( [ link_to_dir ], change_to_dir )

          input_files = cenc_dirs['mt']['inputs']
          label_files = cenc_dirs['mt']['labels']

          util.link_inputs( input_files + label_files, link_to_dir )


     if inArgs.methods:
          pass

     if inArgs.results:
          pass

     if inArgs.status: 
          pass

#
# Main Function
#

if __name__ == "__main__":
    sys.exit(main())

