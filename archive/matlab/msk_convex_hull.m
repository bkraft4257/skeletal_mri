function msk_convex_hull( inVolumeFileName, inParameters, outVolume)

%% Initialization

if nargin < 2 || isempty(inParameters)
     inParameters = [3 5]; % smooting factor iterations]
end

if nargin < 3 || isempty(outVolume)
      outVolume = sprintf('convexHull.%s', inVolumeFileName);
end

if (exist(inVolumeFileName, 'file') ==2) && strcmp(inVolumeFileName(end-3:end), '.nii')
    
         inNii = load_untouch_nii(inVolumeFileName);

elseif (exist(inVolumeFileName, 'file') ==2) && strcmp(inVolumeFileName(end-6:end), '.nii.gz')

        system(sprintf('gunzip %s',inVolumeFileName));

        inNii = load_untouch_nii(inVolumeFileName(1:end-3));

        system(sprintf('gzip %s',inVolumeFileName(1:end-3)));
else

    error('No File Found');
    
end

inVolume = inNii.img;

%% Convex Hull
%

[convexHullVolume, activeContourVolume ] =  local_activeContour3D(inVolume, inParameters(1), inParameters(2));


outNii     = inNii;
outNii.img = convexHullVolume;

 
save_untouch_nii(outNii, 'convex_hull.nii'  ) 
system(sprintf('gzip -f convex_hull.nii; mv convex_hull.nii.gz ch.%s', outVolume))


outNii     = inNii;
outNii.img = activeContourVolume;

save_untouch_nii(outNii, 'active_contour.nii') 

system(sprintf('gzip -f active_contour.nii; mv active_contour.nii.gz ac.%s', outVolume))



%% Active 2D Contours across 3D Volume
%

function [convexHullVolume, contourVolume ] =  local_activeContour3D(inVolume, inSmoothingFactor, inIterations)

initialVolume =  inVolume;
nSlices       = size(inVolume,3);
inSmoothingFactor

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
