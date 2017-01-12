function outNii = load_untouch_niigz(inNiiFileName)


%% Read in raw image and normalize
%

if exist(inNiiFileName, 'file')==2
        
    system(sprintf('gunzip %s',inNiiFileName));
    outNii = load_untouch_nii(inNiiFileName);
    system(sprintf('gzip %s', inNiiFileName(1:end-3)));
    
else
    
    error('No File Found');
    
end

end

