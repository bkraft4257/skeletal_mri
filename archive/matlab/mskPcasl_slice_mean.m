function  mskPcasl_slice_mean( inNii, outFileName, sliceIndex )

%
%
%

if nargin<2 || isempty(outFileName)
    outFileName =  strcat('slice_mean.', inNii );
end


xNii         = load_untouch_nii( inNii );
nSlices      = size(xNii.img,3);

if nargin<3 || isempty(sliceIndex)
    sliceIndex =  1:nSlices;
end


x            = double(xNii.img);

xNii.img                      = double(0*x);
tmp                           = mean(x(:,:,sliceIndex,:),3);
xNii.img(:,:,(nSlices+1)/2,:) = tmp;


save_untouch_nii(xNii, outFileName );

return

