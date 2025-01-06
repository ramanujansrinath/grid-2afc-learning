function trials = gettrialinfo_behav(nev,analogSignals,behav,allCodes)
    % this is the same as the traditional gettrialinfo except it doesn't rely
    % on codes. instead it gets start and end trial times from the behav file
    % and stim times from diode. the only code it cares about is the first
    % start code. this needs to be verified for every file outside of this. in
    % the future, there should be a warning dialog and display of the first n
    % seconds before the detected first trial start code to make sure that it's
    % correct.
    
    behav = [behav.trialData];
    
    START_TRIAL = 1;
    END_TRIAL = 255; %32768 CHANGED!!!!
    % END_TRIAL = 40; %32768
    
    codes = nev(nev(:,1)==0,2:3);
    nev = nev(nev(:,1) ~= 0,:);
    
    starts = find(codes(:,1) == START_TRIAL);
    ends = find(codes(:,1) == END_TRIAL);
    
    [startTimes,endTimes,stimDurs] = inferStartsEnds_behav(starts,codes,behav,allCodes);
    
    trials = cell(length(behav),1);
    for ii = 1:length(behav)
        if mod(ii,100)==0
            disp(['Processing trial ' num2str(ii) ' out of ' num2str(length(behav))]);
        end
        
        trial = struct();
        startTime = startTimes(ii);
        endTime = endTimes(ii);
        trial.startTime = startTime;
        trial.endTime = endTime;
        
        trial.spikes = nev(nev(:,3) > startTime & nev(:,3) < endTime,:);
        trial.codes = allCodes{ii}.codes; % codes(starts(ii):ends(ii),:);
        
        trial.spikes(:,3) = trial.spikes(:,3) - startTime;
        % trial.codes(:,2) = trial.codes(:,2) - startTime;
        
        trial.eyeX = analogSignals.eyeX(round(trial.startTime*1000):round(trial.endTime*1000));
        trial.eyeY = analogSignals.eyeY(round(trial.startTime*1000):round(trial.endTime*1000));
        trial.pupil = analogSignals.pupil(round(trial.startTime*1000):round(trial.endTime*1000));
        trial.oneKHzXval = analogSignals.xVals(round(trial.startTime*1000):round(trial.endTime*1000)); 
        trial.Diodeval = analogSignals.diodeData(round(trial.startTime*30000):round(trial.endTime*30000));
        trial.ThirtyKHzXval = analogSignals.diodeXvals(round(trial.startTime*30000):round(trial.endTime*30000));
            
    
        [stimOn,stimOff] = getStimTimesFromDiode(trial.ThirtyKHzXval,trial.Diodeval);
    
        trial.stimstart = stimOn;
        trial.fixmove = nan; % remove this? put in something more useful???
        trial.stimend = stimOff;
        trial.stimDur_beh = stimDurs(ii)/1000;
        trial.stimDur_diode = stimOff-stimOn;
        trial.fixate = nan;
           
        trials{ii} = trial;
    end
end

function [startTimes,endTimes,stimDur] = inferStartsEnds_behav(starts,codes,behav,allCodes)
    id_str = int2str([behav.id]');
    id_str(:,1:8) = ''; % remove date
    id(:,1) = str2num(id_str(:,1:2))*60*60*1000;
    id(:,2) = str2num(id_str(:,3:4))*60*1000;
    id(:,3) = str2num(id_str(:,5:6))*1000;
    id(:,4) = str2num(id_str(:,7:9));
    id = sum(id,2);
    id = id-id(1);
    
    trialStartTime = codes(starts(1),2) + id/1000;
    
    % for grid_2afc
    if isfield(behav,'behav')
        trialDur = [behav.behav]; 
        trialDur = [trialDur.trialTime]';

        stimDur = [behav.stim]; 
        stimDur = [stimDur.on];
    else
        trialDur = nan(length(allCodes),1);
        stimDur = nan(length(allCodes),1);
        for ii=1:length(allCodes)
            trial_st = allCodes{ii}.codes(allCodes{ii}.codes(:,1)==1,2);
            trial_end = allCodes{ii}.codes(allCodes{ii}.codes(:,1)==255,2);
            trialDur(ii) = trial_end-trial_st;

            stim_on = allCodes{ii}.codes(allCodes{ii}.codes(:,1)==10,2);
            stim_off = allCodes{ii}.codes(allCodes{ii}.codes(:,1)==40,2);
            if ~isempty(stim_off) && ~isempty(stim_on)
                stimDur(ii) = stim_off-stim_on;
            end
        end
    end
    trialEndTime = trialStartTime + trialDur;

    startTimes = trialStartTime;
    endTimes = trialEndTime;
end

function [stimOn,stimOff] = getStimTimesFromDiode(diodeT,diodeY)
    diodeThreshold = 50;
    diodeY(diodeY<diodeThreshold) = 0;
    stimOn = diodeT(find(diodeY>0,1));
    stimOff = diodeT(find(diodeY>0,1,'last'));
end