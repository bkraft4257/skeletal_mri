function [inNii, outNii, nullNii] = mskPcasl_extract( inRawNii )

%
%
%

if nargin < 1
    inRawNii = 'raw.nii';
end

%
% Check that both files exist
%

if ~isempty(inRawNii)
    
    if ~exist(inRawNii, 'file')
        error('Online Siemens image data file does not exist. %s', inRawNii)
    end
    
end

rawNii     = load_untouch_nii(inRawNii);
raw        = double(rawNii.img);

%
% Find M0 and Save M0
%

meanRaw = squeeze(sum(sum(sum(raw,1),2),3));
[ maxRaw, indexM0 ] = max(meanRaw);


m0Nii                 = rawNii;
m0Nii.img             = rawNii.img(:,:,:,indexM0);
m0Nii.hdr.dime.dim(5) = 1;


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


nRaw     = rawNii.hdr.dime.dim(5);

indexCalibration = (0:(nRef+nRefPost-1)) + (indexM0-nRef);

calNii                 = rawNii;
calNii.img             = rawNii.img(:,:,:,indexCalibration);
nCalibration           = length(indexCalibration);
calNii.hdr.dime.dim(5) = nCalibration;


save_extracted(calNii, 'calibration', indexCalibration);

%
% Control Label Pairs
%

nRaw     = rawNii.hdr.dime.dim(5);

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

clNii                 = rawNii;
clNii.img             = rawNii.img(:,:,:,indexCl);
nCl                   = length(indexCl);
clNii.hdr.dime.dim(5) = nCl;


save_extracted(clNii, 'cl', indexCl);



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
