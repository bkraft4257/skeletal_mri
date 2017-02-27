#!/aging1/software/anaconda/bin/python

"""
  icFsSkullStrip.py  strips the skull for a range of watershed threshold values.  Default value is 25.
  This code will apply transformation from a threshold of 20 to 30.  The results will be written to 
  the directory mri/skullstrip.  Files will be converted from MGZ format to NIFTI.GZ format.  Once 
  converted files will be concatenated to NIFTI for easy viewing. 

  More information can be found at https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/SkullStripFix_freeview
"""

import sys      
import os                                               # system functions
import glob
import shutil
import subprocess
import distutils

import  argparse

#
# First Quality Assurance Test 1
#
    
def  priPaslQa1():

    qaList1 = [ 't2w.nii.gz',              
                'mask.muscle.nii.gz',
                'translation.m0_To_mask.muscle.nii.gz',          # M0 image
                'translation.mask.m0_To_mask.muscle.nii.gz',     # M0 image
                'syn.mask.m0_To_mask.muscle.nii.gz' ]
    

    qaTest1=True
    
    for f in qaList1:
        fileExist = os.path.isfile(f)
        qaTest1   = qaTest1 & fileExist
   
   
    if qaTest1:
        print "priPaslResult.py, QA1, Passed, Warp Test, " + inArgs.inDirectory 
  
        systemCommand = ("freeview " +
                         qaList1[0]  + ":visible=1 " +
                         qaList1[1]  + ":visible=1:opacity=0.8 " +
                         qaList1[2]  + ":visible=0 " +
                         qaList1[3]  + ":visible=0:colormap=jet:colorscale=0.1,0.8:opacity=0.4 " +
                         qaList1[4]  + ":visible=1:colormap=jet:colorscale=0.1,1.0:opacity=0.4 " )
        
        if inArgs.debug:
            print
            print systemCommand
            print

        if inArgs.display:
            os.system( systemCommand + " 2> /dev/null &")    
  
    else:
        print "priPaslResult.py, QA1, Failed, Warp Test, " + inArgs.inDirectory 
   
        for f in qaList1:
            if not os.path.isfile(f):
                print "\t " +  f + " does not exist"

        print
                
    return qaTest1

#
# Second Quality Assurance Test 2
#

def  priPaslQa2():

     qaList2 = [ 't2w.nii.gz',
                 'labels.muscle.nii.gz',
                 'mask.muscle.nii.gz',
                 'translation.m0_To_mask.muscle.nii.gz',     # M0 image
                 'translation.pwi_To_mask.muscle.nii.gz',
                 'syn.m0_To_mask.muscle.nii.gz',             # M0 image
                 'syn.pwi_To_mask.muscle.nii.gz' ]
     
     qaTest2=True
     
     for f in qaList2:
         fileExist = os.path.isfile(f)
         qaTest2   = qaTest2 & fileExist
         
         
     if qaTest2:
             
         print "priPaslResult.py, QA2, Passed, Visual Inspection Test, " + inArgs.inDirectory 
         
         systemCommand = ( "freeview "  +
                           qaList2[0] + " " +
                           qaList2[1] + ":colormap=lut:visible=0 " +
                           qaList2[2] + ":visible=0 " +
                           qaList2[3] + ":visible=0:colormap=jet "  +
                           qaList2[4] + ":visible=0:colormap=heat:heatscale=0,150,300:opacity=0.5 " +
                           qaList2[5] + ":visible=0:colormap=jet " +
                           qaList2[6] + ":visible=1:colormap=heat:heatscale=0,150,300:opacity=0.5" )
         if inArgs.debug:
             print
             print systemCommand
             print

         if inArgs.display:
             os.system( systemCommand + " 2> /dev/null &")    
             
     else:
         print "priPaslResult.py, QA2, Failed, Visual Inspection Test, " + inArgs.inDirectory 

         for f in qaList2:
             if not os.path.isfile(f):
                 print "\t " + f + " does not exist"
                 
         print        

     return qaTest2

#
# Quality Assurance Test 4. Intended for 4D files.
#

def  priPaslQa4():
     qaList3 = [ 't2w.nii.gz',
                 'labels.muscle.nii.gz',
                 'mask.muscle.nii.gz',
                 'syn.mask.m0_To_mask.muscle.nii.gz',     # M0 image
                 'syn.m0_To_mask.muscle.nii.gz',          # M0 image
                 'syn.pwi_To_mask.muscle.nii.gz' ]    
     
     qaTest3=True
     
     for f in qaList3:
         fileExist = os.path.isfile(f)
         qaTest3   = qaTest3 & fileExist
         
         
     if qaTest3:
         print "priPaslResult.py, QA4, Passed, Visual 4D Inspection Test, " + inArgs.inDirectory 
         
         systemCommand = ( "freeview "  +
                           qaList3[0] + " " +
                           qaList3[1] + ":colormap=lut:visible=0 " +
                           qaList3[2] + ":visible=0 " +
                           qaList3[3] + ":colormap=jet:visible=0 " +
                           qaList3[4] + ":visible=0 "  + 
                           qaList3[5] + ":colormap=heat:heatscale=0,150,300:opacity=0.5" )
         if inArgs.debug:
             print
             print systemCommand
             print

         if inArgs.display:
             os.system( systemCommand + " 2> /dev/null &")    
             
     else:
         print "priPaslResult.py, QA4, Failed, Visual Inspection Test, " + inArgs.inDirectory 
         
         for f in qaList3:
             if not os.path.isfile(f):
                 print "\t " + f + " does not exist"
                 
         print        
                    
                        
     return qaTest3


#
# Quality Assurance Test 3
#
    
def  priPaslQa3():

    qaList5 = [ 't2w.nii.gz',              
                'frequencyBackground.mask.t2w.nii.gz',
                'phaseBackground.mask.t2w.nii.gz' ]
    

    qaTest5=True
   
    for f in qaList5:
        fileExist = os.path.isfile(f)
        qaTest5   = qaTest5 & fileExist
   
   
    if qaTest5:
        print "priPaslResult.py, QA3, Passed, Background Mask Tests, " + inArgs.inDirectory 
  
        systemCommand = ("freeview " +
                         qaList5[0]  + " " +
                         qaList5[1]  + ":colormap=jet:colorscale=0.1,0.5:opacity=0.2 " +
                         qaList5[2]  + ":colormap=jet:opacity=0.2 ")
        
        if inArgs.debug:
            print
            print systemCommand
            print

        if inArgs.display:
            os.system( systemCommand + " 2> /dev/null &")    
  
    else:
        print "priPaslResult.py, QA3, Failed, Warp Test, " + inArgs.inDirectory 
   
        for f in qaList5:
            if not os.path.isfile(f):
                print "\t " +  f + " does not exist"

        print
                
    return qaTest5


#
# First Quality Assurance Test 1
#
    
def  priPaslQa5():

    qaList1 = [ 'translation.m0_To_mask.muscle.nii.gz',          # M0 image
                'translation.mask.m0_To_mask.muscle.nii.gz' ]

    

    qaTest1=True
    
    for f in qaList1:
        fileExist = os.path.isfile(f)
        qaTest1   = qaTest1 & fileExist
   
   
    if qaTest1:
        print "priPaslResult.py, QA5, Passed, Warp Test, " + inArgs.inDirectory 
  
        systemCommand = ("freeview " +
                         qaList1[0]  + ":visible=1:opacity=1.0 " +
                         qaList1[1]  + ":visible=1:colormap=jet:colorscale=0.1,1.0:opacity=0.4 " )
        
        if inArgs.debug:
            print
            print systemCommand
            print

        if inArgs.display:
            os.system( systemCommand + " 2> /dev/null &")    
  
    else:
        print "priPaslResult.py, QA5, Failed, Warp Test, " + inArgs.inDirectory 
   
        for f in qaList1:
            if not os.path.isfile(f):
                print "\t " +  f + " does not exist"

        print
                
    return qaTest1


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

     parser = argparse.ArgumentParser(prog='priPaslResults')
     parser.add_argument('--inDirectory', help='directory to use', action='store', default=os.getcwd())
     parser.add_argument("-d", "--display",     help="Display results in freeview",        action='store_true',  default=True )
     parser.add_argument("-n", "--no-display",  help="Do not display results in freeview", action='store_false', default=False, dest="display" )
     parser.add_argument("-1", "--qa1",               help="Perform test 1", default=False, action="store_true",  dest="qa1" )
     parser.add_argument("-2", "--qa2",               help="Perform test 2", default=False, action="store_true",  dest="qa2" )
     parser.add_argument("-3", "--qa3",               help="Perform test 3", default=False, action="store_true",  dest="qa3" )
     parser.add_argument("-4", "--qa4",               help="Perform test 4", default=False, action="store_true",  dest="qa4" )
     parser.add_argument("-5", "--qa5",               help="Perform test 5", default=False, action="store_true",  dest="qa5" )
     parser.add_argument("--debug",             help="Debug flag", action="store_true", default=False )

     #qa1 = parser.add_mutually_exclusive_group(required=False)
     #qa1.add_argument('--qa1',    dest='qa1', action='store_true')
     #qa1.add_argument('--no-qa1', dest='qa1', action='store_false')

     #parser.set_defaults(['--qa1'])

     inArgs = parser.parse_args()

     if inArgs.debug:
         print "inArgs.inDirectory = " +  str(inArgs.inDirectory)
         print "inArgs.display     = " +  str(inArgs.display)
         print "inArgs.qa1         = " + str(inArgs.qa1  )
         print "inArgs.qa2         = " + str(inArgs.qa2 )
         print "inArgs.debug       = " + str(inArgs.debug)

     print 

     os.chdir(inArgs.inDirectory)

     if inArgs.qa1:
         priPaslQa1()

     if inArgs.qa2:
         priPaslQa2()

     if inArgs.qa3:
         priPaslQa3()

     if inArgs.qa4:
         priPaslQa4()

     if inArgs.qa5:
         priPaslQa5()

     print
