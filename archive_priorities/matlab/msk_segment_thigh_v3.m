function msk_segment_thigh_v3( inDir, outDir, inMuscleSmoothingFactor, inDebugFlag)
%% Initialization

if nargin<1 || isempty(inDir) % || isempty(inDir =='')
    inDir=pwd;
end

if nargin<2 || isempty(inMuscleSmoothingFactor) % || isempty(inMuscleSmoothingFactor == '')
   outDir=fullfile(inDir,'../03-segment');
end

if nargin<3 || isempty(inMuscleSmoothingFactor) % || isempty(inMuscleSmoothingFactor == '')
    inMuscleSmoothingFactor = 3;
end

if nargin<4 || isempty(inDebugFlag) % || isempty(inDebugFlag == '')
    inDebugFlag = false;
end

debugFlag = inDebugFlag;

inMarrowThreshold = 0.1;

inT2w       = 't1w_36ms_n4';

if( ~(exist(outDir,'dir') == 7) )
   system(sprintf('mkdir -p %s',outDir)); 
end


%% Read in raw image T2w image and normalize
%


n4T2wFileName  = fullfile(inDir,sprintf('%s.nii',inT2w));
n4T2wNii       = load_untouch_nii(n4T2wFileName);

system(sprintf('cp -f %s %s',n4T2wFileName, fullfile(outDir,sprintf('%s.nii',inT2w))));

n4T2w       = double(n4T2wNii.img);
normN4T2w   = n4T2w/max(n4T2w(:));

templateNii = n4T2wNii;



[~, ~, nSlices ]= size(n4T2w);

thighFileName = fullfile(inDir,sprintf('%s_thigh.nii',inT2w));
thighNii      = load_untouch_nii(thighFileName);
thigh{1}      = double(thighNii.img);

atLccEstimateFileName = fullfile(inDir,sprintf('%s_atLccEstimate.nii',inT2w));
atLccEstimateNii      = load_untouch_nii(atLccEstimateFileName);
atLcc{1}      = double(atLccEstimateNii.img);

smEstimateFileName = fullfile(inDir,sprintf('%s_smEstimate.nii',inT2w));
smEstimateNii      = load_untouch_nii(smEstimateFileName);
smEstimate{1}      = double(smEstimateNii.img);


%% Segment bone - cortex and marrow
%

clear bone lowSignal

boneThreshold = 0.10; % (noiseStats(1) + 30*noiseStats(2));  

bone{1} = (normN4T2w < boneThreshold);
bone{2} = imerode(thigh{end},strel('disk',20)) .* bone{1};

bone{3} = local_largest_connected_component(bone{2});

bone{4} = 0 * bone{3};

boneCentroid=zeros(nSlices,2);


for ii=1:nSlices
  
    I  = im2double(bone{end-1}(:,:,ii));
    
    iiRegionProps = regionprops(I, {'BoundingBox', 'ConvexImage','Centroid'});

    bone{end}(iiRegionProps.BoundingBox(2)-0.5 + ...
             (1:iiRegionProps.BoundingBox(4)), ...
              iiRegionProps.BoundingBox(1)-0.5 + ...
             (1:iiRegionProps.BoundingBox(3)), ii) = double(iiRegionProps.ConvexImage);
    
    boneCentroid(ii,:)=iiRegionProps.Centroid;
end


local_check_masks(bone, normN4T2w, 'Bone', debugFlag )

%%  Segment Marrow
%

clear marrow;
marrow{1} = bone{end};
marrow{2} = marrow{1} .* (normN4T2w > inMarrowThreshold);
marrow{3} = imopen(marrow{2}, strel('disk', 2));
marrow{4} = local_largest_connected_component(marrow{3});


[marrow{5}, marrow{6} ] =  local_activeContour3D(marrow{4}, 5, 50);

local_check_masks(marrow, normN4T2w, 'Marrow', debugFlag)

%% Segment Bone Cortex 
%

clear cortex
cortex{1} = bone{end} .* (1-marrow{end});

%% Find larges connected adipose component
%   
%  Conditions that must be met.  Adipose tissue must completely surround
%  the skeletal muscle.  We should impose this condition in the previous
%  step 
%
%

clear sm;
sm{1}                      = smEstimate{1};
[smConvexHull, sm{end+1} ] =  local_activeContour3D(sm{end}, inMuscleSmoothingFactor, 50);


sm{end+1} = sm{end} .* (1-bone{end});
sm{end+1} = imopen(sm{end}, strel('disk',4));  % Remove little pennisulas
sm{end+1} = local_largest_connected_component(sm{end});

local_check_masks(sm, normN4T2w, 'Skeletal Muscle', debugFlag)

smNii     = templateNii;
smNii.img = sm{end};

save_untouch_nii(smNii, fullfile(outDir,sprintf('%s_sm.nii', inT2w)));


% Update Adipose Tissue mask (AT) to remove SM component. 
at{1}     = thigh{end} .* (1-sm{end}) .* (1-bone{end});
atLcc{2}  = atLcc{1} .* (1-bone{end});

atLccNii     = templateNii;
atLccNii.img = atLcc{end};

save_untouch_nii(atLccNii, fullfile(outDir,sprintf('%s_atLcc.nii', inT2w)));

%% Clean up masks
%

%at{end+1}      = at{end}     .* highSnr{end};
%sm{end+1}      = sm{end}     .* highSnr{end};
%marrow{end+1}  = marrow{end} .* highSnr{end};

tissueMask = at{end} + sm{end} + cortex{end} + marrow{end};

if any(tissueMask(:)>1)
   
    templateNii.img = tissueMask;
    
    error('There is a problem with the mask');
   
end



%% Create labels
%

labels     = at{end} + 2*sm{end} + 3*cortex{end} + 4*marrow{end};


labelsNii     = templateNii;
labelsNii.img = labels;

save_untouch_nii(labelsNii, fullfile(outDir,sprintf('%s_autoLabels.nii', inT2w)));
save_untouch_nii(labelsNii, fullfile(outDir,sprintf('%s_labels.nii', inT2w)));


chLabels      = 1 * at{end}      .* (1-smConvexHull) .* (1-bone{end}) + ...
                2 * smConvexHull .* (1-bone{end})                     + ...
                3 * cortex{end}                                       + ...
                4 * marrow{end};

labelsNii.img = chLabels;
save_untouch_nii(labelsNii, fullfile(outDir,sprintf('%s_chAutoLabels.nii', inT2w)));
save_untouch_nii(labelsNii, fullfile(outDir,sprintf('%s_chLabels.nii', inT2w)));

% %%  Clean Direct
% %
% 

fprintf('>>>> Finished segmenting \n\n', inT2w );


%%  local_check_mask
%
%

function local_check_masks(inMasks, refImage, mimpLabel, debugFlag)

if (nargin < 4) || (debugFlag==false)
    return;
end

    [nFreq, nPhase, nSlices ] = size(inMasks{1});

   nMasks      = length(inMasks);
    maxRefImage = max(refImage(:));

    r1Masks     = zeros([nFreq 2*nPhase nSlices nMasks-1]);
    r2Masks     = zeros([nFreq 2*nPhase nSlices nMasks-1]);
    r3Masks     = zeros([nFreq 2*nPhase nSlices nMasks-1]);

    for ii=1:nMasks-1

        r1Masks(:,         1:nPhase,:,ii) = inMasks{ii  }*maxRefImage;
        r1Masks(:,nPhase+(1:nPhase),:,ii) = inMasks{ii+1}*maxRefImage;

        r2Masks(:,         1:nPhase,:,ii) = inMasks{ii  }.*refImage;
        r2Masks(:,nPhase+(1:nPhase),:,ii) = inMasks{ii+1}.*refImage;

        r3Masks(:,         1:nPhase,:,ii) = (1-inMasks{ii}  ).*refImage;
        r3Masks(:,nPhase+(1:nPhase),:,ii) = (1-inMasks{ii+1}).*refImage;
    end

%    mimp([r1Masks;r2Masks;r3Masks], '-t', mimpLabel);
    mimp([r1Masks;r2Masks;r3Masks]);

    return;

%% local_largest_component
%
%

function outMask = local_largest_connected_component(inMask)

            ccInMask = bwconncomp(inMask);
            numPixels = cellfun(@numel,ccInMask.PixelIdxList);
            [biggest,idx] = max(numPixels);

            outMask = zeros(size(inMask));
            outMask(ccInMask.PixelIdxList{idx}) = 1;

%% Active 2D Contours across 3D Volume
%

function [convexHullVolume, contourVolume ] =  local_activeContour3D(inVolume, inSmoothingFactor, inIterations)

initialVolume =  inVolume;
nSlices       = size(inVolume,3);

contourVolume    = zeros(size(inVolume));
convexHullVolume = zeros(size(inVolume));

for ii=1:nSlices
    
    I  = initialVolume(:,:,ii);
    
    iiRegionProps = regionprops(I, {'BoundingBox', 'ConvexImage'});
    
    iiConvexHullImage    = double(iiRegionProps.ConvexImage);
        
    
    convexHullVolume(iiRegionProps.BoundingBox(2)-0.5 + (1:iiRegionProps.BoundingBox(4)), ...
        iiRegionProps.BoundingBox(1)-0.5 + (1:iiRegionProps.BoundingBox(3)), ii) = iiConvexHullImage;
    
    iiInitialContour = imdilate(convexHullVolume(:,:,ii), strel('disk',10));
    
  
    
   iiActiveContour = activecontour(I, iiInitialContour, ...
        inIterations,'Chan-Vese', ...
        'SmoothFactor', inSmoothingFactor, 'ContractionBias',0.4  );
    
   contourVolume(:,:,ii) = iiActiveContour;
     
end
