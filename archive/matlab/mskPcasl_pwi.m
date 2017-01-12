function [inNii, outNiillr, nullNii] = mskPcasl_pwi( inClNii )

%
%
%

if nargin < 1
    inClNii = 'cl.nii';
end
%
% Check that both files exist
%

if ~isempty(inClNii)
    
    if ~exist(inClNii, 'file')
        error('Online Siemens image data file does not exist. %s', inClNii)
    end
    
end

clNii     = load_untouch_nii(inClNii);


%
% Blood Image
%

bloodNii           = clNii;
bloodNii.img       = clNii.img(:,:,:,1:2:end-1)    - clNii.img(:,:,:,2:2:end) ;
bloodNii.img       = bloodNii.img(:,:,:,1:2:end-1) + bloodNii.img(:,:,:,2:2:end);

nPwi                        = size(bloodNii.img, 4);
bloodNii.hdr.dime.dim(5) = nPwi;

save_untouch_nii(bloodNii, 'blood.nii');

mskPcasl_slice_mean( 'blood.nii' )


nAvg = 4; 

bloodNii           = clNii;
bloodNii.img       = clNii.img(:,:,:,1:2:end-1)    - clNii.img(:,:,:,2:2:end) ;
bloodNii.img       = mean(bloodNii.img(:,:,:,1:nAvg),4);

nPwi                        = size(bloodNii.img, 4);
bloodNii.hdr.dime.dim(5) = nPwi;

save_untouch_nii(bloodNii,  sprintf('first_%02d.blood.nii', nAvg));



bloodNii           = clNii;
bloodNii.img       = clNii.img(:,:,:,1:2:end-1)    - clNii.img(:,:,:,2:2:end) ;
bloodNii.img       = mean(bloodNii.img(:,:,:,end-nAvg:end),4);

nPwi                     = size(bloodNii.img, 4);
bloodNii.hdr.dime.dim(5) = nPwi;

save_untouch_nii(bloodNii, sprintf('last_%02d.blood.nii', nAvg));

%
% Create Tissue Image
%

tissueNii           = clNii;
tissueNii.img       = clNii.img(:,:,:,1:2:end-1)     + clNii.img(:,:,:,2:2:end) ;
tissueNii.img       = tissueNii.img(:,:,:,1:2:end-1) + tissueNii.img(:,:,:,2:2:end);

nPwi                      = size(tissueNii.img, 4);
tissueNii.hdr.dime.dim(5) = nPwi;

save_untouch_nii(tissueNii, 'tissue.nii');


%
% Create Fat Image
%


fatNii           = clNii;

fatNii.img       = clNii.img(:,:,:,1:2:end-1)  + clNii.img(:,:,:,2:2:end) ;
fatNii.img       = fatNii.img(:,:,:,1:2:end-1) - fatNii.img(:,:,:,2:2:end);

nPwi                   = size(fatNii.img, 4);
fatNii.hdr.dime.dim(5) = nPwi;

save_untouch_nii(fatNii, 'fat.nii');


% placeCycle = mod(floor( (1+(1:nCl))/2),2);
% indexTe1   = find(placeCycle==0);
% indexTe2   = find(placeCycle==1);
% 
% te1Nii                 = clNii;
% te1Nii.img             = clNii.img(:,:,:,indexTe1);
% 
% nTe1                   = size(te1Nii.img,4);
% te1Nii.hdr.dime.dim(5) = nTe1;
% save_untouch_nii(te1Nii, 'te1.nii');
% 
% indexNull = mskPcasl_null_index( nTe1 );
% 
% te1NullNii             = te1Nii;
% te1NullNii.img         = te1Nii.img(:,:,:, indexNull);
% 
% save_untouch_nii(te1Nii, 'null.te1.nii');
% 
% 
% 
% te2Nii                 = clNii;
% te2Nii.img             = clNii.img(:,:,:,indexTe2);
% nTe2                   = size(te2Nii.img,4);
% te2Nii.hdr.dime.dim(5) = nTe2;
% 
% save_untouch_nii(te2Nii, 'te2.nii');
% 
% indexNull = mskPcasl_null_index( nTe2 );
% 
% te2NullNii             = te2Nii;
% te2NullNii.img         = te2Nii.img(:,:,:, indexNull);
% 
% save_untouch_nii(te2Nii, 'null.te2.nii');

%
%
%





return

