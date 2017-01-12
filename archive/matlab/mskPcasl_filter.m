function idat7_cor = mskPcasl_filter( kdat_cor, nRef, b, a )

% end-0:  1+  3-  5+  7- ...
% end-1:  2+  4-  6+  7- ...
% end-2:  1-  3+  5-  7+ ...
% end-3:  2+  3-  5+  7- ...


    %  run the data through the time-domain UNFOLD filtering routine
    idat2_cor = fif(kdat_cor);
    idat3_cor = permute(idat2_cor, [1 2 3 5 4]);
    idat4_cor = idat3_cor(:,:,:,2:end-nRef,:);
    
    I = idat4_cor;
    sz = size(I);
    Isynth = zeros([ sz(1 : 3 ) sz(4)*2 sz(5)]);
    Isynth(:,:,:,1:sz(4),: ) = flip(I,4);
    Isynth(:,:,:,sz(4)+(1:sz(4)),: ) = I;
    
    idat5_cor = 0*Isynth;
    
    for ii=1:sz(1)
        fprintf('%02d \n',  ii)
        for jj=1:sz(2)
            for kk=1:sz(3)
                for ll=1:sz(5)
                    idat5_cor(ii,jj,kk,:,ll) = filter(b,a, squeeze(Isynth(ii,jj,kk,:,ll)) );
                end
            end
        end
    end
    
    
    temporal_scale =  max(abs(idat4_cor(:)))/max(abs(idat5_cor(:)));
    idat5_cor      = idat5_cor * temporal_scale;
    
    idat6_cor                     = idat3_cor;
    idat6_cor(:,:,:,2:end-nRef,:) = idat5_cor(:,:,:,end-sz(4)+1:end,:);
    
    idat7_cor                     = squeeze(sqrt( sum(idat6_cor .* conj(idat6_cor),5)));
