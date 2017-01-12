#!/usr/bin/env bash 

outDir=${MSK_MRI_DATA}/$2

mkdir -p ${outDir}/data/measdat
mkdir -p ${outDir}/data/labview
mkdir -p ${outDir}/data/

mv $1 ${outDir}/data/dicom

