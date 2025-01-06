clc; clear; close all

rawLoc = '/Volumes/colada/Ram/data/neural/v4-7a';
dataLoc = '~/Downloads/v4-7a';

dirs = dir([rawLoc '/24*']);
if isempty(dirs)
    warning('Colada offline or not mounted.')
    return;
end

missingFiles = {}; mfCount = 1; afCount = 1;
for ii=1:length(dirs)
    disp(dirs(ii).name);
    nevList = dir([rawLoc '/' dirs(ii).name '/*grid*nev*']);
    nevList = {nevList.name};
    nameList = cellfun(@(x) strrep(x,'.nev',''),nevList,'UniformOutput',false);
    matList = cellfun(@(x) strrep(x,'.nev','.mat'),nevList,'UniformOutput',false);
    tiList = cellfun(@(x) strrep(x,'.nev','_trialinfo.mat'),nevList,'UniformOutput',false);
    denseList = cellfun(@(x) strrep(x,'.nev','_dense.mat'),nevList,'UniformOutput',false);
    
    for jj=1:length(nevList)
        rec(afCount).date = dirs(ii).name;
        rec(afCount).expt = nameList{jj};
        afCount = afCount + 1;

        if ~exist([rawLoc '/' dirs(ii).name '/' matList{jj}],'file'); missingFiles{mfCount} = matList{jj}; mfCount = mfCount+1; end
        if ~exist([rawLoc '/' dirs(ii).name '/' tiList{jj}],'file'); missingFiles{mfCount} = tiList{jj}; mfCount = mfCount+1; end
        if ~exist([rawLoc '/' dirs(ii).name '/' denseList{jj}],'file'); missingFiles{mfCount} = denseList{jj}; mfCount = mfCount+1; end
    end
end