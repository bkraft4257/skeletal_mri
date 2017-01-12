#!/usr/bin/env python

import sys
import numpy as np
import matplotlib.pyplot as plt
from   scipy.optimize import curve_fit
import pandas as pd
from scipy.stats.distributions import  t as tdist

def fitFunc(t, a, b, c):
    return a*np.exp(-b*t) + c


def main():

    label_index        = 1
    mbf_index_filename = 'mbf.index'
    mbf_filename = 'test.csv' # m0_To_t2w.slice_mean.mbf.csv'
    mbf_filename = 'm0_To_t2w.slice_mean.mbf.csv'

    raw_time =  pd.read_csv(mbf_index_filename).values
    time     = (40. + 4.0*raw_time.flatten())/60.

    df    =  pd.read_csv(mbf_filename, names=['label','time','mean','std'])


    data0 = df[ df['label'] == label_index ]
    data3 = data0['mean'].values
    data4 = data3[0:len(time)]

    print[data4]

    alpha = 0.05
    n     = len(data4)
    dof   = max(0, n - 3) 
    tval  = tdist.ppf(1.0-alpha/2., dof) 
    
    print([alpha, n, dof, tval])

    #
    # Plot data
    #
    plt.ylabel('Muscle Blood Flow [ml/100g/min]', fontsize = 16)
    plt.xlabel('time [min]', fontsize = 16)
    
    plt.plot(time, data4, 'ro',  color="blue", linewidth=2.5, linestyle='-')


    fitParams, fitCovariance = curve_fit(fitFunc, time, data4, p0=[80, .1, 0])

    print fitParams
    print fitCovariance

    for i, p, var in zip(range(n),fitParams, np.diag(fitCovariance)):
        sigma = var**0.5
        print 'p{0}: {1} [{2}  {3}]'.format(i, p,
                                            p - sigma*tval,
                                            p + sigma*tval)
        
# plot the data as red circles with vertical errorbars
#plt.errorbar(t, data3, fmt = 'ro', yerr = 0.2)

# now plot the best fit curve and also +- 1 sigma curves
# (the square root of the diagonal covariance matrix
# element is the uncertianty on the fit parameter.)

    sigma = [ tval*fitCovariance[0,0] ** 0.5, 
              tval*fitCovariance[1,1] ** 0.5, 
              tval*fitCovariance[2,2] ** 0.5  
              ]
    print
    print('sigma')
    print([  fitCovariance[0,0]**0.5, fitCovariance[1,1]**0.5,fitCovariance[2,2]**0.5])
    print(sigma)
    print

    plt.plot(time, fitFunc(time, fitParams[0], fitParams[1], fitParams[2]), color='red')

#    plt.plot(time, fitFunc(time, fitParams[0] + sigma[0], fitParams[1] - sigma[1], fitParams[2] + sigma[2]),\
#             time, fitFunc(time, fitParams[0] - sigma[0], fitParams[1] + sigma[1], fitParams[2] - sigma[2]),\
#             color="red" \
#                 )

# save plot to a file
    plt.show()
    plt.savefig('dataFitted.png', bbox_inches=0)


#
# Main Function
#

if __name__ == "__main__":
    sys.exit(main())

