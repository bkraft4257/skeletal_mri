function indexNull = mskPcasl_null( nVolumes, nCycle )

if nargin < 1 || isempty(nVolumes)
    nVolumes = 100;
end

if nargin < 2 || isempty(nCycle)
   nRef = 8; 
end

volumes  = 1:nVolumes;
cycle    = mod(volumes,nCycle) ;


return
