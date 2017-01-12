#!/bin/env python

import argparse

import nibabel as nb
import numpy   as np
import pandas  as pd

import matplotlib.pyplot as plt



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
     parser.add_argument("-o","--output",         help="Save results to CSV file", default=None)

     parser.add_argument("-v","--verbose",    help="Verbose flag",      action="store_true", default=False )
     parser.add_argument("-p","--plot",    help="Plot results",      action="store_true", default=False )

     inArgs = parser.parse_args()
     
     #
     #
     #

     nb_image     = nb.load(inArgs.in_image)
     data_array   = nb_image.get_data()

     if not inArgs.mask == None:
          nb_mask  = nb.load(inArgs.mask)
     else:
          nb_mask  = np.ones( np.shape(data_array))

     masked_array = np.ma.masked_array(data_array, mask = abs(nb_mask)>0 )
     
     data_sum    = np.sum(data_array,        axis=tuple(inArgs.axis) )
     data_count  = np.sum(abs(data_array)>0, axis=tuple(inArgs.axis) )
     data_mean   = np.divide(data_sum, data_count)

     df        = pd.DataFrame( { 'mean' : data_mean} )

     if inArgs.plot:
          plt.figure()
          df['mean'].plot()
          plt.show()

     if inArgs.verbose:
          print
          print df
          print
         
     if not inArgs.output == None:
          df.to_csv(inArgs.output, index=True)

