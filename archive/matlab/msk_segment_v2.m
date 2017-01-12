function msk_segment_v2( inT2w )
%% Initialization

if nargin<1
    inT2w='t2w';
end

cleanFlag = 'true';

inPrefix    = 'jmri';
prefix      = sprintf('%s_%s', inPrefix, inT2w);



%% Find Background and Foreground from the Intensity Corrected Image
%

rawT2wFileName  = 't2w.nii';
rawT2wNii = load_untouch_nii(rawT2wFileName);

templateNii = rawT2wNii;

rawT2w    = double(rawT2wNii.img);
rawT2w    = rawT2w/max(rawT2w(:));

[nFreq, nPhase, nSlices ]= size(rawT2w);

clear background;

background{1} = rawT2w;
background{2} = 1-(background{1} > 0.1);

local_check_masks(background, rawT2w, 'background')

background = local_largest_connected_component(t2w<0.05);
foreground = 1-background;

lowSignal  = foreground .* (t2w<0.05);

lowSignalNii     = templateNii;
lowSignalNii.img = lowSignal;
save_untouch_nii(lowSignalNii, sprintf('%s_lowSignal_mask.nii', prefix))


%% Segment bone cortex
%


t2wSmoothFileName  = sprintf('%s_smooth.nii', prefix);
t2wSmoothNii = load_untouch_nii(t2wSmoothFileName);

t2wSmooth    = double(t2wSmoothNii.img);
clear cortex;

cortex{1} = foreground .* (t2wSmooth<0.08);
cortex{2} = local_largest_connected_component(cortex{1});
cortex{3} = imopen(cortex{2},strel('disk',1));
cortex{4} = zeros(size(cortex{3}));

for ii=1:nSlices
    cortex{4}(:,:,ii)  = bwareaopen(cortex{3}(:,:,ii), 10);
end

cortex{end+1} = imclose(cortex{end}, strel('disk',3));
% cortex{end+1} = local_largest_connected_component(cortex{end});


%%  Segment Marrow
%

clear marrow;
marrow{1} = imfill(cortex{end}, 8,'holes');

bone      = marrow{1};
invBone   = foreground .* (1-bone);

marrow{2} = marrow{1} - cortex{end};


%% Find adipose tissue
%   
%  Conditions that must be met.  Adipose tissue must completely surround
%  the skeletal muscle.  We should impose this condition in the previous
%  step 
%
%

otsuNii  = load_untouch_nii(sprintf('%s_otsu2.nii',prefix));
otsu     = double(otsuNii.img);

clear at;
at{1}    = t2wSmooth>0.25;
at{2}    = at{1} .* invBone;
at{3}    = local_largest_connected_component(at{2});
at{4}    = imclose(at{2}, strel('disk', 1));



%% Find skeletal muscle

clear sm;

sm{1} = imfill(at{end}, 8, 'holes');
sm{2} = sm{1}-at{end};
sm{3} = bwareaopen(sm{2}, 40,8);
sm{4} = sm{3} .* invBone;
sm{5} = imfill(sm{4}, 8, 'holes') .* invBone;
sm{6} = imclose(sm{5}, strel('disk', 2));


%% Segment skeletal muscle from adipose tissue
%
%

Options = baseOptions;

smContour       = zeros(size(sm{end}));
smConvexHull{1} = zeros(size(sm{end}));

Options = baseOptions;

for ii=1:nSlices
    
    fprintf('Snakes Slice %d \n', ii);
    
    % Extract Slice
    
    I  = im2double(sm{end}(:,:,ii));
    
    % Dilate image to obtain enlarged convex hull.
    
    I2 = imdilate(I,strel('disk',1));
    
    iiRegionProps = regionprops(I2, {'BoundingBox', 'ConvexImage', 'ConvexHull'});

    smConvexHull{1}(iiRegionProps.BoundingBox(2)-0.5 + (1:iiRegionProps.BoundingBox(4)), ...
        iiRegionProps.BoundingBox(1)-0.5 + (1:iiRegionProps.BoundingBox(3)), ii) = double(iiRegionProps.ConvexImage);
    
    % Convex Hull for intial start
    
    x = iiRegionProps.ConvexHull(:,2);
    y = iiRegionProps.ConvexHull(:,1);
    
    P  = [ x(:) y(:) ];
    
    [O,J] = Snake2D(I,P,Options);
    
    smContour(:,:,ii)    = J;

    
end

%% Create Final Labels from Snake
%

% Remove bone cortex and marrow from filled skeletal muscle contour image.
sm{end+1}     = (smContour | sm{end})  .* invBone;          

% Although probably not necessary, select the largest component
sm{end+1}     = local_largest_connected_component(sm{end});

% Update Adipose Tissue mask (AT) to remove SM component. 
at{end+1}     = at{end}                .* (1-sm{end}) .* invBone;
at{end+1}     = local_largest_connected_component(at{end});



tissueMask = at{end} + sm{end} + cortex{end} + marrow{end};

% if any(tissueMask(:)>1)
%    
%     templateNii.img = tissueMask;
%     
%     error('There is a problem with the mask');
%    
% end

labels     = at{end} + 2*sm{end} + 3*cortex{end} + 4*marrow{end};

labelsNii     = t2wNii;
labelsNii.img = labels;
save_untouch_nii(labelsNii, sprintf('%s_labelsAuto.nii', inT2w))
save_untouch_nii(labelsNii, sprintf('%s_labels.nii', inT2w))


%% Create Final Labels from convex hull
%
% 
 smConvexHull{end+1}  = smConvexHull{end} .* invBone;
 smConvexHull{end+1}  = local_largest_connected_component(smConvexHull{end});
% 
% at{end+1}     = at{end}  .* (1-smConvexHull{end});
% at{end+1}     = local_largest_connected_component(at{end});
% 
% cortex{end+1} = cortex{end} .* (1-smConvexHull{end});
%  
% 
% chTissueMask = at{end} + smConvexHull{end} + cortex{end} + marrow{end};
% 
% % if any(chTissueMask(:)>1)
% %    
% %     templateNii.img = chTissueMask;
% %     
% %     error('There is a problem with the mask');
% %    
% % end
% 
% chLabels     = at{end} + 2*sm{end} + 3*cortex{end} + 4*marrow{end};
% 
% labelsNii     = t2wNii;
% labelsNii.img = chLabels;
% save_untouch_nii(labelsNii, sprintf('%s_convexHullLabelsAuto.nii', inT2w))
% save_untouch_nii(labelsNii, sprintf('%s_convexHullLabels.nii', inT2w))

convexHullNii     = t2wNii;
convexHullNii.img = smConvexHull{end};
save_untouch_nii(convexHullNii, sprintf('%s_smConvexHull.nii', inT2w))

%%  Clean Direct
%

system(sprintf('gzip -f %s.nii %s_labelsAuto.nii %s_labels.nii', inT2w, inT2w, inT2w));
system(sprintf('rm -rf %s*.nii',prefix));

%%  local_check_mask
%
%

function local_check_masks(inMasks, refImage, mimpLabel)

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



function outMask = local_largest_connected_component(inMask)

            ccInMask = bwconncomp(inMask);
            numPixels = cellfun(@numel,ccInMask.PixelIdxList);
            [biggest,idx] = max(numPixels);

            outMask = zeros(size(inMask));
            outMask(ccInMask.PixelIdxList{idx}) = 1;

            
function volumeContour = local_snakes(inVolume, inOptions)   

nSlices=size(inVolume,3);
volumeContour = zeros(size(volumeContour));


for ii=1:nSlices
    
    fprintf('Snakes Slice %d \n', ii);
    
    % Extract Slice
    
    I  = im2double(inVolume(:,:,ii));
    
    % Dilate image to obtain enlarged convex hull.
    
    I2 = imdilate(I,strel('disk',1));
    
    iiRegionProps = regionprops(I2, {'BoundingBox', 'ConvexImage', 'ConvexHull'});

    
    volumeContour(iiRegionProps.BoundingBox(2)-0.5 + (1:iiRegionProps.BoundingBox(4)), ...
        iiRegionProps.BoundingBox(1)-0.5 + (1:iiRegionProps.BoundingBox(3)), ii) = double(iiRegionProps.ConvexImage);
    
    % Convex Hull for intial start
    
    x = iiRegionProps.ConvexHull(:,2);
    y = iiRegionProps.ConvexHull(:,1);
    
    P  = [ x(:) y(:) ];
    
    [O,J] = Snake2D(I,P,inOptions);
    
    volumeContour(:,:,ii)    = J;

    
end