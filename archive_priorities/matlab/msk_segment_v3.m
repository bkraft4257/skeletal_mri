function msk_segment_v3( inT2w )
%% Initialization

if nargin<1
    inT2w='t2w';
end

cleanFlag = 'true';

inSmoothFactor = 3;
inPrefix    = 'jmri';
prefix      = sprintf('%s_%s', inPrefix, inT2w);

debugFlag = false;

%% Read in raw image and normalize
%
rawT2wFileName  = 't2w.nii';

if exist(rawT2wFileName, 'file')==2

    rawT2wNii = load_untouch_nii(rawT2wFileName);

elseif exist(strcat(rawT2wFileName,'.gz'), 'file')==2

        system(sprintf('%s.gz',rawT2wFileName));
        rawT2wNii = load_untouch_nii(rawT2wFileName);
else

    error('No File Found');
    
end

templateNii = rawT2wNii;

rawT2w    = double(rawT2wNii.img);
normRawT2w    = rawT2w/max(rawT2w(:));

[nFreq, nPhase, nSlices ]= size(rawT2w);


%% Find Background and Foreground from raw Image
%
clear foreground;

foreground{1} = normRawT2w>0.05;
foreground{2} = foreground{1};
foreground{3} = 1-imfill(foreground{2},8);
foreground{4} = foreground{2} + foreground{3};

local_check_masks(foreground, normRawT2w, 'background')

%% Segment thigh from raw Image
%

clear background;

background{1} = foreground{end};

background{2} = background{1};
nBorder=10;
background{2}([1:nBorder (end-nBorder):end],  :, : ) = 1;
background{2}( :, [1:nBorder (end-nBorder):end], : ) = 1;

background{3} = 1-background{2};


local_check_masks(background, normRawT2w, 'background')

%%  Create Noise Mask
% 

noise{1} = background{end};
noise{2} = imerode(noise{1},strel('disk',15));

local_check_masks(noise, normRawT2w, 'background')


noiseNii     = templateNii;
noiseNii.img = noise{end};
save_untouch_nii(noiseNii, sprintf('%s_noise.nii', prefix))


%% Segment out thigh
%

clear thigh;
thigh{1}      = foreground{end};
thigh{2}      = thigh{1};

thigh{2}([1:nBorder (end-nBorder):end],  :, : ) = 1;
thigh{2}( :, [1:nBorder (end-nBorder):end], : ) = 1;

thigh{3}      =  imclearborder(thigh{2}, 8);

local_check_masks(thigh, rawT2w, 'thigh')

thighNii     = templateNii;
thighNii.img = thigh{end} .* rawT2w;
save_untouch_nii(thighNii, sprintf('%s_thigh.nii', prefix))

thighMaskNii     = templateNii;
thighMaskNii.img = thigh{end};
save_untouch_nii(thighMaskNii, sprintf('%s_thigh_mask.nii', prefix))

%% Apply Intensity Correction
%

n4FileName = sprintf('%s_n4.nii',prefix);

if(~(exist(n4FileName,'file')==2))
    
    fprintf('Applying N4BiasFieldCorrection to %s_thigh.nii \n', prefix );

    
    cmd=sprintf(['N4BiasFieldCorrection -d 3 -i %s_thigh.nii', ...
        ' -o %s -r -s '], prefix, n4FileName);

    system(cmd);
    
else
    
    fprintf('Reading in N4BiasFieldCorrection from %s \n', n4FileName);
    
end




%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s_n4.nii',prefix);
n4T2wNii = load_untouch_nii(n4T2wFileName);

n4T2w    = double(n4T2wNii.img);
normN4T2w    = n4T2w/max(n4T2w(:));

noiseT2w   =   normRawT2w .* noise{2}; 
noiseStats = [ mean(noiseT2w(:)) std(noiseT2w(:)) ];
noiseFloor = noiseStats(1) + 9*noiseStats(2);

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
marrow{2} = marrow{1} .* (normN4T2w > 0.4);
marrow{3} = local_largest_connected_component(marrow{2});

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
at{1}    = normN4T2w .* (1-bone{end});
at{2}    = at{1}>0.5;
at{3}    = imopen(at{2},strel('disk',1));
at{3}    = local_largest_connected_component(at{3});


at{4}    = zeros(size(at{3}));
at{5}    = zeros(size(at{4}));

for ii=1:nSlices

    iiBW1      = logical(at{3}(:,:,ii));                        % Force mask to be logical
    iiBW2      = double(imfill(iiBW1, floor(boneCentroid), 8)); % Perform imfill starting at centroid

    at{4}(:,:,ii) = iiBW2;
    at{5}(:,:,ii) = imfill(iiBW2,'holes');
end

at{6} = at{5} - at{4};  % Holes in Adipose tissue
at{7} = at{3} + at{6};  % Fill in holes in adipose tissue

at{8}  = imclose(at{7}, strel('disk',2));  % Remove small gaps in adipose tissue
at{9}  = imfill(at{8},8,'holes');

at{10} = at{1}>0.1;                        % Select lower threshold
at{11} = (at{10}-at{9})==1;
at{12} = at{8}+at{11};

local_check_masks(at, normN4T2w, 'Adipose Tissue',true)

%% Find Skeletal muscle
%
clear sm;

sm{1}    = imfill(at{end},8,'holes')-at{end};

sm{2}    = 0 * sm{1};
sm{3}    = 0 * sm{2};

for ii=1:nSlices
  
    I  = sm{1}(:,:,ii);
    
    iiRegionProps = regionprops(I, {'BoundingBox', 'ConvexImage'});
    
    iiConvexImage    = double(iiRegionProps.ConvexImage);
   
    
    sm{2}(iiRegionProps.BoundingBox(2)-0.5 + (1:iiRegionProps.BoundingBox(4)), ...
        iiRegionProps.BoundingBox(1)-0.5 + (1:iiRegionProps.BoundingBox(3)), ii) = iiConvexImage;
     
    iiInitialContour = imdilate(sm{2}(:,:,ii), strel('disk',10));
     
    sm{3}(:,:,ii) = activecontour(I, iiInitialContour, ...
                                  50,'Chan-Vese', ...
                                  'SmoothFactor', inSmoothFactor, 'ContractionBias',0.4  );
    
end

sm{4} = imopen(sm{3}, strel('disk',1));
sm{5} = sm{4} .* sm{2};

local_check_masks(sm, normN4T2w, 'Skeletal Muscle')


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


% %% Create Final Labels from convex hull
% %
% % 
%  smConvexHull{end+1}  = smConvexHull{end} .* invBone;
%  smConvexHull{end+1}  = local_largest_connected_component(smConvexHull{end});
% % 
% % at{end+1}     = at{end}  .* (1-smConvexHull{end});
% % at{end+1}     = local_largest_connected_component(at{end});
% % 
% % cortex{end+1} = cortex{end} .* (1-smConvexHull{end});
% %  
% % 
% % chTissueMask = at{end} + smConvexHull{end} + cortex{end} + marrow{end};
% % 
% % % if any(chTissueMask(:)>1)
% % %    
% % %     templateNii.img = chTissueMask;
% % %     
% % %     error('There is a problem with the mask');
% % %    
% % % end
% % 
% % chLabels     = at{end} + 2*sm{end} + 3*cortex{end} + 4*marrow{end};
% % 
% % labelsNii     = t2wNii;
% % labelsNii.img = chLabels;
% % save_untouch_nii(labelsNii, sprintf('%s_convexHullLabelsAuto.nii', inT2w))
% % save_untouch_nii(labelsNii, sprintf('%s_convexHullLabels.nii', inT2w))
% 
% convexHullNii     = t2wNii;
% convexHullNii.img = smConvexHull{end};
% save_untouch_nii(convexHullNii, sprintf('%s_smConvexHull.nii', inT2w))
% 
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

            