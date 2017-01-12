function [inNii, outNii, nullNii] = mskPcasl_recon( inRawDat,  inRawNii, flipFlag, filterFlag, rotateFlag )

%
%
%

if nargin < 1 || isempty(inRawDat)
    inRawDat = 'meas_raw.dat';
end

if nargin < 2
    inRawNii = 'raw.nii';
end

if nargin < 3 || isempty(flipFlag)
   flipFlag = [  1 0 1 ]; 
end

if nargin < 4 || isempty(filterFlag)
   filterFlag = false; 
end

if nargin < 5 || isempty(rotateFlag)
   rotateFlag = 0 ; 
end


nRef= [ 5 4 ];

%
% Check that both files exist
%

if ~exist(inRawDat, 'file')
    error('Raw Siemens data file does not exist. %s', inRawDat) 
end

sosOutRawNii = strcat('sos.', strrep(inRawDat, '.dat', '.nii'));
vbcOutRawNii = strcat('vbc.', strrep(inRawDat, '.dat', '.nii'));
filterSosOutRawNii = strcat('filter.sos.', strrep(inRawDat, '.dat', '.nii'));
filterVbcOutRawNii = strcat('filter.vbc.', strrep(inRawDat, '.dat', '.nii'));

if ~isempty(inRawNii)
    
    if ~exist(inRawNii, 'file')
        error('Online Siemens image data file does not exist. %s', inRawNii)
    end
    
    if strcmp(inRawNii, sosOutRawNii)
        error('Input NII (%s) and output NII (%s) have the same filename', inRawNii, sosOutRawNii)
    end
        
    if strcmp(inRawNii, vbcOutRawNii)
        error('Input NII (%s) and output NII (%s) have the same filename', inRawNii, vbcOutRawNii)
    end
         
    if strcmp(inRawNii, filterSosOutRawNii)
        error('Input NII (%s) and output NII (%s) have the same filename', inRawNii, filterSosOutRawNii)
    end
          
    if strcmp(inRawNii, filterVbcOutRawNii)
        error('Input NII (%s) and output NII (%s) have the same filename', inRawNii, filterVbcOutRawNii)
    end
end


%
% Reconstruct K-Space
%


matFileName = strrep(inRawDat, '.dat', '.mat');

if ~exist(matFileName, 'file')
    fprintf('\nReconstructing %s \n', inRawDat);
    
   [ kdat_cor, nM0 ]  = mskPcasl_kspace_correct(inRawDat);
   save(matFileName,'kdat_cor', 'nM0')

else
    
    fprintf('\nLoading %s \n', matFileName);
    load(matFileName,'kdat_cor', 'nM0')
end
       
%
% Reconstruct
%

idat7_cor = fif(kdat_cor);
idat7_cor = permute(idat7_cor, [1 2 3 5 4]);

scale     = 4096/max(abs(idat7_cor(:)));
idat7_cor = scale*idat7_cor;

[~, sv] = vbc2(squeeze(idat7_cor(:,:,:,nM0,:)));

[idat7ss_cor, idat7vbc_cor] = local_collapse_coils( idat7_cor, sv);

unfold_filename = 'meas_recon.mat';

save(unfold_filename, 'idat7_cor', 'idat7ss_cor', 'idat7vbc_cor' )

local_save_images( idat7ss_cor,  sosOutRawNii, inRawNii, flipFlag, rotateFlag )
local_save_images( idat7vbc_cor, vbcOutRawNii, inRawNii, flipFlag, rotateFlag )

%
% Filter data
%

if filterFlag
    
    fprintf('\t Filtering K-space with tandem Low Pass Filter \n');
    
    idat8_cor   = zeros(size(idat7_cor));
    
    idat8ss_cor  = idat8_cor;
    idat8vbc_cor = idat8_cor;
    
    [nFreq,nPhase,nSlices,nVolumes,nCoils] =  size(idat7_cor);
    
    % [b,a] =ellip(3,0.1,40,[0.9],'high');
    [b,a] = ellip(3,5,50,[0.2 0.7],'stop');  % Stop band
    % freqz(b,a)
    
    for iiFreq=1:nFreq
        disp([iiFreq])
        
        for iiPhase=1:nPhase
            for iiSlice=1:nSlices
                for iiCoil=1:nCoils
                    
                    iiVolumes = [ 1:(nM0 - nRef(1)) (nM0+nRef(2)+1):nVolumes ];
                    
                    data = squeeze(idat7_cor(iiFreq,iiPhase,iiSlice, iiVolumes, iiCoil))';
                    sym_data =  [ fliplr(data), data ];
                    filter_data = filter(b,a,sym_data);
                    filter_data2 = filter_data((end-length(data)+1):end);
                    idat8_cor(iiFreq,iiPhase,iiSlice,iiVolumes,iiCoil) = filter_data2;
                    
                end
            end
        end
    end
    
    [idat8ss_cor, idat8vbc_cor] = local_collapse_coils( idat8_cor, sv);
    
    save(unfold_filename,  'idat8_cor','idat8ss_cor', 'idat8vbc_cor', '-append'  )
    
    local_save_images( idat7ss_cor, sosOutRawNii, inRawNii, flipFlag, rotateFlag )
    local_save_images( idat7vbc_cor, sosOutRawNii, inRawNii, flipFlag, rotateFlag )
    
end


%
% Local function to Save images
%

function local_save_images( idat, out_filename, inRawNii, flipFlag, rotateFlag )

if any(flipFlag)
    
    fprintf('\t Flipping image \n');
    for ii =1:length(flipFlag)
        if flipFlag(ii)
            idat   = flip(idat,ii);
        end
    end
end

idat_save  = double(idat);


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

    


if isreal(outNii.img)
    
    save_untouch_nii(outNii, out_filename);
    
else
    
    realOutNii = outNii;
    realOutNii.img = real(outNii.img);
    save_untouch_nii(realOutNii, strcat('real.', out_filename));
    
    imagOutNii     = outNii;
    imagOutNii.img = imag(outNii.img);
    save_untouch_nii(realOutNii, strcat('imag.', out_filename));
    
    absOutNii = outNii;
    absOutNii.img = abs(outNii.img);
    save_untouch_nii(absOutNii, strcat('magnitude.', out_filename));
    
    phaseOutNii = outNii;
    phaseOutNii.img = angle(outNii.img);
    save_untouch_nii(phaseOutNii, strcat('phase.', out_filename));
end
    



%
% Local Function to Collapse Coils with SOS and VBC
%

function [idat_ss, idat_vbc] = local_collapse_coils(idat, sv) 

     idat_ss = squeeze(sqrt( sum(idat .* conj(idat),5)));   
     
     idat_vbc = zeros(size(idat_ss));
     
     for iiSlice=1:size(idat,3)
         for iiVolume=1:size(idat,4)
             idat_vbc(:,:,iiSlice, iiVolume) = tmult(idat(:,:,iiSlice,iiVolume,:), sv(:,iiSlice).', 5);
         end
    end


