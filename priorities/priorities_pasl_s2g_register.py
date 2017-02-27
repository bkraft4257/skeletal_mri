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
import _qa_utilities as qa_util
import _utilities    as util
import labels    

import numpy        as np
import nibabel      as nb
import pandas       as pd
import matplotlib.pyplot   as plt

#
# Apply Transforms to Perfusion Weighted Image
#

cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/$inM0FileName  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_1Warp.nii.gz               \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_0GenericAffine.mat         \
                            -o syn.m0_To_${inMuscleMaskBaseFileName}.nii.gz"

echo $cmd
$cmd


#
# Apply Transforms to Muscle Mask
#


cmd="antsApplyTransforms -v -d 3 -r ${inDir}/${inMuscleMaskFileName} -i ${inDir}/$inPwiFileName  \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_1Warp.nii.gz                \
                            -t maskM0_To_${inMuscleMaskBaseFileName}_0GenericAffine.mat          \
                            -o syn.pwi_To_${inMuscleMaskBaseFileName}.nii.gz"

echo $cmd
$cmd
