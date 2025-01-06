clc; clear; clc
addpath('neuroshare')
% sudo mount -t cifs -o username=cohenlab,password=GrayMatter1 //cohenlab.pina.uchicago.edu/colada /media/colada_mount

% addpath('/Users/ramanujan/Documents/postdoc/work/dep/NPMK')
% addpath('matlabtools/neuroshare/')

%folderPath = 'C:\Users\Cohen Lab\Documents\Data';
% folderPath = '/media/colada_mount/Ram/data/neural/v4-7a';
% folderPath = '/home/cohenlab/Trellis/dataFiles';\
folderPath = 'raw_data_temp';
altfolderPath = '/mnt/colada_share/Ram/data/neural/v4-7a';

folders = dir([folderPath '/24*']); 
folders = {folders.name};
for ii=1:length(folders)
    folder = [folderPath '/' folders{ii}];
    files = dir([folder '/*.nev']);
    files = cellfun(@(x) [folder '/' strrep(x,'.nev','')],{files.name},'UniformOutput',false);
    cellfun(@(x) pipeline_test_fn(x,folderPath,altfolderPath),files);
end

% %%
% pipeline_test_fn([folderPath '\' folders{1} '\' 'zippy_imgMap_240606-155934'])

%%
function pipeline_test_fn(FileName,folderPath,altfolderPath)
    thisname = [FileName '_trialinfo.mat'];
    altname = [altfolderPath FileName(length(folderPath)+1:end)];
    if exist(altname,'file')
        disp([FileName ' exists on server. skipping...'])
        return;
    elseif exist(thisname,'file')
        disp([FileName ' exists locally. copying...'])
        % copyfile(thisname,altname)
        return
    else
        disp(['... analysing ' FileName '=== NEV'])
        % open up nev file (this function may need to be compiled)
        nev=readNEV( [FileName '.nev']);
    
        % renumber channels (keep this!!)
        renumber = find(nev(:,1)> 128); % reset channels coming from B bank (starts at 129) to be 33-128;
        nev(renumber,1) = nev(renumber,1) - 32; % 32 for helium, 96 for zippy
        
        %dar added continuous signal extraction
        %extract the eye signals (x and y), pupil signal, and diode trace
        %extract_all_data is recommended because it correctly handles paused files
        disp([FileName ' === 1K'])
        [analogSignals.xVals, analogSignals.eyeX] = extract_all_data('Analog 1k', 10241, [FileName '.ns2']);
        analogSignals.xVals = analogSignals.xVals';
        [~, analogSignals.eyeY] = extract_all_data('Analog 1k', 10242, [FileName '.ns2']); %eyeY
        [~, analogSignals.pupil] = extract_all_data('Analog 1k', 10243, [FileName '.ns2']); %pupil

        %dar added diode extraction
        disp([FileName ' === 30K'])
        [analogSignals.diodeXvals, diodeData] = extract_all_data('Analog 30k', 10244, [FileName '.ns5']);
        analogSignals.diodeData = diodeData';

        % try
        %     trials = gettrialinfo(nev, analogSignals);
        %     save(thisname,'trials','FileName','-v7.3')
        % catch me
            % disp(me.identifier)
            % disp('ram: couldn''t use traditional gettrialinfo')
            % disp('ram: getting behav to reconcile')

            % get behav file if available
            if exist([FileName '.mat'],'file')
                load(FileName,'behav','allCodes')
                % get and save the behavioral and physiology data
                trials = gettrialinfo_behav(nev, analogSignals, behav,allCodes);     
            end
        % end
        
        disp('... saving trial info')
        save(thisname,'trials','FileName','-v7.3')
        % save(altname,'trials','FileName','-v7.3')
    end
end