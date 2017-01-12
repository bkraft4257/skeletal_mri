function [inNii, outNii] = mskPcasl_recon( inRawDat,  inRawNii, flipFlag, rotateFlag )

if nargin < 1 || isempty(inRawDat)
    inRawDat = 'meas_raw.dat';
end

if nargin < 2 || isempty(inRawNii)
    inRawNii = 'raw.nii';
end

if nargin < 3 || isempty(flipFlag)
   flipFlag = [ 0 1 1 ]; 
end

if nargin < 4 || isempty(rotateFlag)
   rotateFlag = 0 ; 
end



%
% Check that both files exist
%

if ~exist(inRawDat, 'file')
    error('Raw Siemens data file does not exist. %s', inRawDat)
    
end

if ~exist(inRawNii, 'file')
     error('Online Siemens image data file does not exist. %s', inRawNii)
end

outRawNii = strrep(inRawDat, '.dat', '.nii');

if strcmp(inRawNii, outRawNii)
    error('Input NII (%s) and output NII (%s) have the same filename', inRawNii, outRawNii)
    
end


%
% Reconstruct K-Space
%

kFileName = strrep(inRawDat, '.dat', '.mat');

if ~exist(kFileName, 'file')
    fprintf('\nReconstructing %s \n', inRawDat);
    kdat_cor = mskPcasl_kspace_correct(inRawDat);
    
    save(kFileName,'kdat_cor')

else
    
    fprintf('\nLoading %s \n', kFileName);
    load(kFileName,'kdat_cor')
end
    

%
%  Flip  K-Space as needed
%

kdat2_cor = kdat_cor;

if any(flipFlag)
    
    fprintf('\t Flipping data \n');
    
    for ii =1:length(flipFlag)
        if flipFlag(ii)
            kdat2_cor   = flip(kdat2_cor,ii);
        end
    end
end

%
%
%

idat2_cor     = fif(kdat2_cor);
idat3_cor     = squeeze(sqrt( sum(idat2_cor .* conj(idat2_cor),4)));

%
% Save images
%

inNii                   = load_untouch_nii(inRawNii);

outNii                   = inNii;
outNii.img               = double(outNii.img);

scaleNii                 = max(abs(double(inNii.img(:)))) / max(abs(idat3_cor(:)));

outNii.img(:,2:end-1,:,:)  = scaleNii * double(idat3_cor);

%
%  Rotate Image if needed
%


if rotateFlag ~= 0 
    
    fprintf('\t Rotating image \n');
    outNii.img = permute(outNii.img, [2 1 3 4]);
    
end


outNii.hdr.dime.datatype = 16;  % float64'

save_untouch_nii(outNii, outRawNii);



