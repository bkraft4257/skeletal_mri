function [inNii, outNii, nullNii] = mskPcasl_extract_from_mat( inRawMat, inOnlineReconNii )

%
%
%

if nargin < 1
    inRawMat = 'meas_recon.mat';
end

if nargin < 2
    inOnlineReconNii = 'raw.nii';
end

%
% Check that both files exist
%

if ~isempty(inRawMat)
    
    if ~exist(inRawMat, 'file')
        error('Online Siemens image data file does not exist. %s', inRawMat)
    end
    
end>

if ~isempty(inOnlineReconNii)
    
    if ~exist(inOnlineReconNii, 'file')
        error('Online Siemens image data file does not exist. %s', inOnlineReconNii)
    end
    
end


%
%
%

rawMat     = load(inRawMat);
onlineNii  = load_untouch_nii(inOnlineReconNii);

raw        = rawMat.idat8vbc_cor;


%
% Find M0 and Save M0
%

meanRaw = squeeze(sum(sum(sum(sum(abs(raw),1),2),3),5));
[ maxRaw, indexM0 ] = max(meanRaw);


m0Nii                 = onlineNii;
m0Nii.hdr.dime.dim(5) = 1;

complexM0 = raw(:,:,:,indexM0,:);
m0        = 0 * m0Nii.img(:,:,:,1);

m0Scale   = 1e7;
tmp             = m0Scale*sqrt( squeeze( sum(complexM0 .* conj(complexM0), 5)) );
m0(:,2:end-1,:) = int16(tmp);

m0Nii.img             = m0;
save_extracted(m0Nii, 'm0', indexM0)



%
% Extract Calibration Data
%

if indexM0 > 80
    nRef     = 8;
    nRefPost = 4;
else
    nRef     = 8;
    nRefPost = 0;
end


indexCalibration = (0:(nRef+nRefPost-1)) + (indexM0-nRef);

calNii                 = onlineNii;
cal                    = 0*onlineNii.img(:,:,:,indexCalibration);

nCalibration           = length(indexCalibration);
calNii.hdr.dime.dim(5) = nCalibration;

complexCal       = raw(:,:,:,indexCalibration,:);
tmp              = m0Scale*sqrt( squeeze( sum(complexCal .* conj(complexCal), 5)) );
cal(:,2:end-1,:,:) = int16(tmp);

calNii.img             = abs(cal);
save_extracted(calNii, 'calibration', indexCalibration);


%
% Control Label Pairs
%

nRaw     = onlineNii.hdr.dime.dim(5);

startIndex = 3;
stopIndex  = startIndex + ((indexM0-nRef - startIndex ) - mod(indexM0-nRef - startIndex,4));

indexCl1 = startIndex:stopIndex-1;

startIndex = (indexM0+nRefPost)+4;
stopIndex  = startIndex + ((nRaw-startIndex) - mod(nRaw-startIndex,4)) - 1;
indexCl2   = startIndex:stopIndex;

if indexM0 <= 80
    indexCl  = indexCl1;
else
    indexCl  = [ indexCl1 indexCl2 ];

end


clNii                 = onlineNii;
clNii.img             = onlineNii.img(:,:,:,indexCl,1);
cl                    = 0*clNii.img;

nCl                   = length(indexCl);
clNii.hdr.dime.dim(5) = nCl;
clNii.img             = abs(raw(:,:,:,indexCl,:));

save_extracted(clNii, 'cl', indexCl);


%
% PWI
%

pwiNii                = onlineNii;

nPwi                   = length(indexCl)/2;
pwiNii.hdr.dime.dim(5) = nPwi;

pwiNii.img             = onlineNii.img(:,:,:,1:nPwi,1);
pwi                    = 0*pwiNii.img;

cl = double(raw(:,:,:,indexCl,:));
c  = cl(:,:,:,1:2:end-1,:);
l  = cl(:,:,:,2:2:end,:);
pwi =  m0Scale*(abs(c)-abs(l));

pwiNii.img(:,2:end-1,:,:) =pwi;

size(pwiNii.img)

save_extracted(pwiNii, 'pwi', indexCl);



return


function save_index( inFileName, index )

header1 = 'index';
fid=fopen(inFileName,'w');
% fprintf(fid, [header1 '\n']);
fprintf(fid, '%d \n', index(:)-1);
fclose(fid);

function save_extracted( inNii, inFileName, inIndex )

save_untouch_nii(inNii, strcat(inFileName, '.nii'));
save_index(strcat(inFileName,'.index'), inIndex)
