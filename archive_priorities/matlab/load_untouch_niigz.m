function outNii = load_untouch_niigz(inNiiFileName)


%% Read in raw image and normalize
%

if exist(inNiiFileName, 'file')==2
    
    outNii = load_untouch_nii(inNiiFileName);
    
    
elseif exist(strcat(inNiiFileName,'.gz'), 'file')==2
    
    system(sprintf('%s.gz',inNiiFileName));
    outNii = load_untouch_nii(inNiiFileName);
else
    
    error('No File Found');
    
end

end

