function msk_round_image( inImage, outImage, inLabels)

inNii       = load_untouch_nii(inImage);
outNii      = inNii;
outNii.img  = round(inNii.img)

  outLabel    = zeros( [ size(outNii.img), length(inLabels) ]) 
save_untouch_nii(outNii, outImage );

