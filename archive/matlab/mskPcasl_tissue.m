function [inNii, outNii, nullNii] = mskPcasl_tissue( inTissueNii, inM0,  inFudgeFactor  )

%
%
%

if nargin < 1 || isempty(inTissueNii)
    inTissueNii = 'tissue.nii';
end

if nargin < 2 || isempty(inM0)
    inM0 = 295;
end

if nargin < 3 || isempty(inFudgeFactor)
    inFudgeFactor = 1;
end

%
% Check that both files exist
%

if ~isempty(inTissueNii)
    
    if ~exist(inTissueNii, 'file')
        error('Online Siemens image data file does not exist. %s', inTissueNii)
    end
    
end

tissueNii   = load_untouch_nii(inTissueNii);

nSlices    = size(tissueNii.img,3)
nVolumes   = size(tissueNii.img,4)

m0Scale   = inFudgeFactor./inM0


normTissueNii     = tissueNii;
normTissueNii.img = m0Scale * normTissueNii.img;

save_untouch_nii(normTissueNii, 'norm_m0.tissue.nii');


return

