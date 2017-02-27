function msk_estimate_fat_fraction( inN4T2w, inLabels, inStd )

%% Initialization

if nargin<1 || isempty(inN4T2w)
    inN4T2w='t2w_n4';
end

if nargin<2 || isempty(inLabels)
    inLabels='t2w_n4_labels';
end

if nargin<3 || isempty(inStd)
    inStd=1;
end

%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s.nii', inN4T2w);
n4T2wNii       = local_load_nii(n4T2wFileName);

templateNii = n4T2wNii;

%%  Read in Label Images
%

labelFileName  = sprintf('%s.nii', inLabels);
labelNii       = local_load_nii(labelFileName);



%% AT Stats
%

labels    = double(labelNii.img);

thighMask       = labels>0;
atMask          = (labels==1);
smMask          = (labels==2);
boneCortexMask  = (labels==3);

n4T2w    = double(n4T2wNii.img .* thighMask);
normN4T2w    = n4T2w/max(n4T2w(:));

atNormN4T2w   = normN4T2w .* atMask;
smNormN4T2w   = normN4T2w .* smMask;
atSmNormN4T2w = atNormN4T2w + smNormN4T2w;


otsuThreshold = graythresh(atSmNormN4T2w(:));

tmpMask       = (smNormN4T2w>0) & (smNormN4T2w<otsuThreshold);
smStats       = [ mean(smNormN4T2w(tmpMask(:))) ...
                  std(smNormN4T2w(tmpMask(:))) ];
              
tmpMask       = atNormN4T2w>=otsuThreshold;
atStats       = [ mean(atNormN4T2w(tmpMask(:))) ...
                  std(atNormN4T2w(tmpMask(:))) ];
              


smThreshold = smStats(1) + inStd*smStats(2);
atThreshold = atStats(1) - inStd*atStats(2);

clear linN4T2w; 

linN4T2w{1} = normN4T2w;

linN4T2w{2} = linN4T2w{1};
linN4T2w{2}(normN4T2w<=smThreshold) = smThreshold;
linN4T2w{2}(normN4T2w>=atThreshold) = atThreshold;

linN4T2w{3} = (linN4T2w{2} -smThreshold) .* thighMask;
linN4T2w{4} = (1+linN4T2w{3}/ (atThreshold-smThreshold)) .* thighMask .* (1-boneCortexMask);


estimatedFatFractionNii  = templateNii;
estimatedFatFractionNii.img = linN4T2w{end};

save_untouch_nii(estimatedFatFractionNii, sprintf('%s_atFraction.nii', inN4T2w))

estimatedMuscleFractionNii     = templateNii;
estimatedMuscleFractionNii.img = (3-linN4T2w{end}) .* thighMask .* (1-boneCortexMask);

save_untouch_nii(estimatedMuscleFractionNii, sprintf('%s_smFraction.nii', inN4T2w))

return


function outNii = local_load_nii(inNiiFileName)


%% Read in raw image and normalize
%

if exist(inNiiFileName, 'file')==2
    
    outNii = load_untouch_nii(inNiiFileName);

    
elseif exist(strcat(inNiiFileName,'.gz'), 'file')==2
    
    system(sprintf('%s.gz',inNiiFileName));
    outNii = load_untouch_nii(inNiiFileName);
else
    
    error('No File Found');
    
end
