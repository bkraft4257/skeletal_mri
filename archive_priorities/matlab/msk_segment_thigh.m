function msk_segment_thigh( inT2w, inMuscleSmoothingFactor, inDebugFlag)
%% Initialization

if nargin<1 || isempty(inT2w) % || isempty(inT2w =='')
    inT2w='t1w_36ms';
end

if nargin<2 || isempty(inMuscleSmoothingFactor) % || isempty(inMuscleSmoothingFactor == '')
    inMuscleSmoothingFactor = 3;
end

if nargin<3 || isempty(inDebugFlag) % || isempty(inDebugFlag == '')
    inDebugFlag = true;
end

debugFlag = inDebugFlag;

inForegroundThreshold=0.15;
inMarrowThreshold = 0.1;

inPrefix    = 'tmp';
prefix      = sprintf('%s_%s', inPrefix, inT2w);

%% Apply Intensity Correction
%

inT2wFileName = sprintf('%s.nii',inT2w);
t2wNii        = load_untouch_nii(inT2wFileName);

if( t2wNii.hdr.dime.dim(4) ==1)
  dimT2w = 2;
else
  dimT2w = 3;
end


% nSlices = t2wNi.hdr.dim;

n4T2wFileName = sprintf('%s_n4.nii',inT2w);


if(~(exist(n4T2wFileName,'file')==2))
    
    fprintf('\n >>>> Applying N4BiasFieldCorrection to %s \n', inT2w );
    
    cmd=sprintf(['N4BiasFieldCorrection -d %d -i %s', ...
		 ' -o %s -r -s '], dimT2w, inT2wFileName, n4T2wFileName);
   
    fprintf('\n\t %s \n', cmd)

    system(cmd);
      
else
    
    fprintf('\n>>>> Reading in N4BiasFieldCorrection from %s \n', n4T2wFileName);
    
end



%% Read in raw image T2w image and normalize
%

n4T2wFileName  = sprintf('%s_n4.nii',inT2w);
n4T2wNii = load_untouch_nii(n4T2wFileName);

n4T2w       = double(n4T2wNii.img);
normN4T2w   = n4T2w/max(n4T2w(:));

templateNii = n4T2wNii;



[~, ~, nSlices ]= size(n4T2w);

%% Segment out foreground from raw Image
%
clear foreground;

foreground{1} = normN4T2w>inForegroundThreshold;
foreground{2} = foreground{1};
foreground{3} = 1-imfill(foreground{2},8);
foreground{4} = foreground{2} + foreground{3};

local_check_masks(foreground, normN4T2w, 'background', debugFlag)

%% Segment out background
%

clear background;

background{1} = foreground{end};
background{2} = background{1};

nBorder=4;
background{2}([1:nBorder (end-nBorder):end],  :, : ) = 1;
background{2}( :, [1:nBorder (end-nBorder):end], : ) = 1;

background{3} = 1-background{2};


local_check_masks(background, normN4T2w, 'background', debugFlag )

%%  Create Noise Mask
% 

noise{1} = background{end};
noise{2} = imerode(noise{1},strel('disk',15));

local_check_masks(noise, normN4T2w, 'background')


noiseNii     = templateNii;
noiseNii.img = noise{end};
save_untouch_nii(noiseNii, sprintf('%s_noise.nii', prefix))

tmp          = normN4T2w .* noise{end};
meanNoise    = mean(tmp(:));
stdNoise     = std(tmp(:));

%% Segment out thigh
%

clear thigh;
thigh{1}      = normN4T2w;
thigh{2}      = thigh{1};

thigh{2}([1:nBorder (end-nBorder):end],  :, : ) = 1;
thigh{2}( :, [1:nBorder (end-nBorder):end], : ) = 1;

thigh{3}      =  imclearborder(thigh{2}, 8);

thighThreshold = meanNoise + 9*stdNoise;
thigh{4}      = thigh{3}>thighThreshold;
thigh{5}      = local_largest_connected_component(thigh{4});

[thigh{6}, thigh{7} ] =  local_activeContour3D(thigh{5}, 3, 50);


local_check_masks(thigh, normN4T2w, 'thigh', debugFlag)

thighNii     = templateNii;
thighNii.img = thigh{end} .* normN4T2w;
save_untouch_nii(thighNii, sprintf('%s_normN4.nii', inT2w))

thighMaskNii     = templateNii;
thighMaskNii.img = thigh{end};
save_untouch_nii(thighMaskNii, sprintf('%s_thigh_mask.nii', prefix))



%% Segment bone - cortex and marrow
%

clear bone lowSignal



boneThreshold = 0.05; % (noiseStats(1) + 30*noiseStats(2));  

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

clear atLcc;
atLcc{1}    = normN4T2w .* thigh{end} .* (1-bone{end});  % Remove bone

% Find
atLccThreshold = 0.75*graythresh(atLcc{1});  % Select threshold
atLcc{2}    = 0*atLcc{1};

% Apply threshold slice by slice
for ii=1:nSlices
    atLcc{2}(:,:,ii) = im2bw(atLcc{1}(:,:,ii),atLccThreshold(end));
end

%Select and save largest connected component
atLcc{3}    = local_largest_connected_component(atLcc{2});


atLccNii     = templateNii;
atLccNii.img = atLcc{3};
save_untouch_nii(atLccNii, sprintf('%s_n4_atLCC.nii', inT2w, debugFlag))


%% Find Skeletal muscle boundary with active contours
%

thighBoundary = thigh{end} - imerode(thigh{end},strel('disk',2));


clear sm;
sm{1}    = atLcc{end};
sm{2}    = imopen(sm{1}, strel('ball',10,3));
sm{3}    = (sm{2}+thighBoundary)>0.5;
sm{4}    = local_largest_connected_component(sm{3});

sm{5}    = zeros(size(sm{4}));
sm{6}    = zeros(size(sm{4}));

for ii=1:nSlices

    iiBW1      = logical(sm{4}(:,:,ii));                        % Force mask to be logical
    iiBW2      = double(imfill(iiBW1, floor(boneCentroid), 8)); % Perform imfill starting sm centroid

    sm{5}(:,:,ii) = iiBW2;
    sm{6}(:,:,ii) = imfill(iiBW2,'holes');
end


sm{7} = sm{6} - sm{4};  % Estimate of Skeletal Muscle
sm{8} = imopen(sm{7}, strel('ball',4,4))>.5;  % Threshold to convert to logical
sm{9} =  local_largest_connected_component(sm{8});

%% Find the vessels in fat
%
clear atVessels;
atVessels{1} = imdilate(thigh{end},strel('disk',3)) - sm{6};
atVessels{2} = local_largest_connected_component(atVessels{1});
atVessels{3} = atVessels{1}-atVessels{2};


%% Clean up Skeletal Muscle
%

sm{end+1}   = sm{end} .* (1-atVessels{end});  % Remove vessels
sm{end+1}  = zeros(size(sm{end}));

% Find largest connected component on each slice
for ii=1:nSlices
    sm{end}(:,:,ii) = local_largest_connected_component(sm{end-1}(:,:,ii));
end

[smConvexHull, sm{end+1} ] =  local_activeContour3D(sm{end}, inMuscleSmoothingFactor, 50);


sm{end+1} = sm{end} .* (1-bone{end});
sm{end+1} = imopen(sm{end}, strel(disk,20));

%% Select subcutaneous fat
% Update Adipose Tissue mask (AT) to remove SM component. 
at{1}     = atLcc{end} .* (1-sm{end});
at{2}     = at{1} .* (normN4T2w>=(meanNoise + 3*stdNoise));

% attNormN4T2w = normN4T2w(logical(at{1}));

% atMax        = max(attNormN4T2w(:));
% 
% sm{14} = sm{13} .* (normN4T2w<=atMax);
% sm{15} = sm{14} .* (normN4T2w>=(meanNoise + 3* stdNoise));

% Remove bone cortex and marrow from filled skeletal muscle contour image.
sm{end+1}     = imdilate(sm{end},strel('disk',2)) .* (1-at{end});
sm{end+1}     = sm{end}  .* (1-bone{end}); 
sm{end+1}     = local_largest_connected_component(sm{end});


local_check_masks(sm, normN4T2w, 'Skeletal Muscle', debugFlag)

%% Low threshold mask
%

%clear highSNR;
%highSnr{1} = (normN4T2w .* thigh{end}) >= 0.15;
       
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

%% Smooth tissue Mask
%  

tissueMask2 = imopen(tissueMask, strel('disk',20));



%% Create labels
%

labels     = at{end} + 2*sm{end} + 3*cortex{end} + 4*marrow{end};


labelsNii     = templateNii;
labelsNii.img = labels;

save_untouch_nii(labelsNii, sprintf('%s_n4_autoLabels.nii', inT2w))
save_untouch_nii(labelsNii, sprintf('%s_n4_labels.nii', inT2w))


chLabels      = 1 * at{end}      .* (1-smConvexHull) .* (1-bone{end}) + ...
                2 * smConvexHull .* (1-bone{end})                     + ...
                3 * cortex{end}                                       + ...
                4 * marrow{end};

labelsNii.img = chLabels;
save_untouch_nii(labelsNii, sprintf('%s_n4_chAutoLabels.nii', inT2w))
save_untouch_nii(labelsNii, sprintf('%s_n4_chLabels.nii', inT2w))

% %%  Clean Direct
% %
% 
% system(sprintf('gzip -f %s.nii %s_labelsAuto.nii %s_labels.nii', inT2w, inT2w, inT2w));
system(sprintf('rm -rf %s*.nii',prefix));

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
    
   contourVolume(:,:,ii) = imclose(iiActiveContour, strel('disk',2));
     
end
