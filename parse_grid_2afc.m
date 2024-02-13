clc; clear; close all

rawLoc = '/Volumes/colada/Ram/data/neural/v4-7a';
dataLoc = '~/Downloads/v4-7a';

exptRecord = crawlForFiles(rawLoc,dataLoc);
exptRecord = parse_all_records(exptRecord,dataLoc);

%% helpers
function exptRecord = parse_all_records(exptRecord,dataLoc)
    if isempty(exptRecord); return; end
    
    for ii=1:length(exptRecord)
        exptName = exptRecord(ii).path(1+find(exptRecord(ii).path=='/',1,'last'):end);
        disp(exptName)
        if ~exist([dataLoc '/' exptName '_dense.mat'],'file')
            disp('... getting remote')
            load([exptRecord(ii).path '_trialinfo'],'trials')
            load(exptRecord(ii).path)
            behav = [behav.trialData];
        
            clearvars params resp resp_base
            trialCount = 0;
            for tt=1:length(trials)
                if trials{tt}.selected > 0
                    trialCount = trialCount + 1;
                    params(trialCount).id = trials{tt}.id;
                    params(trialCount).stimRF_set = trials{tt}.stimRF_set;
                    params(trialCount).stimRF_num = trials{tt}.stimRF_num;
                    params(trialCount).stimOpp_set = trials{tt}.stimOpp_set;
                    params(trialCount).stimOpp_num = trials{tt}.stimOpp_num;
                    params(trialCount).correct = trials{tt}.correct;
                    params(trialCount).selected = trials{tt}.selected;
    
                    params(trialCount).spikes = trials{tt}.spikes(:,[1 3]);
                    params(trialCount).spikes(:,2) = params(trialCount).spikes(:,2)-trials{tt}.stimstart;
        
                    sp = params(trialCount).spikes(:,1);
                    t_sp = params(trialCount).spikes(:,2);
        
                    respDur = behav(tt).stim.on/1000;
                    respLims = [0.05 respDur];
                    baseLims = [-0.1 0];
                    
                    sp_idx = t_sp > baseLims(1) & t_sp < respLims(2); % find all spikes in the window
                    sp_ch = sp(sp_idx); % the channels the spikes were on
                    [sp_ch,idx] = sort(sp_ch); % sort by channel
                    sp_ts = t_sp(sp_idx); % get spike timestamps (in s)
                    sp_ts = sp_ts(idx); % sort in the same way as channels
                    
                    params(trialCount).resp      = histcounts(sp_ch(sp_ts > respLims(1)),0.5:1:128.5)/respDur;
                    params(trialCount).resp_base = histcounts(sp_ch(sp_ts < baseLims(2)),0.5:1:128.5)/0.1;
                    
                    resp(trialCount,:) = params(trialCount).resp;
                    resp_base(trialCount,:) = params(trialCount).resp_base;
                end
            end
    
            save([exptRecord(ii).path '_dense'],'params','resp','resp_base')
            save([dataLoc '/' exptName '_dense.mat'],'params','resp','resp_base')
        else
            load([dataLoc '/' exptName '_dense.mat'],'params')
        end
    
        exptRecord(ii).name = exptName;
        exptRecord(ii).nTrials = length(params);
        exptRecord(ii).nCorrect = sum(arrayfun(@(tt) params(tt).correct==params(tt).selected,1:length(params)));
        exptRecord(ii).stimRF_set = unique([params.stimRF_set]);
        exptRecord(ii).stimRF_num = unique([params.stimRF_num]);
        exptRecord(ii).stimOpp_set = unique([params.stimOpp_set]);
        exptRecord(ii).stimOpp_num = unique([params.stimOpp_num]);
    end
    
    save('data/exptRecord.mat','exptRecord')
end

function exptRecord = crawlForFiles(rawLoc,dataLoc)
    filelist = cell(1);
    dirs = dir([rawLoc '/24*']);
    if isempty(dirs)
        warning('Colada offline or not mounted.')
    end
    for ii=1:length(dirs)
        files_grid = dir([rawLoc '/' dirs(ii).name '/*grid*nev*']);
        filelist = [filelist cellfun(@(x) strrep([rawLoc '/' dirs(ii).name '/' x],'.nev',''),{files_grid.name},'UniformOutput',false)];
        % if length(files_nev) ~= length(files_grid)
        %     for jj=1:length(files_nev)
        %         files_nev.name(jj)
        %     end
        % end
    end
    filelist(1) = [];
    exptRecord = cell2struct(filelist,'path',1);

    % if data location is passed, then copy trial info files there if they
    % don't exist; this is not necessary, just faster later
    % if exist('dataLoc','var')
    %     for ii=1:length(exptRecord)
    %         exptName = exptRecord(ii).path(1+find(exptRecord(ii).path=='/',1,'last'):end);
    %         if ~exist([dataLoc '/' exptName '_trialinfo.mat'],'file')
    %             copyfile([exptRecord(ii).path '_trialinfo.mat'],[dataLoc '/' exptName '_trialinfo.mat'])
    %         end
    %     end
    % end
end