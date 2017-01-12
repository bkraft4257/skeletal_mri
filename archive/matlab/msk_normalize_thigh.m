function msk_normalize_thigh( inN4T2w, inLabels, inAtLcc )

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

%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s.nii', inN4T2w);
n4T2wNii       = local_load_nii(n4T2wFileName);

templateNii = n4T2wNii;

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

thighMask = labels>0;
atMask    = (labels==1);
smMask    = (labels==2);
atSmMask  = atMask | smMask;

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
              

nStd = 0;

smThreshold = smStats(1) + nStd*smStats(2);
atThreshold = atStats(1) - nStd*atStats(2);

clear linN4T2w; 

linN4T2w{1} = normN4T2w;

linN4T2w{2} = linN4T2w{1};
linN4T2w{2}(normN4T2w<=smThreshold) = smThreshold;
linN4T2w{2}(normN4T2w>=atThreshold) = atThreshold;

linN4T2w{3} = (linN4T2w{2} -smThreshold) .* thighMask;
linN4T2w{4} = (linN4T2w{3}/ (atThreshold-smThreshold)) .* thighMask;


estimatedFatFractionNii  = templateNii;
estimatedFatFractionNii.img = linN4T2w{end};

save_untouch_nii(estimatedFatFractionNii, sprintf('%s_fatFraction.nii', inN4T2w))


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
