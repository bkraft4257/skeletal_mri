#!/aging1/software/anaconda/bin/python

"""

"""

import argparse

import numpy as np
import matplotlib.pyplot as plt
from   scipy.optimize import curve_fit
import pandas as pd
from   scipy.stats.distributions import  t as tdist


def fitFunc(t, a, b, c):
    return a*np.exp(-b*t) + c


def extract_data( raw_data, label ):

    data1 = raw_data[['label', 'mean']]
    data2 = data1[data1.label == label ]
    data3 = data1[data1.label == label ][['mean']].values

    return data3.flatten()



#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     usage = "usage: %prog [options] arg1 arg2"

     parser = argparse.ArgumentParser(prog='msk_pcasl_recon')

     parser.add_argument("input",           help="Input  directory", default = 'm0_To_t2w.slice_mean.mbf.csv' )
     parser.add_argument("time",            help="Time index file", default = 'mbf.index' )
     parser.add_argument("--time_scale",    help="Time scale (1=seconds, 60=minutes)", choices=[1,60], type=float, default = 1.0 )
     parser.add_argument("--params_init",   help="Initial guess for parameters a,b,c", nargs=3, type=float, default = [ 100.0, 0.1, 0] )


     parser.add_argument("-d","--display",  help="Display Results",  action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",     action="store_true", default=False )


     inArgs = parser.parse_args()


     raw_data =  pd.read_csv(inArgs.input, names = ["label", "time", "mean", "stddev"])

     raw_time =  pd.read_csv(inArgs.time, names = ["index"]).values
     time     = (40. + 4.0*raw_time.flatten())/inArgs.time_scale
     
     alpha = 0.05
     
     param_bounds=( [-10.0, -np.inf, -20.0], [200.0, 0.0, 20.0])
     print param_bounds


     for ii in range(1,6):

         ii_data = extract_data(raw_data,ii)
         
         fitParams, fitCovariance = curve_fit(fitFunc, time, ii_data, bounds=param_bounds ) #, p0=inArgs.params_init)
         
         plt.ylabel('Muscle Blood Flow [ml/100g/min]', fontsize = 16)
         plt.xlabel('time [min]', fontsize = 16)
         
         plt.plot(time, ii_data, 'ro',  color="blue", linewidth=2.5, linestyle='-')
         
         # now plot the best fit curve and also +- 1 sigma curves
         # (the square root of the diagonal covariance matrix
         # element is the uncertianty on the fit parameter.)
         
         n     = len( ii_data)
         dof   = max(0, n - 3) 
         tval  = tdist.ppf(1.0-alpha/2., dof) 
         
         sigma = tval * [ fitCovariance[0,0] ** 0.5,
                          fitCovariance[1,1] ** 0.5,
                          fitCovariance[2,2] ** 0.5 
                          ]
         
         print sigma
         
         plt.plot(time, fitFunc(time, fitParams[0], fitParams[1], fitParams[2]), 
                  time, fitFunc(time, fitParams[0] + sigma[0], fitParams[1] - sigma[1], fitParams[2] + sigma[2]),
                  time, fitFunc(time, fitParams[0] - sigma[0], fitParams[1] + sigma[1], fitParams[2] - sigma[2]),
                  color="red"
                 )

         plt.show()
