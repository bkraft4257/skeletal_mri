function msk_stats( inN4T2w, inLabels, inAtLcc )

%% Initialization

if nargin<1
    inN4T2w='t2w_n4';
end

if nargin<2
    inLabels='t2w_labels';
end

if nargin<3
    inAtLcc='t2w_atLCC';
end

cleanFlag = 'true';

inSmoothFactor = 3;
inPrefix    = 'jmri';
prefix      = sprintf('%s_%s', inPrefix, inN4T2w);

debugFlag = false;

%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s.nii', inN4T2w);
n4T2wNii       = local_load_nii(n4T2wFileName);

templateNii = n4T2wNii;

n4T2w    = double(n4T2wNii.img);
normN4T2w    = n4T2w/max(n4T2w(:));

[nFreq, nPhase, nSlices ]= size(n4T2w);

%%  Read in Label Images
%

labelFileName  = sprintf('%s.nii', inLabels);
labelNii       = local_load_nii(labelFileName);

%%  Read in AT Largest Connected Component
%

atLccFileName  = sprintf('%s.nii', inAtLcc);
atLccNii       = local_load_nii(atLccFileName);


%% AT Stats
%

labels    = double(labelNii.img);
atLccMask = logical(atLccNii.img);

atMask    = (labels==1);
smMask    = (labels==2);
atSmMask  = atMask | smMask;


atNormN4T2w   = normN4T2w .* atMask;
smNormN4T2w   = normN4T2w .* smMask;
atSmNormN4T2w = atNormN4T2w + smNormN4T2w;



%%  Classify Muscle
%

[nFreq, nPhase, nSlices ] = size(labelNii.img);

smSegmentNii     = templateNii;

nSegments        = [1 5 9];

for iiSegments=nSegments
    
    
    atSmThresholds   = multithresh(atSmNormN4T2w(:), iiSegments);

    fprintf('%d ', iiSegments, atSmThresholds)
    fprintf('\n');
    
    smSegmentNii.img = imquantize(smNormN4T2w,atSmThresholds) .* smMask;

    save_untouch_nii(smSegmentNii, sprintf('%s_smSegment_%02d.nii', 't2w', iiSegments))

end

%% Normalize Muscle by AT and SM mask
%

maxAtLccNormN4T2w = max(atSmNormN4T2w(logical(atLccMask(:))));

normAtSmNii      = templateNii;
normAtSmNii.img  =  atSmNormN4T2w/maxAtLccNormN4T2w;

save_untouch_nii(normAtSmNii, sprintf('%s_atSmNormN4.nii', 't2w'))

%% Normalize Muscle by maximum
%


normN4T2wNii      = templateNii;
normAtSmNii.img  =  atSmNormN4T2w/maxAtLccNormN4T2w;

save_untouch_nii(normSmNii, sprintf('%s_normAtSmN4.nii', 't2w'))

% figure(1); histogram(smSegmentNii.img(smSegmentNii.img>0));

% stats.at.volume    = voxelVolume * sum(atMask(:));
% stats.at.mean      = mean(n4T2w(atMask(:)));
% stats.at.stdDev    = mean(n4T2w(atMask(:)));
% 
% stats.sm.volume    = voxelVolume * sum(smMask(:));
% stats.sm.mean      = mean(n4T2w(smMask(:)));
% stats.sm.stdDev    = mean(n4T2w(smMask(:)));
% 
% stats.atLCC.volume    = voxelVolume * sum(atLccMask(:));
% stats.atLCC.mean      = mean(n4T2w(atLccMask(:)));
% stats.atLCC.stdDev    = mean(n4T2w(atLccMask(:)));

return


function outNii = local_load_nii(inNiiFileName)


%% Read in raw image and normalize
%

if exist(inNiiFileName, 'file')==2
    
    outNii = load_untouch_nii(inNiiFileName);
    
elseif exist(strcat(n4T2wFileName,'.gz'), 'file')==2
    
    system(sprintf('%s.gz',inNiiFileName));
    outNii = load_untouch_nii(inNiiFileName);
else
    
    error('No File Found');
    
end
