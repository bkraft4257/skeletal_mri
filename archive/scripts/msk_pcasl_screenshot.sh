#!/bin/env bash

         # Cortical thickness
        
            mask="${ANTSPATH}/ThresholdImage ${DIMENSION} ${CORTICAL_THICKNESS_IMAGE_RESAMPLED} ${CORTICAL_THICKNESS_MASK} 0 0 0 1"
            logCmd $mask
        
            conversion="${ANTSPATH}/ConvertScalarImageToRGB ${DIMENSION} ${CORTICAL_THICKNESS_IMAGE_RESAMPLED}"
            conversion="${conversion} ${CORTICAL_THICKNESS_IMAGE_RGB} none hot none 0 ${DIRECT_THICKNESS_PRIOR}"
            logCmd $conversion
        
            mosaic="${ANTSPATH}/CreateTiledMosaic -i ${HEAD_N4_IMAGE_RESAMPLED} -r ${CORTICAL_THICKNESS_IMAGE_RGB}"
            mosaic="${mosaic} -o ${CORTICAL_THICKNESS_MOSAIC} -a 1.0 -t -1x-1 -d 2 -p mask"
            mosaic="${mosaic} -s [2,mask,mask] -x ${CORTICAL_THICKNESS_MASK}"
            logCmd $mosaic
        
            # Segmentation
        
            echo "0 1 0 0 1 0 1" > $ITKSNAP_COLORMAP
            echo "0 0 1 0 1 1 0" >> $ITKSNAP_COLORMAP
            echo "0 0 0 1 0 1 1" >> $ITKSNAP_COLORMAP
        
            conversion="${ANTSPATH}/ConvertScalarImageToRGB ${DIMENSION} ${BRAIN_SEGMENTATION_IMAGE_RESAMPLED}"
            conversion="${conversion} ${BRAIN_SEGMENTATION_IMAGE_RGB} none custom $ITKSNAP_COLORMAP 0 6"
            logCmd $conversion
        
            mosaic="${ANTSPATH}/CreateTiledMosaic -i ${HEAD_N4_IMAGE_RESAMPLED} -r ${BRAIN_SEGMENTATION_IMAGE_RGB}"
            mosaic="${mosaic} -o ${BRAIN_SEGMENTATION_MOSAIC} -a 0.3 -t -1x-1 -d 2 -p mask"
            mosaic="${mosaic} -s [2,mask,mask] -x ${BRAIN_EXTRACTION_MASK_RESAMPLED}"
    logCmd $mosaic