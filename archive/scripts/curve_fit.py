#!/bin/env python

import numpy as np
import matplotlib.pyplot as plt
from   scipy.optimize import curve_fit
import pandas as pd
from scipy.stats.distributions import  t as tdist

def fitFunc(t, a, b, c):
    return a*np.exp(-b*t) + c

raw_time =  pd.read_csv('max.mbf.index.csv', names = ["index"]).values
time     = (40. + 4.0*raw_time.flatten())/60.
print time

raw_data =  pd.read_csv('max.m0_To_t2w.slice_mean.mbf.csv', names = ["label", "time", "mean", "stddev"])


data1 = raw_data[['label', 'mean']]
data2 = data1[data1.label == 5 ]
data3 = data1[data1.label == 5 ][['mean']].values
data4 = data3.flatten()

alpha = 0.05
n     = len(data4)
dof   = max(0, n - 3) 
tval  = tdist.ppf(1.0-alpha/2., dof) 

#
# Plot data
#
plt.ylabel('Muscle Blood Flow [ml/100g/min]', fontsize = 16)
plt.xlabel('time [min]', fontsize = 16)

plt.plot(time, data4, 'ro',  color="blue", linewidth=2.5, linestyle='-')

fitParams, fitCovariance = curve_fit(fitFunc, time, data4, p0=[100, .1, 0])
#print fitParams
#print fitCovariance

for i, p,var in zip(range(n),fitParams, np.diag(fitCovariance)):
    sigma = var**0.5
    print 'p{0}: {1} [{2}  {3}]'.format(i, p,
                                  p - sigma*tval,
                                  p + sigma*tval)

# plot the data as red circles with vertical errorbars
#plt.errorbar(t, data3, fmt = 'ro', yerr = 0.2)

# now plot the best fit curve and also +- 1 sigma curves
# (the square root of the diagonal covariance matrix
# element is the uncertianty on the fit parameter.)

sigma = tval * [ fitCovariance[0,0] ** 0.5, \
                 fitCovariance[1,1] ** 0.5, \
                 fitCovariance[2,2] ** 0.5  \
         ]

print sigma

plt.plot(time, fitFunc(time, fitParams[0], fitParams[1], fitParams[2]), \
         time, fitFunc(time, fitParams[0] + sigma[0], fitParams[1] - sigma[1], fitParams[2] + sigma[2]),\
         time, fitFunc(time, fitParams[0] - sigma[0], fitParams[1] + sigma[1], fitParams[2] - sigma[2]),\
         color="red" \
         )

# save plot to a file
plt.show()
plt.savefig('dataFitted.png', bbox_inches=0)
