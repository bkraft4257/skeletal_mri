function pepper_pcasl_recon( inFileName,  inRawOnlineNii, inPrefix )

if nargin<3 || isempty(inPrefix)
   inPrefix = 'hoge.'; 
end

kFileName = strcat(inPrefix,'kspace.',inRawOnlineNii, '.mat');

fileName = inFileName;



prefix   = inPrefix;


if ~exist(kFileName)

  k = mapVBVD(fileName);
  k.image.flagIgnoreSeg = 1;
  v = extract_vrgf(k.image.filename);

kdat    = tmult(permute( squeeze(k.image(:,:,:,1,:,1,1,1,:)), [1 3 4 2 5]),v',1);
sz      = size(kdat);

nSlices = sz(3);
nCoils  = sz(4);
maxTcnt = sz(5);

a1 = zeros( sz(1:4).*[1 1/2 1 1] ); a1(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,end-3); a1(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,end-1);
b1 = zeros( sz(1:4).*[1 1/2 1 1] ); b1(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,end-1); b1(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,end-3);
c1 = ifi(pos_neg_add( fif(a1), fif(b1) ))/2;

clear F1;
[ifull,jfull] = find(ones(sz(2)/2,sz(1)));



for slc=1:nSlices;
  G1{slc} = grog( reshape(permute(squeeze(c1(:,:,slc,:)),[2 1 3]),[sz(1)*sz(2)/2 sz(4)]), [ifull jfull] ,[],'kernel','1x5','refang',0);
  F1(:,:,slc,:) = grog( reshape(permute(squeeze(c1(:,:,slc,:)),[2 1 3]),[sz(1)*sz(2)/2 sz(4)]), [ifull+0.5 jfull], G1{slc}, 'kernel', '1x5' );
end;

F1 = permute(reshape(F1,[sz(2)/2 sz([1 4 3])]),[2 1 4 3]);
AA = zeros(sz(1:4));
AA(:,1:2:end,:,:) = F1;
AA(:,2:2:end,:,:) = c1;


a2 = zeros(sz(1:4).*[1 1/2 1 1]); a2(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,end-2); a2(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,end);
b2 = zeros(sz(1:4).*[1 1/2 1 1]); b2(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,end); b2(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,end-2);
c2 = ifi(pos_neg_add( fif(a2), fif(b2) ))/2;

clear F2;
[ifull,jfull] = find(ones(sz(2)/2,sz(1)));

for slc=1:nSlices;
  G2{slc} = grog( reshape(permute(squeeze(c2(:,:,slc,:)),[2 1 3]),[sz(1)*sz(2)/2 sz(4)]), [ifull jfull] ,[],'kernel','1x5','refang',0);
  F2(:,:,slc,:) = grog( reshape(permute(squeeze(c2(:,:,slc,:)),[2 1 3]),[sz(1)*sz(2)/2 sz(4)]), [ifull+0.5 jfull], G2{slc}, 'kernel', '1x5' );
end;

F2 = permute(reshape(F2,[sz(2)/2 sz([1 4 3])]),[2 1 4 3]);

% BB = zeros([64 62 5 15]); BB(:,1:2:end,:,:) = F2; BB(:,2:2:end,:,:) = c2;
%%% odd frames are offset by 1ky line, due to PLACE being on...
BB = zeros(sz(1:4)); 
BB(:,[end 2:2:(end-1)],:,:) = F2; 
BB(:,1:2:end,:,:) = c2;

CC = ifi( pos_neg_add( fif(AA), fif(BB) )/2 );

for slc=1:nSlices; [~,~,Nc{slc}] = grappa([sz([1 2 4])],squeeze( CC(:,:,slc,:) ), vec(1:62),'2x5',[2;4]); end;



kdat_cor = zeros(size(kdat));
for slc=1:5;
  fprintf('-');
  for Tcnt=1:maxTcnt;
    fprintf('.');
  
    Fa = grappa([sz([1 2 4])],double(squeeze(kdat(:,2:4:end,slc,:,Tcnt))),vec(2:4:62),'2x5',4,Nc{slc});
    Fb = grappa([sz([1 2 4])],double(squeeze(kdat(:,4:4:end,slc,:,Tcnt))),vec(4:4:62),'2x5',4,Nc{slc});

    Fc = phzshift( permute(fif(Fa),[2 1 3]), permute(fif(Fb),[2 1 3]), 'nofft' );

    kdat_cor(:,:,slc,:,Tcnt) = permute( ifi(Fc), [2 1 3] );

  end;
  fprintf('\n');
end;

kdat2_cor = flip(flip(kdat_cor,2),3); 

save(kFileName,'kdat2_cor') 
else
        
    fprintf('\nLoading %s \n', kFileName);
    load(kFileName,'kdat2_cor')
end

%
% 

idat2_cor     = fif(kdat2_cor);
idat3_cor     = squeeze(sqrt( sum(idat2_cor .* conj(idat2_cor),4)));
%
% Save images 
%

inNii                   = load_untouch_nii(inRawOnlineNii);

maxInNii                = max(inNii.img(:));

scaleNii                = double(maxInNii) / max(idat3_cor(:));

outNii     = inNii;
outNii.img = double(outNii.img);
outNii.img(:,3:end,:,:)  = scaleNii * double(idat3_cor);


outNii.hdr.dime.datatype = 64;  % float64'



save_untouch_nii(outNii, strcat(prefix, inRawOnlineNii));
