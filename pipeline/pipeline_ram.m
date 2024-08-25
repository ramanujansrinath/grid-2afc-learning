clc; clear; clc
addpath('neuroshare')
% addpath('/Users/ramanujan/Documents/postdoc/work/dep/NPMK')
% addpath('matlabtools/neuroshare/')

%folderPath = 'C:\Users\Cohen Lab\Documents\Data';
folderPath = 'Z:\Ram\data\neural\v4-7a';
folders = {'240731','240801','240802','240805','240806','240807'};
for ii=1:length(folders)
    folder = [folderPath '/' folders{ii}];
    files = dir([folder '/*.nev']);
    files = cellfun(@(x) [folder '/' strrep(x,'.nev','')],{files.name},'UniformOutput',false);
    cellfun(@(x) pipeline_test_fn(x),files);
end

% %%
% pipeline_test_fn([folderPath '\' folders{1} '\' 'zippy_imgMap_240606-155934'])

%%

function pipeline_test_fn(FileName)
    thisname=[FileName '_trialinfo.mat'];
    if ~exist(thisname,'file')
        disp([FileName '=== NEV'])
        % open up nev file (this function may need to be compiled)
        nev=readNEV( [FileName '.nev']);
    
        % renumber channels (keep this!!)
        renumber = find(nev(:,1)> 128); % reset channels coming from B bank (starts at 129) to be 33-128;
        nev(renumber,1) = nev(renumber,1) - 96;
        
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

        try
            trials = gettrialinfo(nev, analogSignals);
        catch me
            disp(me.identifier)
            disp('ram: couldn''t use traditional gettrialinfo')
            disp('ram: getting behav to reconcile')

            % get behav file if available
            if exist([FileName '.mat'],'file')
                load(FileName,'behav','allCodes')
                % get and save the behavioral and physiology data
                trials = gettrialinfo_behav(nev, analogSignals, behav,allCodes);     
            end
        end
        
        save(thisname,'trials','FileName','-v7.3')
    end
end