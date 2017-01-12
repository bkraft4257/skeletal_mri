function [inNii, outNii, nullNii] = mskPcasl_recon_v3( inRawDat,  inRawNii, flipFlag, filterFlag, rotateFlag, nM0 )

%
%
%

if nargin < 1 || isempty(inRawDat)
    inRawDat = 'meas_raw.dat';
end

if nargin < 2
    inRawNii = [];
end

if nargin < 3 || isempty(flipFlag)
   flipFlag = [ 0 1 1 ]; 
end

if nargin < 4 || isempty(filterFlag)
   filterFlag = false; 
end

if nargin < 5 || isempty(rotateFlag)
   rotateFlag = 0 ; 
end

if nargin < 6 || isempty(nM0)
   nM0 = 89; 
end

nRef= [ 5 4 ];

%
% Check that both files exist
%

if ~exist(inRawDat, 'file')
    error('Raw Siemens data file does not exist. %s', inRawDat) 
end

outRawNii = strrep(inRawDat, '.dat', '.nii');

if ~isempty(inRawNii)
    
    if ~exist(inRawNii, 'file')
        error('Online Siemens image data file does not exist. %s', inRawNii)
    end
    
    if strcmp(inRawNii, outRawNii)
        error('Input NII (%s) and output NII (%s) have the same filename', inRawNii, outRawNii)
        
    end
end


%
% Reconstruct K-Space
%


matFileName = strrep(inRawDat, '.dat', '.mat');

if ~exist(matFileName, 'file')
    fprintf('\nReconstructing %s \n', inRawDat);
    
   kdat_cor  = mskPcasl_kspace_correct(inRawDat);
   save(matFileName,'kdat_cor')

else
    
    fprintf('\nLoading %s \n', matFileName);
    load(matFileName,'kdat_cor')
end
       


%
% Filter data
%

if filterFlag
        
    fprintf('\t Filtering K-space with tandem Low Pass Filter \n');
    
    unfold_filename = 'idat7_cor.mat';
    
        
  kcsz      = size(kdat_cor);
  idat7_cor = fif(kdat_cor);
  idat8_cor = zeros(size(idat7_cor));  
  
    for c3=1:kcsz(3)
      for c4=1:kcsz(4)
          
        iiControls = [ 1:2:(nM0 - nRef(1)) (nM0+nRef(2)+1):2:kcsz(5) ];
        
        idat8_cor(:,:,c3,c4,iiControls) = ...
            unfold(squeeze(idat7_cor(:,:,c3,c4,iiControls)), 'lowp'); 
        
        
        iiLabels = iiControls + 1;
        
        idat8_cor(:,:,c3,c4,iiLabels) = ...
            unfold(squeeze(idat7_cor(:,:,c3,c4,iiLabels)),'lowp'); 
        
        iiRef    = (nM0 - nRef(1)+1):(nM0+nRef(2));
            
        idat8_cor(:,:,c3,c4,iiRef) = squeeze(idat7_cor(:,:,c3,c4,iiRef));
        
      end;
    end;

    idat7ss_cor = squeeze(sqrt( sum(idat7_cor .* conj(idat7_cor),4)));
    idat8ss_cor = squeeze(sqrt( sum(idat8_cor .* conj(idat8_cor),4)));
        
    save(unfold_filename, 'idat7_cor', 'idat8_cor',  'idat7ss_cor','idat8ss_cor'  )
        
    
else
    
     idat2_cor = fif(kdat_cor);
     idat3_cor = permute(idat2_cor, [1 2 3 5 4]);
     idat8ss_cor = squeeze(sqrt( sum(idat3_cor .* conj(idat3_cor),5)));
end




%
% Save images
%

%
%  Reconstruct Images from K-Space
%

idat9_cor = idat8ss_cor;

if any(flipFlag)
    
    fprintf('\t Flipping image \n');
    for ii =1:length(flipFlag)
        if flipFlag(ii)
            idat9_cor   = flip(idat9_cor,ii);
        end
    end
end

idat_save  = double(idat9_cor);


if exist(inRawNii, 'file')
    inNii      = load_untouch_nii(inRawNii);
    scaleNii   = double(max(double(inNii.img(:))) / max(idat_save(:)));

else
    
    sz         = size(idat_save);
    sz(2)      = 64;
    
    inNii      = make_nii(zeros(sz));
    scaleNii   = 1.0;
end


outNii     = inNii;
outNii.img = double(0*inNii.img);

outNii.img(:,3:end,:,:) = double(idat_save * scaleNii);

%
%  Rotate Image if needed
%


if rotateFlag ~= 0 
    
    fprintf('\t Rotating image \n');
    outNii.img = permute(outNii.img, [2 1 3 4]);
    
end



outNii.hdr.dime.datatype = 64;  % float64'
outNii.hdr.dime.bitpix   = 64;  % float64'

if exist(inRawNii, 'file')
    save_untouch_nii(outNii, outRawNii);
else
    save_nii(outNii, outRawNii);
end


