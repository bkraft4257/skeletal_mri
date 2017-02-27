function msk_classify_thigh_v1( inDir, outDir, inSegments )

%% Initialization

if nargin<1 || isempty(inDir) % || isempty(inDir =='')
    inDir=pwd;
end

if nargin<2 || isempty(outDir) % || isempty(outDir == '')
   outDir=fullfile(inDir,'../04-classify');
end

if nargin<3 || isempty(inSegments)
  inSegments        = 1;
end

inN4T2w = 't1w_36ms_n4';


if( ~(exist(outDir,'dir') == 7) )
   system(sprintf('mkdir -p %s',outDir)); 
end

n4T2wFileName  = fullfile(inDir,sprintf('%s.nii', inN4T2w));
n4T2wNii       = local_load_nii(n4T2wFileName);

system(sprintf('cp -f %s %s',n4T2wFileName, fullfile(outDir,sprintf('%s.nii',inN4T2w))));




%% Read in raw image and normalize
%



templateNii = n4T2wNii;

n4T2w    = double(n4T2wNii.img);
normN4T2w    = n4T2w/max(n4T2w(:));



%%  Read in Label Images
%

labelFileName  = fullfile(inDir,sprintf('%s_labels.nii', inN4T2w));
labelNii       = local_load_nii(labelFileName);

%%  Read in AT Largest Connected Component
%

atLccFileName  = fullfile(inDir,sprintf('%s_atLcc.nii', inN4T2w));
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

    save_untouch_nii(smSegmentNii, fullfile(outDir,sprintf('%s_smSegment_%02d.nii',inN4T2w, iiSegments)));

end

%% Normalize Muscle by AT and SM mask
%

maxAtLccNormN4T2w = max(atSmNormN4T2w(logical(atLccMask(:))));

normAtSmNii      = templateNii;
normAtSmNii.img  =  atSmNormN4T2w/maxAtLccNormN4T2w;

save_untouch_nii(normAtSmNii, fullfile(outDir,sprintf('%s_atSmNormN4.nii',inN4T2w)));



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
