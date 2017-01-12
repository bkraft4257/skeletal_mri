function  mskPcasl_slice_scale( inNii, inSliceScale, outFileName )

%
%
%

xNii         = load_untouch_nii( inNii );
nSlices      = size(xNii.img,3);

if nargin< 2 || isempty(inSliceScale)
    
    inSliceScale               = zeros(1,nSlices);
    
    if mod(nSlices,2)   
        inSliceScale((nSlices+1)/2)   = 1;
    else
        inSliceScale(nSlices/2+(0:1)) = 1;
    end
end

if nargin<3 || isempty(outFileName)
    outFileName =  strcat('slice_scale.', inNii );
end

for ii=1:nSlices 
    xNii.img(:,:,ii,:)  = inSliceScale(ii) * double(xNii.img(:,:,ii,:));
end

save_untouch_nii(xNii, outFileName );

return

