function msk_segment( inT2w )
%% Initialization

if nargin<1
    inT2w='t2w';
end

cleanFlag = 'true';

inPrefix    = 'jmri';
prefix      = sprintf('%s_%s', inPrefix, inT2w);

%path('/kitzman/secret2/bkraft/matlab/pathdef.m');
% path(pathdef)

%% Set Snake Defaults
%
% This function SNAKE implements the basic snake segmentation. A snake is an 
% active (moving) contour, in which the points are attracted by edges and
% other boundaries. To keep the contour smooth, an membrame and thin plate
% energy is used as regularization.
%
% [O,J]=Snake2D(I,P,baseOptions)
%  
% inputs,
%   I : An Image of type double preferable ranged [0..1]
%   P : List with coordinates descriping the rough contour N x 2
%   baseOptions : A struct with all snake baseOptions
%   
% outputs,
%   O : List with coordinates of the final contour M x 2
%   J : Binary image with the segmented region
%
% baseOptions (general),
%  Option.Verbose : If true show important images, default false
%  baseOptions.nPoints : Number of contour points, default 100
%  baseOptions.Gamma : Time step, default 1
%  baseOptions.Iterations : Number of iterations, default 100
%
% baseOptions (Image Edge Energy / Image force))
%  baseOptions.Sigma1 : Sigma used to calculate image derivatives, default 10
%  baseOptions.Wline : Attraction to lines, if negative to black lines otherwise white
%                    lines , default 0.04
%  baseOptions.Wedge : Attraction to edges, default 2.0
%  baseOptions.Wterm : Attraction to terminations of lines (end points) and
%                    corners, default 0.01
%  baseOptions.Sigma2 : Sigma used to calculate the gradient of the edge energy
%                    image (which gives the image force), default 20
%
% baseOptions (Gradient Vector Flow)
%  baseOptions.Mu : Trade of between real edge vectors, and noise vectors,
%                default 0.2. (Warning setting this to high >0.5 gives
%                an instable Vector Flow)
%  baseOptions.GIterations : Number of GVF iterations, default 0
%  baseOptions.Sigma3 : Sigma used to calculate the laplacian in GVF, default 1.0
%
% baseOptions (Snake)
%  baseOptions.Alpha : Membrame energy  (first order), default 0.2
%  baseOptions.Beta : Thin plate energy (second order), default 0.2
%  baseOptions.Delta : Baloon force, default 0.1
%  baseOptions.Kappa : Weight of external image force, default 2
%
%
% Literature:
%   - Michael Kass, Andrew Witkin and Demetri TerzoPoulos "Snakes : Active
%       Contour Models", 1987
%   - Jim Ivins amd John Porrill, "Everything you always wanted to know
%       about snakes (but wer afraid to ask)
%   - Chenyang Xu and Jerry L. Prince, "Gradient Vector Flow: A New
%       external force for Snakes
%

baseOptions=struct;
baseOptions.Verbose    = false;
baseOptions.Iterations = 50;

% baseOptions (Image Edge Energy / Image force))

%  baseOptions.Sigma1 : Sigma used to calculate image derivatives, default 10
%  baseOptions.Wline : Attraction to lines, if negative to black lines otherwise white
%                    lines , default 0.04
%  baseOptions.Wedge : Attraction to edges, default 2.0
%  baseOptions.Wterm : Attraction to terminations of lines (end points) and
%                    corners, default 0.01
%  baseOptions.Sigma2 : Sigma used to calculate the gradient of the edge energy
%                    image (which gives the image force), default 20


baseOptions.Sigma1 = 5;
baseOptions.Wline  = 0.04;
baseOptions.Wedge  = 2.00;    %Negative makes snake repel from image
baseOptions.Wterm  = 0.01;

baseOptions.Sigma2 = 10;

% baseOptions (Snake)
% baseOptions.Alpha : Membrane energy  (first order),   default 0.2
% baseOptions.Beta  : Thin plate energy (second order), default 0.2
% baseOptions.Delta : Balloon force,                    default 0.1
% baseOptions.Kappa : Weight of external image force,   default 2.0

baseOptions.Alpha = 0.1;  % Negative
baseOptions.Beta  = 0.1;

baseOptions.Delta = 0.2;  % Smaller number pulls snake in
baseOptions.Kappa = 2.0;

% baseOptions (Gradient Vector Flow)
%  baseOptions.Mu : Trade of between real edge vectors, and noise vectors,
%                default 0.2. (Warning setting this to high >0.5 gives
%                an instable Vector Flow)
%  baseOptions.GIterations : Number of GVF iterations, default 0
%  baseOptions.Sigma3 : Sigma used to calculate the laplacian in GVF, default 1.0

baseOptions.Mu=0.3;
baseOptions.GIterations=600;

%
%
%

%% Perform intensity correction on t2w image

cmd = sprintf('jmri_v2.sh %s %s %s', inT2w, inPrefix, cleanFlag);
system(cmd);


%% Find Background and Foreground from the Intensity Corrected Image
%

t2wFileName  = sprintf('%s_n3.nii', prefix);
t2wNii = load_untouch_nii(t2wFileName);

templateNii = t2wNii;

t2w    = double(t2wNii.img);
[nFreq, nPhase, nSlices ]= size(t2w);

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