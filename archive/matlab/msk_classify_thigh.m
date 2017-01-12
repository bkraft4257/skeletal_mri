function msk_classify_thigh( inN4T2w, inLabels, inAtLcc, inSegments )

%% Initialization

if nargin<1  || isempty(inN4T2w)
    inN4T2w='t2w_n4';
end

if nargin<2 || isempty(inLabels)
    inLabels='t2w_n4_labels';
end

if nargin<3  || isempty(inAtLcc)
    inAtLcc='t2w_n4_atLCC';
end

if nargin<4 || isempty(inSegments)
    inSegments        = 1;
end



%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s.nii', inN4T2w);
n4T2wNii       = local_load_nii(n4T2wFileName);

templateNii = n4T2wNii;

n4T2w    = double(n4T2wNii.img);
normN4T2w    = n4T2w/max(n4T2w(:));



%%  Read in Label Images
%

labelFileName  = sprintf('%s.nii', inLabels);
labelNii       = local_load_nii(labelFileName);

%%  Read in AT Largest Connected Component
%

atLccFileName  = sprintf('%s.nii', inAtLcc);
atLccNii       = local_load_nii(atLccFileName);


%% AT Stats
%

labels    = double(labelNii.img);
atLccMask = logical(atLccNii.img);

atMask    = (labels==1);
smMask    = (labels==2);


atNormN4T2w   = normN4T2w .* atMask;
smNormN4T2w   = normN4T2w .* smMask;
atSmNormN4T2w = atNormN4T2w + smNormN4T2w;



%%  Classify Muscle
%


smSegmentNii     = templateNii;

fprintf('\n');

ls


for iiSegments=inSegments
    
    
    atSmThresholds   = multithresh(atSmNormN4T2w(:), iiSegments);

    fprintf('%d ', iiSegments, atSmThresholds)
    fprintf('\n');
    
    smSegmentNii.img = imquantize(smNormN4T2w,atSmThresholds) .* smMask;

    save_untouch_nii(smSegmentNii, sprintf('%s_smSegment_%02d.nii',inN4T2w, iiSegments));

end

%% Normalize Muscle by AT and SM mask
%

maxAtLccNormN4T2w = max(atSmNormN4T2w(logical(atLccMask(:))));

normAtSmNii      = templateNii;
normAtSmNii.img  =  atSmNormN4T2w/maxAtLccNormN4T2w;

save_untouch_nii(normAtSmNii, sprintf('%s_atSmNormN4.nii',inN4T2w));



return



function outNii = local_load_nii(inNiiFileName)


%% Read in raw image and normalize
%

fprintf('Importing %s \n', inNiiFileName)

if exist(inNiiFileName, 'file')==2   % FileName complete
    
    outNii = load_untouch_nii(inNiiFileName);
    
elseif exist(strcat(inNiiFileName,'.nii'), 'file')==2  % Filename without NII extension
    
    outNii = load_untouch_nii(sprintf('%s.nii',inNiiFileName));

elseif exist(strcat(inNiiFileName,'.nii.gz'), 'file')==2  % Filename without NII.GZ extension
    
    system(sprintf('gunzip %s.nii.gz',inNiiFileName));
    outNii = load_untouch_nii(inNiiFileName);
    system(sprintf('gzip %s.nii',inNiiFileName));
    
elseif exist(strcat(inNiiFileName,'.gz'), 'file')==2   %Filename without GZ extension
    
    system(sprintf('gunzip %s.gz',inNiiFileName));
    outNii = load_untouch_nii(inNiiFileName);
    system(sprintf('gzip %s',inNiiFileName));

else  % No File Found
    
    error('No File Found');
    
end
