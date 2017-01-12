% Reset path in Matlab


%------------ MSK_MATLAB_PATH ----------------------------%
mskPath       = getenv('MSK_MATLAB');

mskMvo2Path         = getenv('MSK_MATLAB_MVO2');
mskMvo2OriginalPath = fullfile(mskMvo2Path, '..', 'original');


if (exist(mskPath,'dir') == 7)
    path(mskPath, path );
    path(mskMvo2Path, path );
    path(mskMvo2OriginalPath, path );
     
    mvo2_thompson_startup( mskMvo2OriginalPath )
    
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/include'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/source_code'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/source_code/matlab'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/source_code/matlab/mex'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/demos'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/demos/display'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/demos/dicom_demo'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/demos/mex_demo'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/demos/nd_demo'), path );
    path(fullfile(mskPath,'ncigt_fil_v2.2_20150119_x64_0/lib'), path );
    
    path(fullfile(mskPath,'shoge/mscripts_for_bk'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mri'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mri/other'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mri/parallel'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mri/parallel/grappa'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mri/mtlib'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mbin'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mathlib'), path );
    path(fullfile(mskPath,'shoge/mscripts_for_bk/mathlib/tensor'), path );
    
    path('/bkraft1/studies/mvo2/MatlabCode/maxwork', path);
    
end

clear mskPath

%-----------------------------------------------------%

