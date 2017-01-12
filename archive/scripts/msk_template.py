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

def main():

     ## Parsing Arguments

     usage = "usage: %prog [options] arg1 arg2"

     parser = argparse.ArgumentParser(prog='cenc_freesurfer')

     parser.add_argument("--in_dir",       help="Participant directory", default = os.getcwd() )

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

     if inArgs.prepare:
          pass

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

