function [inNii, outNii] = mskPcasl_recon_v2( inRawDat,  inRawNii, flipFlag, filterFlag, rotateFlag )

%
%
%

if nargin < 1 || isempty(inRawDat)
    inRawDat = 'meas_raw.dat';
end

if nargin < 2 || isempty(inRawNii)
    inRawNii = 'raw.nii';
end

if nargin < 3 || isempty(flipFlag)
   flipFlag = [ 0 1 1 ]; 
end

if nargin < 4 || isempty(filterFlag)
   filterFlag = true; 
end

if nargin < 5 || isempty(rotateFlag)
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
nRef = 7;

matFileName = strrep(inRawDat, '.dat', '.mat');

if ~exist(matFileName, 'file')
    fprintf('\nReconstructing %s \n', inRawDat);
    
   
    kdat_cor = mskPcasl_kspace_correct(inRawDat);
    
    save(matFileName,'kdat_cor')

else
    
    fprintf('\nLoading %s \n', matFileName);
    load(matFileName,'kdat_cor')
end
       


%
% Filter data
%

if filterFlag
        
    fprintf('\t Filtering K-space with Stop Band \n');
    unfold_filename = 'idat7_cor.mat';
    
    if ~exist(unfold_filename, 'file')
        
        %    [b,a] = ellip(3,0.1,40,[0.9],'high')
        % [b,a] = ellip(5,6,50,[0.4 0.6],'stop');
        [b,a] = ellip(5,2,40,[0.2 0.7],'stop')
        
        figure(100); freqz(b,a)
        
        idat7_cor = mskPcasl_filter( kdat_cor, 10, a, b);
        
        save(unfold_filename, 'idat7_cor')
        
    else
        fprintf('\nLoading %s \n', unfold_filename);
        load(unfold_filename, 'idat7_cor')
        
    end
    
else
    
     idat2_cor = fif(kdat_cor);
     idat3_cor = permute(idat2_cor, [1 2 3 5 4]);
     idat7_cor = squeeze(sqrt( sum(idat3_cor .* conj(idat3_cor),5)));
end




%
% Save images
%

%
%  Reconstruct Images from K-Space
%

idat8_cor = idat7_cor;

if any(flipFlag)

    fprintf('\t Flipping image \n');
    for ii =1:length(flipFlag)
    if flipFlag(ii)
        idat8_cor   = flip(idat8_cor,ii);
    end
end
end

idat_save  = idat8_cor;

inNii      = load_untouch_nii(inRawNii);

scaleNii   = max(double(inNii.img(:))) / max(idat_save(:));

outNii     = inNii;
outNii.img = 0*inNii.img;

outNii.img(:,3:end,:,:) = double(idat_save *scaleNii);

%
%  Rotate Image if needed
%


if rotateFlag ~= 0 
    
    fprintf('\t Rotating image \n');
    outNii.img = permute(outNii.img, [2 1 3 4]);
    
end


outNii.hdr.dime.datatype = 16;  % float64'

save_untouch_nii(outNii, outRawNii);




%
%
%

    
function idat7_cor = local_highpass_filter( kdat_cor, b, a )

    nRef=8;
    %  run the data through the time-domain UNFOLD filtering routine
    idat2_cor = fif(kdat_cor);
    idat3_cor = permute(idat2_cor, [1 2 3 5 4]);
    idat4_cor = idat3_cor(:,:,:,2:end-nRef,:);
    
    I = idat4_cor;
    sz = size(I);
    Isynth = zeros([ sz(1 : 3 ) sz(4)*2 sz(5)]);
    Isynth(:,:,:,1:sz(4),: ) = flip(I,4);
    Isynth(:,:,:,sz(4)+(1:sz(4)),: ) = I;
    
    idat5_cor = 0*Isynth;
    
    for ii=1:sz(1)
        fprintf('%02d \n',  ii)
        for jj=1:sz(2)
            for kk=1:sz(3)
                for ll=1:sz(5)
                    idat5_cor(ii,jj,kk,:,ll) = filter(b,a, squeeze(Isynth(ii,jj,kk,:,ll)) );
                end
            end
        end
    end
    
    
    temporal_scale =  max(abs(idat4_cor(:)))/max(abs(idat5_cor(:)));
    idat5_cor      = idat5_cor * temporal_scale;
    
    idat6_cor                     = idat3_cor;
    idat6_cor(:,:,:,2:end-nRef,:) = idat5_cor(:,:,:,end-sz(4)+1:end,:);
    
    idat7_cor                     = squeeze(sqrt( sum(idat6_cor .* conj(idat6_cor),5)));
