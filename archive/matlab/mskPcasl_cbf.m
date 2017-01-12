function [inNii, outNii, nullNii] = mskPcasl_cbf( inBloodNii, inM0,  inFudgeFactor  )

%
%
%

if nargin < 1 || isempty(inBloodNii)
    inBloodNii = 'blood.nii';
end

if nargin < 2 || isempty(inM0)
    inM0 = 295;
end

if nargin < 3 || isempty(inFudgeFactor)
    inFudgeFactor = 1;
end

epiAcqTime = 0.05;   % Time to acquire each slice [seconds]
alpha      = 0.94;   % Tagging efficiency
lamda      = 0.9;    % [ml/g]
tau        = 2.000;  % tag duration         [seconds]
delta0     = 1.500;  % post-labeling delay  [seconds]
T1b        = 1.600;  % T1 of blood at 3T    [seconds]


%
% Check that both files exist
%

if ~isempty(inBloodNii)
    
    if ~exist(inBloodNii, 'file')
        error('Online Siemens image data file does not exist. %s', inBloodNii)
    end
    
end

bloodNii   = load_untouch_nii(inBloodNii);

nSlices    = size(bloodNii.img,3)
nVolumes   = size(bloodNii.img,4)

Q          = tau + delta0;
delta      = delta0 + ((nSlices-1):-1:0)*epiAcqTime;

m0Scale0  = (2*alpha*inM0*T1b)/ (6000*lamda)           % [ (ml/g)/s = (ml/(100g)/minute) ]
m0Scale1  = exp(-delta/T1b) - exp(-(tau+delta)/T1b)

m0Scale   = inFudgeFactor./(m0Scale0 * m0Scale1)


%
% CBF 
%

blood  = double(bloodNii.img);
cbf    = zeros( size(blood) );

for iiSlices=1:nSlices
    
        cbf(:,:,iiSlices,:) = m0Scale(iiSlices)*blood(:,:,iiSlices,:);  % [ (ml/g)/s ]
        
end

% cbf = 600*cbf;  

%
%
%

cbfNii     = bloodNii;
cbfNii.img = cbf;

save_untouch_nii(cbfNii, 'cbf.nii');

%
%
%

mskPcasl_slice_mean( 'cbf.nii' )

return

