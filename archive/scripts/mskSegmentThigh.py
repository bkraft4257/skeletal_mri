#!/aging1/software/anaconda/bin/python
# !/usr/bin/env python
"""
    Segments thigh into 5 tissue components - subcutaneous fat (1), intramuscular fat(2), muscle (3), bone cortex (4), and bone marrow (5).

    Required inputs:  --image A t1 or t2 weighted image for segmentation.
                      --mask  A mask directing over what region in the image should the segmentation be performed.

    Assumptions employeed :

        1) Bone cortex may be approximated with a convex hull
        2) Bone marroe may be approximated with a convex hull
        3) Muscle boundary may be approximated with a convex hull
        4) Segmentation is done on leg at time.  

    Segmentation is done in stages.  First stage classifies the tissue contained in the mask to either muscle, fat, or other. N4 correction
    is applied to the masked image before segmentation occurs. Second stage finds the convex hull of the muscle.  Thir 

"""

import sys      
import os                                               # system functions
import glob
import shutil
import distutils

import argparse
import subprocess
import iwQa
import iwUtilities

def redcap():

# record_id
# redcap_event_name    
# acrostic    
# date_of_birth    
# gender    
# demographics_complete   
# 
# subfat_vol
# mus_vol 
# musfat_vol
# femur_cortex_vol
# femur_mar_vol 
# convex_hull_measurements_complete    

# subfat_vol_v2    
# mus_vol_v2   
# musfat_vol_v2    
# femur_cortex_vol_v2    
# femur_mar_vol_v2    
# manual_measurements_complete

     print "Not implemented yet"


def probabilityVolume( probabilityMap ):

     callCommand = ["fslstats", probabilityMap, "-M", "-V"]

     fslstats  = subprocess.Popen(callCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
     rawOutput = fslstats.communicate()[0]
     output    = rawOutput.rstrip().split()

     volume    = float(output[0]) * float(output[2])/ 1000.

     return volume



def stats( labelFile, probImfat, probMuscle ):

     if not os.path.isfile(labelFile):
          print "Label file %s does not exist"  % labelFile
          quit()

     labels   = ( ("Subcutaneous_fat", 1), 
                  ( "Intramuscular_fat", 2),
                  ( "Skeletal_muscle",   3),
                  ( "Bone_cortex", 4),
                  ( "Bone_marrow", 5))       

#     print '\n\n{0:>25s}, {1:>8s}, {2:>10s}, {3:>15s}'.format("Label Name", "Number", "nVoxels", "Volume [cm^3]")

     volume = [0, 0, 0, 0, 0, 0, 0];

     for ii in labels:

          iiMaskFileName = "mask." + ii[0] + "." + labelFile

          callCommand = ["fslmaths", labelFile, "-thr", str(ii[1]), "-uthr", str(ii[1]), "-bin", iiMaskFileName ]
          iwUtilities.iw_subprocess(callCommand)

          callCommand = ["fslstats", labelFile, "-k", iiMaskFileName, "-V"]

          fslstats  = subprocess.Popen(callCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
          rawOutput = fslstats.communicate()[0]
          output    = rawOutput.rstrip().split()

          volume[int(ii[1]-1)] = float(output[1])/1000.
          
#          print '{0:>25s}, {1:>8d}, {2:>10d}, {3:>15.8f}'.format(ii[0], ii[1], int(output[0]), float(output[1])/1000)

          if not inArgs.debug:
               os.remove(iiMaskFileName)

     #
     # Calculate volume from probability maps 
     #

     volume[5] = probabilityVolume( probImfat  )
     volume[6] = probabilityVolume( probMuscle )
     
     print '{0:>10s}, {1:>10s}, {2:>10s}, {3:>10s},{4:>10s},{5:>12s},{6:>12s}'.format("SubFat", "ImFat","Muscle","Cortex", "Marrow", "probImFat", "probMuscle")
     print '{0:>10.3f}, {1:>10.3f}, {2:>10.3f}, {3:>10.3f},{4:>10.3f},{5:>12.3f},{6:>12.3f}'.format(*volume)



def clean( imageFile ):

     delete_files = glob.glob('*'+ imageFile + '*')

     for ii in delete_files:
          os.remove( ii )

def extract_label( image, labelIndex, labelName ):

     iwUtilities.iw_subprocess( ["fslmaths", image, "-thr", str(labelIndex), "-uthr", str(labelIndex), labelName])

def check_file(filename):

     # Create convex hull of bone cortex
     if not os.path.exists(filename):
          sys.exit("check_file(): " + filename + " does not exist.")
          
def set_stages(in_stage_list):
    
     nStages = 8
     stages  = ('0','1','2','3','4','5','6','7','all', 'auto')

     if 'auto' in in_stage_list:
          stage_flags = [False]*nStages

     elif 'all' in in_stage_list:
          stage_flags = [True]*nStages

     else:
          stage_flags = [False]*nStages

          for ii,jj in enumerate(stages[0:7]):
               stage_flags[ii] = jj in in_stage_list
          
     return stage_flags


def check_stage_stop( stage_stop, current_stage):

     if stage_stop[0] == current_stage:
          print "\n\t!!! Forced to stop at Stage " + str(stage_stop[0]) + " !!! \n"
          quit()


 

#
# Main Function
#

if __name__ == "__main__":

     ## Parsing Arguments
     #
     #

     usage = "usage: %prog [options] arg1 arg2"

     class MyParser(argparse.ArgumentParser):
         def error(self, message):
             sys.stderr.write('error: %s\n' % message)
             self.print_help()
             sys.exit(2)

     parser = argparse.ArgumentParser(prog='mskSegmentThigh')

     parser.add_argument("--image",         help="T2w thigh image file", default="t1w_36ms.nii.gz")
     parser.add_argument("--mask",          help="Mask to segment thigh into subcutaneous fat, intramuscular fat, muscle, bone cortex, and bone marrow", 
                         default="mask.t1w_36ms.nii.gz")

     parser.add_argument("--indir",           help="Input directory",  default = os.getcwd() )
     parser.add_argument("--outdir",          help="Output directory", default = '../01-segment' )
     parser.add_argument("--outprefix",       help="Output prefix",    default = "st_" )

     parser.add_argument("-d","--display",  help="Display results in Freeview", action="store_true", default=False )
     parser.add_argument("-v","--verbose",  help="Verbose flag",      action="store_true", default=False )
     parser.add_argument("--debug",         help="Debug flag",      action="store_true", default=False )

     parser.add_argument("--clean",         help="Clean directory by deleting intermediate files",      action="store_true", default=False )
     parser.add_argument("--stats",         help="Measure Label volumes in cm^3",      action="store_true", default=False )
     parser.add_argument("--stage_force",   help="Force stages to process.", nargs='+',  type=str, choices={'0','1','2','3','4','5','6','7','all'}, default='all' )
     parser.add_argument("--stage_stop",    help="Force stages to process.", nargs=1,  type=int, choices=range(0,7),  default=[6] )

     parser.add_argument("--qi",            help="QA inputs",      action="store_true", default=False )
     parser.add_argument("--qo",            help="QA outputs",      action="store_true", default=False )
     parser.add_argument("-r", "--run",     help="Run processing pipeline",      action="store_true", default=False )

     inArgs = parser.parse_args()

     stageFlag = set_stages(inArgs.stage_force)

     input_files = [[ inArgs.image, ":colormap=grayscale" ],
                    [ inArgs.mask,  ":colormap=jet:opacity=0.5"]];

     processName   = ".mskSegmentThigh."
     baseName      = ".mskSegmentThigh."+inArgs.image;



     labelFileName = "labels."+inArgs.image

     labelColorFreeSurferLUT  =  os.getenv("MSK_SCRIPTS") + "/" "mskSegmentThigh.FreesurferColorLUT.txt" 

     intermediate_files = [["1"+processName+"SegmentationPosteriors1.nii.gz",    ":colormap=jet:opacity=0.3"],  # Atropos Skeletal Muscle
                           ["ch.muscle."+inArgs.image,                               ":colormap=jet:opacity=0.3"],  # Convex Hull Muscle
                           ["ch.cortex."+inArgs.image,                               ":colormap=jet:opacity=0.3"],  # Convex Hull Muscle
                           ["cortex."+inArgs.image,                                  ":colormap=jet:opacity=0.3"],  # Convex Hull Muscle
                           ["marrow."+inArgs.image,                                  ":colormap=jet:opacity=0.3"],  # Convex Hull Muscle
                           ["subfat."+inArgs.image,                                  ":colormap=jet:opacity=0.3"],  # Convex Hull Muscle
                           ["imfat."+inArgs.image,                                   ":colormap=jet:opacity=0.3"],  # Convex Hull Muscle
                           ["muscle."+inArgs.image,                                  ":colormap=jet:opacity=0.3"]]  # Convex Hull Muscle

     
     output_files = [  [ "n4."         + inArgs.image,  ":visible=1:colormap=grayscale" ],
                       [ "pmap.imfat."  + inArgs.image,  ":visible=0:colormap=heat:heatscale=0,1:opacity=0.6" ],
                       [ "pmap.muscle." + inArgs.image,  ":visible=0:colormap=heat:heatscale=0,1:opacity=0.6" ],
                       [ "labels."      + inArgs.image,  ":visible=1:colormap=lut:lut="+ labelColorFreeSurferLUT+":opacity=0.6" ]]

     labels = [[ "subfat", 1], [ "muscle", 1], [ "muscle", 1], [ "muscle", 1], [ "muscle", 1],]


     # Change director to input directory

     in_directory = os.path.abspath( inArgs.indir)
     os.chdir( in_directory )

     out_directory = os.path.abspath( os.path.join( inArgs.indir,inArgs.outdir))
     outFull       = os.path.join(out_directory, inArgs.outprefix)

     if not os.path.exists(out_directory):
          os.makedirs(out_directory)
          
     in_file_full_path   =  os.path.join( in_directory, inArgs.image) 
     mask_file_full_path =  os.path.join( in_directory, inArgs.mask) 


     if ( os.path.isfile( in_file_full_path ) and 
          not os.path.isfile( os.path.join( out_directory, inArgs.image))):
          shutil.copy2(in_file_full_path,   out_directory )

     if ( os.path.isfile( mask_file_full_path  ) and 
          not os.path.isfile( os.path.join( out_directory, inArgs.mask))):
          shutil.copy2(mask_file_full_path, out_directory )


     if inArgs.debug:
          print
          print "inArgs.display    = " +  str(inArgs.display)
          print "inArgs.debug      = " +  str(inArgs.debug)
          print "inArgs.verbose    = " +  str(inArgs.verbose)
          print "inArgs.stage_stop = " +  str(inArgs.stage_stop)

     # Quality Assurance input
     #
         
     if  inArgs.qi:

         iwQa.qa_input_files( input_files, True )
         iwQa.freeview( input_files ) 


     # Clean
     #
         
     if  inArgs.clean:
          clean( processName ) 
     
     # Run    
     # 


     if  inArgs.run:

         if  iwQa.qa_input_files( input_files, False):

              print "\n"

              # Change director to input directory
              os.chdir( out_directory )

              #
              # Stage 0: Does a crude segmentation of fat.
              #

              print "\n#### Stage 0: Crude segmentation of subcutaneous fat (mask.fat."+inArgs.image+")\n"

              if stageFlag[0] or not os.path.isfile( "mask.fat."+inArgs.image  ):

                   if not os.path.isfile( "n4."+inArgs.image  ):

                        print "\t#### N4 Bias Field correction"

                        iwUtilities.iw_subprocess( ["N4BiasFieldCorrection","-d","3", "-i", inArgs.image, "-x", 
                                                    inArgs.mask, "-r", "-s", "-o","n4."+inArgs.image], inArgs.verbose)


                   # -c:  number of segmentation classes        Number of classes defining the segmentation
                   # -m:  max. N4 <-> Atropos iterations        Maximum number of (outer loop) iterations between N4 <-> Atropos.
                   # -n:  max. Atropos iterations               Maximum number of (inner loop) iterations in Atropos.
                   # -k:  keep temporary files                  Keep temporary files on disk (default = 0).

#                   iwUtilities.iw_subprocess( ["antsAtroposN4.sh","-d","3", "-c", "1", "-a", inArgs.image, "-m", "4", "-n", "4", 
#                                               "-x", inArgs.mask,
#                                               "-o", "00.mskSegmentThigh." ], inArgs.verbose )                              

                   print "\t#### Initial Segmentation of subcutaneous fat"

                   iwUtilities.iw_subprocess( ["ImageMath","3", "00a"+baseName, "m", "n4."+inArgs.image, inArgs.mask], inArgs.verbose)
                   iwUtilities.iw_subprocess( ["ThresholdImage","3", "00a"+baseName, "00b"+baseName, "Otsu", "1"], inArgs.verbose)

                   print "\t#### Extract fat mask"

                   extract_label("00b"+baseName, 1, "auto.mask.fat."+inArgs.image)
                   shutil.copy("auto.mask.fat."+inArgs.image, "mask.fat."+inArgs.image)

                   check_stage_stop(inArgs.stage_stop, 0)


              #
              # Stage 1:  Find convex hull of muscle mask. 
              #           

              print "\n#### Stage 1: Find convex hull of muscle (ac.init.muscle."+inArgs.image+")\n"

              if stageFlag[1] or not os.path.isfile( "ac.init.muscle."+inArgs.image  ):

                   check_file("mask.fat."+inArgs.image)

                   if stageFlag[1] or not os.path.isfile( "ac.mask.fat"+inArgs.image ):
                        print "\t#### Find active contour of fat"
                        iwUtilities.iw_subprocess( ["matlab", "-nodisplay", "-noFigureWindows", "-nosplash", "-r", 
                                                    "msk_convex_hull('mask.fat."+inArgs.image+"',[2, 100],'mask.fat."+inArgs.image+"'); exit"], inArgs.verbose)

                   check_file("ac.mask.fat."+inArgs.image)                   

                   iwUtilities.iw_subprocess( ["fslmaths", "mask.fat."+inArgs.image, "-binv", "01b"+baseName], inArgs.verbose)

                   iwUtilities.iw_subprocess( ["fslmaths", "01b"+baseName, "-mul", "ac.mask.fat."+inArgs.image,
                                               "01c"+baseName], inArgs.verbose)

                   print "\t#### Closing operation on muscle mask"
                   iwUtilities.iw_subprocess( ["fslmaths", "01c"+baseName, "-kernel", "2D", "-dilM", "-ero", 
                                               "01d"+baseName], inArgs.verbose)

                   print "\t#### Filter muscle to components greater than 30 pixels"
                   check_file("01d"+baseName)
                   iwUtilities.iw_subprocess( ["matlab", "-nodisplay", "-noFigureWindows", "-nosplash", "-r", 
                                               "iw_bwareafilt('01d"+baseName+"',[50, inf],'01e"+baseName+"'); exit"], inArgs.verbose)
                   
                   if stageFlag[1] or not os.path.isfile( "ac.init.muscle."+inArgs.image):

                        check_file("01e"+baseName)
                        print "\t#### Find convex hull of muscle"
                        iwUtilities.iw_subprocess( ["matlab", "-nodisplay", "-noFigureWindows", "-nosplash", "-r", 
                                                    "msk_convex_hull('01e"+baseName+"',[4, 100],'init.muscle.auto."+inArgs.image+"'); exit"], inArgs.verbose)

                        iwUtilities.iw_subprocess( ["fslmaths", "ac.init.muscle.auto."+inArgs.image, "-kernel", "2D", "-dilM", 
                                                    "ac.init.muscle.auto"+inArgs.image], inArgs.verbose)

                        os.rename("ac.init.muscle.auto."+inArgs.image, "auto.ac.init.muscle."+inArgs.image)
                        os.rename("ch.init.muscle.auto."+inArgs.image, "auto.ch.init.muscle."+inArgs.image)

                        shutil.copy("auto.ac.init.muscle."+inArgs.image, "ac.init.muscle."+inArgs.image)
                        shutil.copy("auto.ch.init.muscle."+inArgs.image, "ch.init.muscle."+inArgs.image)

                   check_stage_stop(inArgs.stage_stop, 1)

              #
              # Stage 2:  Find convex hull of bone cortex
              #           

              print "\n#### Stage 2: Find convex hull of bone cortex (ch.cortex."+inArgs.image+")\n"

              if stageFlag[2] or not os.path.isfile( "ch.cortex."+inArgs.image  ):

#                   print "\t#### Dilation operation on muscle mask"
#                   iwUtilities.iw_subprocess( ["fslmaths", "ch.init.muscle."+inArgs.image, "-kernel", "2D", "-dilM",  "-dilM", 
#                                               "02a"+baseName], inArgs.verbose)

                   print "\t#### Otsu Threshold on Convex Hull Muscle Mask"
                   iwUtilities.iw_subprocess( ["ImageMath","3", "02b"+baseName, "m", "n4."+inArgs.image, "ac.init.muscle."+inArgs.image], inArgs.verbose)
                   iwUtilities.iw_subprocess( ["ThresholdImage","3", "02b"+baseName, "otsu.muscle."+inArgs.image, "Otsu", "2"], inArgs.verbose)

                   iwUtilities.iw_subprocess( ["fslmaths", "otsu.muscle."+inArgs.image, "-add", "1", "-mul", 
                                               "ac.init.muscle."+inArgs.image, "02d"+baseName], inArgs.verbose)

                   extract_label("02d"+baseName, 1, "02e"+baseName)

                   iwUtilities.iw_subprocess( ["ImageMath","3", "02f"+baseName, "GetLargestComponent",
                                               "02e"+baseName ], inArgs.verbose)

                   # Create convex hull of bone cortex
                   check_file("02f"+baseName)

                   if stageFlag[2] or not os.path.isfile( "ch.cortex."+inArgs.image  ):
                        iwUtilities.iw_subprocess( ["matlab", "-nodisplay", "-noFigureWindows", "-nosplash", "-r", 
                                                    "msk_convex_hull('02f"+baseName+"',[2, 100],'cortex.auto."+inArgs.image+"'); exit"], inArgs.verbose)

                        shutil.copy("ch.cortex.auto."+inArgs.image, "ch.cortex."+inArgs.image)

                   check_stage_stop(inArgs.stage_stop, 2)

              #
              # Stage 3
              #

              print "\n#### Stage 3: Find bone marrow (cortex."+inArgs.image+") \n"

              if (stageFlag[3] or not os.path.isfile( "cortex."+inArgs.image) ):
                   
                   check_file("ch.cortex."+inArgs.image)

                   print "\t#### Identify marrow within convex hull of bone cortex"
                   iwUtilities.iw_subprocess( ["fslmaths", "ch.cortex."+inArgs.image, "-mul", "otsu.muscle."+inArgs.image,  "03a"+baseName], inArgs.verbose)

                   extract_label("03a"+baseName, 2, "03b"+baseName)

                   print "\t#### Get largest component of marrow"
                   iwUtilities.iw_subprocess( ["ImageMath","3", "marrow."+inArgs.image, "GetLargestComponent", "03b"+baseName ], inArgs.verbose)


                   print "\t#### Remove marrow from convex hull of bone cortex"
                   iwUtilities.iw_subprocess( ["fslmaths", "marrow."+inArgs.image, "-binv", "-mul", "ch.cortex."+inArgs.image, 
                                               "cortex."+inArgs.image ], inArgs.verbose)

                   check_stage_stop(inArgs.stage_stop, 3)                   
              #
              # Stage 4
              #

              print "\n#### Stage 4: Atropos convex muscle hull (init.pmap.imfat."+ inArgs.image + ")"

              if stageFlag[4] or not os.path.isfile(  "init.pmap.imfat."+inArgs.image ):

                   print "\t#### Remove bone from convex hull of the skeletal muscle"

                   print "\t#### Dilation operation on muscle mask"
                   iwUtilities.iw_subprocess( ["fslmaths", "ch.init.muscle."+inArgs.image, "-kernel", "2D", "-dilM", "-dilM",
                                               "04a"+baseName], inArgs.verbose)

                   iwUtilities.iw_subprocess( ["fslmaths", "ch.cortex."+inArgs.image, "-binv", "-mul", "04a"+baseName,
                                               "04b"+baseName], inArgs.verbose)

#                   iwUtilities.iw_subprocess( ["fslmaths", "04b"+baseName, "-uthrp", "10", "04c"+baseName], inArgs.verbose)

#                   iwUtilities.iw_subprocess( ["fslmaths", "04c"+baseName, "-binv", "-mul", "04b"+baseName,  "04d"+baseName], inArgs.verbose)

                   print "\t#### Ants Atropos N4 on convex hull muscle mask"
                   if stageFlag[4] or not os.path.isfile( "04e.mskSegmentThigh.Segmentation.nii.gz" ):
                        iwUtilities.iw_subprocess( ["antsAtroposN4.sh","-d","3", "-c", "2", "-a", inArgs.image, "-m", "4", "-n", "4",
                                                    "-x", "04b"+baseName, 
                                                    "-o", "./04e.mskSegmentThigh." ], inArgs.verbose ) 
                        
#                  extract_label("04e.mskSegmentThigh.Segmentation.nii.gz", 1, "other."+inArgs.image)
                   extract_label("04e.mskSegmentThigh.Segmentation.nii.gz", 1, "init.muscle."+inArgs.image)
                   extract_label("04e.mskSegmentThigh.Segmentation.nii.gz", 2, "init.imfat."+inArgs.image)

#                  shutil.copy("04e.mskSegmentThigh.SegmentationPosteriors1.nii.gz",    "pmap.other."+inArgs.image )
                   shutil.copy("04e.mskSegmentThigh.SegmentationPosteriors1.nii.gz",    "init.pmap.muscle."+inArgs.image )
                   shutil.copy("04e.mskSegmentThigh.SegmentationPosteriors2.nii.gz",    "init.pmap.imfat."+inArgs.image )

                   check_stage_stop(inArgs.stage_stop, 4)

              #
              # Stage 5: Refine Convex Hull of muscle
              #

              print "\n#### Stage 5: Refine convex hull of muscle (ac.muscle." + inArgs.image + ")\n"

              if stageFlag[5] or not os.path.isfile( "ch.muscle."+inArgs.image  ):

                   print "\t#### Filter muscle to components greater than 30 pixels"
                   iwUtilities.iw_subprocess( ["matlab", "-nodisplay", "-noFigureWindows", "-nosplash", "-r", 
                                               "iw_bwareafilt('init.muscle."+inArgs.image+"',[30, inf],'05a"+baseName+"'); exit"], inArgs.verbose)
                   check_file("05a"+baseName)
                   iwUtilities.iw_subprocess( ["matlab", "-nodisplay", "-noFigureWindows", "-nosplash", "-r", 
                                               "msk_convex_hull('05a"+baseName+"',[2, 100],'muscle.auto." + 
                                               inArgs.image+"'); exit"], inArgs.verbose)
                   
                   shutil.copy("ac.muscle.auto."+inArgs.image, "ac.muscle."+inArgs.image )
                   shutil.copy("ch.muscle.auto."+inArgs.image, "ch.muscle."+inArgs.image )

                   check_stage_stop(inArgs.stage_stop, 5)


              #
              # Stage 6: Refine Posterior estimates
              #

              print "\n#### Stage 6: Atropos convex muscle hull \n"

              if stageFlag[6] or not os.path.isfile(  "pmap.imfat."+inArgs.image ):

                   print "\t#### Remove ch.cortex from ch.muscle"

                   iwUtilities.iw_subprocess( ["fslmaths", "ch.cortex."+inArgs.image, "-binv", "-mul", "ch.muscle."+inArgs.image, 
                                               "06a"+baseName], inArgs.verbose)

                   print "\t#### Ants Atropos N4 on refined convex hull muscle mask"
                   if stageFlag[6] or not os.path.isfile( "06b.mskSegmentThigh.Segmentation.nii.gz" ):
                        iwUtilities.iw_subprocess( ["antsAtroposN4.sh","-d","3", "-c", "2", "-a", inArgs.image, "-m", "4", "-n", "4",
                                                    "-x", "06a"+baseName,
                                                    "-o", "./06b.mskSegmentThigh." ], inArgs.verbose ) 
                        
                   extract_label("06b.mskSegmentThigh.Segmentation.nii.gz", 1, "muscle."+inArgs.image)
                   extract_label("06b.mskSegmentThigh.Segmentation.nii.gz", 2, "imfat."+inArgs.image)

                   shutil.copy("06b.mskSegmentThigh.SegmentationPosteriors1.nii.gz",    "pmap.muscle."+inArgs.image )
                   shutil.copy("06b.mskSegmentThigh.SegmentationPosteriors2.nii.gz",    "pmap.imfat."+inArgs.image )

                   check_stage_stop(inArgs.stage_stop, 6)

              #
              # Stage 7
              #

              print "\n#### Stage 7: Calculate subcortical fat mask (subfat."+inArgs.image + ")\n"
              
              if stageFlag[7] or  not os.path.isfile( "subfat."+inArgs.image  ): 

                   iwUtilities.iw_subprocess( ["fslmaths", "ch.muscle."+inArgs.image, "-binv", "-mul",
                                               inArgs.mask,  "subfat."+inArgs.image ], inArgs.verbose)

                   check_stage_stop(inArgs.stage_stop, 7)

              #
              # Stage 8: Create Final Labels
              #
                   
              print "\n#### Stage 8: Create final labels \n"

              check_file("subfat."+inArgs.image)
              check_file("imfat."+inArgs.image)
              check_file("muscle."+inArgs.image)
              check_file("cortex."+inArgs.image)
              check_file("marrow."+inArgs.image)
              
              if False:
                   iwUtilities.iw_subprocess(["fslmaths", 
                                              "subfat."+inArgs.image,  "-add",
                                              "imfat."+inArgs.image,  "-add",
                                              "muscle."+inArgs.image,  "-add",
                                              "cortex."+inArgs.image,  "-add",
                                              "marrow."+inArgs.image,
                                              "all."+inArgs.image])
                   
                   iwUtilities.iw_subprocess(["fslmaths", "all."+inArgs.image, "-binv", "-mul", inArgs.mask, "other."+inArgs.image])



              shutil.copy(inArgs.image, "labels." + inArgs.image )
              
              iwUtilities.iw_subprocess(["fslmaths", "labels."+inArgs.image,  "-mul",  "0",  "labels."+inArgs.image])
              
              iwUtilities.iw_subprocess(["fslmaths", "subfat."+inArgs.image,  "-bin", "-mul",  "1", "-add", "labels."+inArgs.image, "labels."+inArgs.image])
              iwUtilities.iw_subprocess(["fslmaths", "imfat."+inArgs.image,   "-bin", "-mul",  "2", "-add", "labels."+inArgs.image, "labels."+inArgs.image])
              iwUtilities.iw_subprocess(["fslmaths", "muscle."+inArgs.image,  "-bin", "-mul",  "3", "-add", "labels."+inArgs.image, "labels."+inArgs.image])
              iwUtilities.iw_subprocess(["fslmaths", "cortex."+inArgs.image,  "-bin", "-mul",  "4", "-add", "labels."+inArgs.image, "labels."+inArgs.image])
              iwUtilities.iw_subprocess(["fslmaths", "marrow."+inArgs.image,  "-bin", "-mul",  "5", "-add", "labels."+inArgs.image, "labels."+inArgs.image])
                   
              if not inArgs.debug or inArgs.clean:
                   clean( baseName ) 

         else:
              print
              print "Unable to run mskSegmentThigh.py - failed input QA."
              iwQa.qa_exist( input_files, True )
              print


     #   
     #

     if  inArgs.stats:
          stats( labelFileName, "pmap.imfat."+inArgs.image, "pmap.muscle."+inArgs.image )

     # Quality Assurance output
     #

     if  inArgs.qo:

          if inArgs.debug:
               iwQa.freeview( intermediate_files +  output_files, True ) 
          else:
               iwQa.freeview( output_files, True ) 
