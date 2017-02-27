function msk_sm_fat_fraction( inN4T2w, inLabels )
%% Initialization

if nargin<1
    inN4T2w='jmri_t2w_n4';
end

if nargin<2
    inLabels='t2w_labels';
end


cleanFlag = 'true';

inSmoothFactor = 3;
inPrefix    = 'jmri';
prefix      = sprintf('%s_%s', inPrefix, inN4T2w);

debugFlag = false;

%% Read in raw image and normalize
%
n4T2wFileName  = sprintf('%s.nii', inN4T2w);

if exist(n4T2wFileName, 'file')==2

    n4T2wNii = load_untouch_nii(n4T2wFileName);

elseif exist(strcat(n4T2wFileName,'.gz'), 'file')==2

        system(sprintf('%s.gz',n4T2wFileName));
        n4T2wNii = load_untouch_nii(n4T2wFileName);
else

    error('No File Found');
    
end

templateNii = n4T2wNii;

n4T2w    = double(n4T2wNii.img);
normN4T2w    = n4T2w/max(n4T2w(:));

[nFreq, nPhase, nSlices ]= size(n4T2w);

%%
%

labelFileName  = sprintf('%s.nii', inLabels);

if exist(labelFileName, 'file')==2

    labelNii = load_untouch_nii(labelFileName);

elseif exist(strcat(labelFileName,'.gz'), 'file')==2

        system(sprintf('%s.gz',labelFileName));
        labelNii = load_untouch_nii(labelFileName);
else

    error('No File Found');
    
end

%%
%

smLabels = double(labelNii.img);

atMask   = (smLabels==1);
smMask   = (smLabels==2);



at       = normN4T2w .* atMask;
atStats = [ mean(at(atMask(:)))  std(at(atMask(:))) ];
atThreshold = atStats(1)

sm       = normN4T2w .* smMask;

smNii    = templateNii;
smNii.img = sm;

save_untouch_nii(smNii, sprintf('%s_sm.nii', inN4T2w))


figure(2); histogram(at(at>0),100)


[N, edges] = histcounts(sm(:),100);

smNormDist = fitdist(sm(sm>0),'normal')

x = 0:.01:1;
y = pdf(smNormDist ,x);
plot(x,y,'LineWidth',2)
hold on;
plot(x(3:end),N(2:end)/max(N(:)));

return


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

            