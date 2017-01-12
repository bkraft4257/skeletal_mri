#!/usr/bin/env python

import sys      
import os                                               # system functions
import shutil

import subprocess
import argparse
import iwUtilities     as util

import nibabel as nb
import pandas  as pd
import numpy   as np

import iwCtf         as ctf


#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #
     
     parser = argparse.ArgumentParser(prog='iwCtf_transform_points')
               
     parser.add_argument("in_image",              help="Fiducials in wLPS coordinates CTF, Native, or Template space" )
     parser.add_argument("-a","--axis",           help="Axis", type=int, nargs="*", default = [0,1]  )
     parser.add_argument("-m","--mask",           help="Mask" )
     parser.add_argument("-o","--output",         help="Output filename", default=None)

     parser.add_argument("-v","--verbose",    help="Verbose flag",      action="store_true", default=False )
     parser.add_argument("--debug",           help="Debug flag",      action="store_true", default=False )

     inArgs = parser.parse_args()
     
     #
     #
     #

     util.print_stage("Displaying inputs to iwCtf_transform_points", inArgs.verbose )

     if inArgs.debug:
          print
          print "inArgs.verbose        = " +  str(inArgs.verbose)

     print inArgs.axis

     nb_image  = nb.load(inArgs.in_image)
     data      = nb_image.get_data()
     mean      = np.mean(data,   axis= tuple(inArgs.axis) )


     df        = pd.DataFrame( mean, columns=['mean'])
     
     print
     print df
     print
         
     if not inArgs.output == None:
          df.to_csv(inArgs.output, index=True)

