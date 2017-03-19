% Reset path in Matlabv


%------------ MSK_MATLAB_PATH ----------------------------%

% export MSK_MVO2_THOMPSON=${SOFTWARE_PATH}/mvo2_thompson/
% export MSK_NCIGT=${SOFTWARE_PATH}/ncigt_fil_v2.2_20150119_x64_0/

mskPath       = getenv('MSK_MATLAB');

mskMvo2Path         = getenv('MSK_MVO2_THOMPSON');
mskMvo2OriginalPath = fullfile(mskMvo2Path, '..', 'original');


if (exist(mskPath,'dir') == 7)
    path(mskPath, path );
    path(mskMvo2Path, path );
    path(mskMvo2OriginalPath, path );
     
    mvo2_thompson_startup( mskMvo2 )
    
    path(mskPath, path );
    path(fullfile(mskMvo2Path,'include'), path );
    path(fullfile(mskMvo2Path,'source_code'), path );
    path(fullfile(mskMvo2Path,'source_code','matlab'), path );
    path(fullfile(mskMvo2Path,'source_code','matlab','mex'), path );
    path(fullfile(mskMvo2Path,'demos'), path );
    path(fullfile(mskMvo2Path,'demos','display'), path );
    path(fullfile(mskMvo2Path,'demos','dicom_demo'), path );
    path(fullfile(mskMvo2Path,'demos','mex_demo'), path );
    path(fullfile(mskMvo2Path,'demos','nd_demo'), path );
    path(fullfile(mskMvo2Path,'lib'), path );
    
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

