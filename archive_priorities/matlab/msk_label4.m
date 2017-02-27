function msk_label4( inT2w )
%% Initialization

if nargin<1
    inT2w='t2w';
end

inForegroundThreshold=0.15;
inMarrowThreshold = 0.1;

inSmoothFactor = 2;
inPrefix    = 'jmri';
prefix      = sprintf('%s_%s', inPrefix, inT2w);

debugFlag = false;

%% Apply Intensity Correction
%

n4FileName = sprintf('%s_n4.nii',prefix);

if(~(exist(n4FileName,'file')==2))
    
    fprintf('Applying N4BiasFieldCorrection to %s.nii \n', inT2w );
    
    cmd=sprintf(['N4BiasFieldCorrection -d 3 -i %s.nii', ...
        ' -o %s -r -s '], inT2w, n4FileName);
   
    system(cmd);
      
else
    
    fprintf('Reading in N4BiasFieldCorrection from %s \n', n4FileName);
    
end

%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s_n4.nii',prefix);
n4T2wNii = load_untouch_nii(n4T2wFileName);

n4T2w       = double(n4T2wNii.img);
normN4T2w   = n4T2w/max(n4T2w(:));

templateNii = n4T2wNii;

[nFreq, nPhase, nSlices ]= size(n4T2w);

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

nBorder=10;
background{2}([1:nBorder (end-nBorder):end],  :, : ) = 1;
background{2}( :, [1:nBorder (end-nBorder):end], : ) = 1;

background{3} = 1-background{2};


local_check_masks(background, normN4T2w, 'background')

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
thighNii.img = thigh{end} .* n4T2w;
save_untouch_nii(thighNii, sprintf('%s_thigh.nii', prefix))

thighMaskNii     = templateNii;
thighMaskNii.img = thigh{end};
save_untouch_nii(thighMaskNii, sprintf('%s_thigh_mask.nii', prefix))

%% Segment bone cortex | bone marrow
%

clear bone lowSignal



boneThreshold = 0.05; % (noiseStats(1) + 30*noiseStats(2));  

bone{1} = (normN4T2w < boneThreshold);
bone{2} = imerode(thigh{end},strel('disk',10)) .* bone{1};

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


local_check_masks(bone, normN4T2w, 'Bone')

%%  Segment Marrow
%

clear marrow;
marrow{1} = bone{end};
marrow{2} = marrow{1} .* (normN4T2w > inMarrowThreshold);
marrow{3} = imopen(marrow{2}, strel('disk', 2));
marrow{4} = local_largest_connected_component(marrow{3});c


[marrow{5}, marrow{6} ] =  local_activeContour3D(marrow{4}, 5, 50);

local_check_masks(marrow, normN4T2w, 'Marrow')

%% Segment Bone Marrow
%

clear cortex
cortex{1} = bone{end} .* (1-marrow{end});

%% Find adipose tissue
%   
%  Conditions that must be met.  Adipose tissue must completely surround
%  the skeletal muscle.  We should impose this condition in the previous
%  step 
%
%

clear at;
at{1}    = normN4T2w .* (1-bone{end});  % Remove bone

atThreshold = multithresh(at{1},2);  % Select threshold
at{2}    = 0*at{1};

% Apply threshold slice by slice
for ii=1:nSlices
    at{2}(:,:,ii) = im2bw(at{1}(:,:,ii),atThreshold(end));
end


%Select and save largest connected component
at{3}    = local_largest_connected_component(at{2});

atNii     = templateNii;
atNii.img = at{3};
save_untouch_nii(atNii, sprintf('%s_atLCC.nii', inT2w))


%% Find Skeletal muscle
%

clear sm;
sm{1}    = at{end};
sm{2}    = at{end};
sm{3}    = at{end};
sm{4}    = imopen(sm{1}, strel('ball',3,3))>.5;  % Threshold to convert to logical

sm{5}    = zeros(size(sm{4}));
sm{6}    = zeros(size(sm{4}));

for ii=1:nSlices

    iiBW1      = logical(sm{4}(:,:,ii));                        % Force mask to be logical
    iiBW2      = double(imfill(iiBW1, floor(boneCentroid), 8)); % Perform imfill starting sm centroid

    sm{5}(:,:,ii) = iiBW2;
    sm{6}(:,:,ii) = imfill(iiBW2,'holes');
end

sm{7} = sm{6} - sm{4};  % Estimsme of Skeletal Muscle
sm{8} = imopen(sm{7}, strel('ball',4,4))>.5;  % Threshold to convert to logical

sm{9} = 0*sm{8};

for ii=1:nSlices
    sm{9}(:,:,ii) = local_largest_connected_component(sm{8}(:,:,ii));
end

sm{10} = sm{9} .* (1-sm{1});

[sm{11}, sm{12} ] =  local_activeContour3D(sm{10}, inSmoothFactor, 50);

sm{13} = sm{12} .* (1-bone{end});

local_check_masks(sm, normN4T2w, 'Skeletal Muscle', debugFlag)


%%  Clean up masks and remove low signal from each tissue type
%

% Update Adipose Tissue mask (AT) to remove SM component. 
at{end+1}     = at{end} .* (1-sm{end});

% Remove bone cortex and marrow from filled skeletal muscle contour image.
sm{end+1}     = sm{end}  .* (1-bone{end});          


tissueMask = at{end} + sm{end} + bone{end} + marrow{end};

% if any(tissueMask(:)>1)
%    
%     templateNii.img = tissueMask;
%     
%     error('There is a problem with the mask');
%    
% end

labels     = at{end} + 2*sm{end} + 3*bone{end} + 4*marrow{end};

labelsNii     = templateNii;
labelsNii.img = labels;
save_untouch_nii(labelsNii, sprintf('%s_labelsAuto.nii', inT2w))
save_untouch_nii(labelsNii, sprintf('%s_labels.nii', inT2w))


% %%  Clean Direct
% %
% 
% system(sprintf('gzip -f %s.nii %s_labelsAuto.nii %s_labels.nii', inT2w, inT2w, inT2w));
% system(sprintf('rm -rf %s*.nii',prefix));



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
    
    contourVolume(:,:,ii) = activecontour(I, iiInitialContour, ...
        inIterations,'Chan-Vese', ...
        'SmoothFactor', inSmoothingFactor, 'ContractionBias',0.4  );
    
end
