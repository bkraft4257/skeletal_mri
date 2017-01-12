function   mskProjectLabels( inLabel, inStructural)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

try
    
    
    centerSlice = local_project_slice(inLabel );    
    local_project_slice(inStructural, centerSlice );
    
    
catch
    fprintf('Failed to run mskProjectLabels.m\n')    
end


function inSliceToProject = local_project_slice(inFileName, inSliceToProject)

inNii      = load_untouch_nii(inFileName);
inImage    = inNii.img;
nSlices    = size(inImage,3);

if nargin < 2 || isempty(inSliceToProject)
    inSliceToProject =  find( sum(sum(inImage,1), 2) > 0);
end

outNii     = inNii;
outNii.img = repmat(inNii.img(:,:,inSliceToProject),  1, 1, nSlices);

save_untouch_nii(outNii, ['project.' inFileName])
