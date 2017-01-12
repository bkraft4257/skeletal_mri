function [ kdat2_cor, nM0 ] = mskPcasl_kspace_correct(inRawDat, nPlaceCalibrationOffset, nM0)

if nargin < 2 || isempty(nPlaceCalibrationOffset)
    nPlaceCalibrationOffset = 8;
end




k                     = mapVBVD(inRawDat);
k.image.flagIgnoreSeg = 1;
v                     = extract_vrgf(k.image.filename);

kdat    = tmult(permute( squeeze(k.image(:,:,:,1,:,1,1,1,:)), [1 3 4 2 5]),v',1);
sz      = size(kdat);

nSlices = sz(3);
maxTcnt = sz(5);

if nargin < 2 || isempty(nM0)
    if maxTcnt > 80
        nM0 = 89;
    else
         nM0 = maxTcnt;
    end
end


%
%  R=2 accelaration with 2 step temporal encoding
%
%  +/- is the Readout direction
%
% end-0:  1+ 3-  5+ 7- ...
% end-1:  2+ 4-  6+ 7- ...
% end-2:  1- 3+  5- 7+ ...
% end-3:  2- 4+  6- 8+ ...
% (end-1) combined with (end-3) to give (R=2 data)  
% a1: 2+ 4+ 6+ ...
% b1: 2- 4- 6- ...
% 
% c1: coherent combination of a1 and b2, to get rid of ghost artifacts in these segments

    placeReference = nM0 + [0 1 2 3 ] - nPlaceCalibrationOffset   % a1/b1  a2/b2;
    
    %% Even lines of data
    %
    % A1 Interleaved RO+, B1=Interleaved RO- ,  C1=PLACE Combination Reference images grabbed here (
    %
    %  A1 and B1 should be complete but subsampled by factor of 2
    %
    
    a1 = zeros( sz(1:4).*[1 1/2 1 1] ); 
    a1(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,placeReference(1) );  %placeReference(1) = end - 3
    a1(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,placeReference(2) );  %placeReference(2) = end - 1
    
    b1 = zeros( sz(1:4).*[1 1/2 1 1] ); 
    b1(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,placeReference(2) );  %placeReference(1) = end - 1
    b1(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,placeReference(1) );  %placeReference(1) = end - 3
    
    c1 = ifi(pos_neg_add( fif(a1), fif(b1) ))/2;
    
    clear F1;
    [ifull,jfull] = find(ones(sz(2)/2,sz(1)));
    
    %
    % GRAPPA Operator Gridding
    %
    
    for slc=1:nSlices;
        G1{slc}       = grog( reshape(permute(squeeze(c1(:,:,slc,:)),[2 1 3]),[sz(1)*sz(2)/2 sz(4)]), [ifull jfull] ,[],'kernel','1x5','refang',0);
        F1(:,:,slc,:) = grog( reshape(permute(squeeze(c1(:,:,slc,:)),[2 1 3]),[sz(1)*sz(2)/2 sz(4)]), [ifull+0.5 jfull], G1{slc}, 'kernel', '1x5' );
    end;
    
    F1 = permute(reshape(F1,[sz(2)/2 sz([1 4 3])]),[2 1 4 3]);
    AA = zeros(sz(1:4));
    AA(:,1:2:end,:,:) = F1;
    AA(:,2:2:end,:,:) = c1;
    
    
    %% Odd lines
    %
    %
    % A2 Interleaved RO-,B1=Interleaved RO- ,C1=PLACE Combination Reference images grabbed here (
    %
    
    a2 = zeros(sz(1:4).*[1 1/2 1 1]); 
    a2(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,placeReference(3) );  %placeReference(3) = end - 2
    a2(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,placeReference(4) );  %placeReference(1) = end - 0
    
    b2 = zeros(sz(1:4).*[1 1/2 1 1]); 
    b2(:,1:2:end,:,:) = kdat(:,2:4:end,:,:,placeReference(4) );  %placeReference(1) = end - 0
    b2(:,2:2:end,:,:) = kdat(:,4:4:end,:,:,placeReference(3) );  %placeReference(1) = end - 2
    
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

%
%  PLACE shift correction
% 

kdat2_cor = kdat_cor;

% 1+ 2+ 3- 4- 5+ 6+ 7- 8- 9+ 10+

placeShift = 4;
pCaslCycle = 4;

kdat2_cor(:,:,:,:,5:pCaslCycle:end) = kdat_cor(:,[(placeShift+1):end 1:placeShift],:,:,5:pCaslCycle:end);
kdat2_cor(:,:,:,:,2:pCaslCycle:end) = kdat_cor(:,[(placeShift+1):end 1:placeShift],:,:,2:pCaslCycle:end);
    