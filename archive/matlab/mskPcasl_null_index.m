function indexNull = mskPcasl_null_index( nVolumes, nCycle )

if nargin < 1 || isempty(nVolumes)
    nVolumes = 100;
end

if nargin < 2 || isempty(nCycle)
   nCycle = 4; 
end

nLastFullCycleVolume = nCycle*floor(nVolumes/nCycle)
volumes              = 1:(nLastFullCycleVolume);
cycle                = mod(volumes-1,nCycle) + 1;

indexNull = 0*volumes;

switch nCycle
        
    case 4

        index1 = find(cycle == 1 );
        index2 = find(cycle == 2 );
        index3 = find(cycle == 3 );
        index4 = find(cycle == 4 );
        
        indexNull(index1) = volumes(index1);
        indexNull(index2) = volumes(index2) + 1;
        indexNull(index3) = volumes(index3) - 1;
        indexNull(index4) = volumes(index4);
    
        
    otherwise
        
        error('unknown cycle');
        
end

return
