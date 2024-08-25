function trials = gettrialinfo(nev, analogSignals)
% Function to read nev files created with Ex.
% nev: a Nx3 matrix where the columns are elec num, sort code, time(s),
% should be created with runNEV
% diode: the 1kHz photodiode signal (optional)
% thresh: the value for the diode threshold.  aligning happens the
%  first time the diode is greater than this value (optioal)
%
% output is a 1xnumtrials cell array
% each entry is struct (e.g. trials{20} is the structure for the 20th trial)
% each struct has with the fields:
%   startTime, endTime (boundary for this trial; will give an error if start
%       is not before end)
%   spikes (numspikes x 3 array; first column is electrode #, second
%       column is sort code, third column is timestamp)
%   codes  (numcodes x 2 array; first column is code, second is timestamp)
%   stimstart (numstim x 1 vector of stimulus start times)
%   cnd (condition number)
%   channels (numunits x 2 array, first column is electrode #, second is
%       sort code)
%   msgs (decoded ascii messages)
%   several more fields with the decoded messages
%   several more fields with the code indicating trial type (outcome,
%       instruct, correction, attention);  these will be empty if they don't
%       exist

warnVarFlag = 0;

START_TRIAL = 1;
END_TRIAL = 255; %32768 CHANGED!!!!
% END_TRIAL = 40; %32768


% Any string composed solely of ASCII codes from this set will be
% considered to be numeric. If the string contains at least one value
% that is not a member of this set, it will be considered a string data
% type
NumericSet = double(unique([num2str(0:9),' ',',','.','-','e']));

codes = nev(nev(:,1)==0,2:3);
nev = nev(nev(:,1) ~= 0,:);

channels = unique(nev(:,1:2),'rows');
sortInd=find(channels(:,2)>0);
sortedChannels=channels(sortInd,:);

starts = find(codes(:,1) == START_TRIAL);
ends = find(codes(:,1) == END_TRIAL);

m=min([length(starts) length(ends)]);
match=ends(1:m-1)>starts(2:m);

while sum(match)
    badtrial=min(find(match==1));
    disp(['Trial number ' num2str(badtrial) ' has no end code and will not be analyzed'])
    starts=[starts(1:badtrial-1); starts(badtrial+1:end)];
    m=min([length(starts) length(ends)]);
    match=ends(1:m-1)>starts(2:m);
end

% ends=ends(2:end);

if length(starts) ~= length(ends)
    if length(starts) - 1 == length(ends)
        disp('Warning: One extra start code');  
        starts = starts(1:end-1);
    elseif length(ends) - 1 == length(starts)
        disp('Warning: One extra end code'); 
        ind_red=find(ends(1:end-1)-starts<0,1);
        starts(ind_red-1)=[];
        ends(ind_red-1:ind_red)=[];
    else
        error('Something is wrong: Different trial start and end counts');
        disp(length(starts))
        disp(length(ends))
    end
end

if sum((ends-starts)<0) > 0
    error(['Something is wrong: some trial starts are after the ' ...
        'corresponding ends']);
end

trials = cell(length(starts),1);
s=length(starts);
for i = 1:length(starts)
    if mod(i,100)==0
        disp(['Processing trial ' num2str(i) ' out of ' num2str(s)]);
    end
    
    trial = struct();
    startTime = codes(starts(i),2);
    endTime = codes(ends(i),2);
    trial.startTime = startTime;
    trial.endTime = endTime;
    
    trial.spikes = nev(nev(:,3) > startTime & nev(:,3) < endTime,:);
    trial.codes = codes(starts(i):ends(i),:);
    
    trial.spikes(:,3) = trial.spikes(:,3) - startTime;
    trial.codes(:,2) = trial.codes(:,2) - startTime;
    cdid=trial.codes(:,1);
    cdtime=trial.codes(:,2);
    cdstimtimes=cdtime(cdid==10);
    cdofftimes=cdtime(cdid==40);  
    
    %now, we will pull in continuous signals (diode, eyes)
    % 05/02/14  as of now, i am not relying on the diode at this point.
    % i am just saving the snippet and making a simple threshold
    % calculation 
     if nargin > 1  
        numstim=length(cdstimtimes);
        trial.stimStart=nans(numstim,1);

        trial.eyeX = analogSignals.eyeX(round(trial.startTime*1000):round(trial.endTime*1000));
        trial.eyeY = analogSignals.eyeY(round(trial.startTime*1000):round(trial.endTime*1000));
        trial.pupil = analogSignals.pupil(round(trial.startTime*1000):round(trial.endTime*1000));
        trial.oneKHzXval = analogSignals.xVals(round(trial.startTime*1000):round(trial.endTime*1000)); 
        trial.Diodeval = analogSignals.diodeData(round(trial.startTime*30000):round(trial.endTime*30000));
        trial.ThirtyKHzXval = analogSignals.diodeXvals(round(trial.startTime*30000):round(trial.endTime*30000));
        trial.stimstart=cdstimtimes;    
     end    
    
     trial.stimstart=cdstimtimes;
     
    cndIndex = find(trial.codes(:,1)>32768);
    trial.cnd = trial.codes(cndIndex,1)-32768;
    trial.codes(cndIndex,:) = [];
    trial.channels = channels;
    trial.sortInd=sortInd;
    trial.sortedChannels=sortedChannels;
    msgInd = trial.codes(:,1) >= 256 & trial.codes(:,1) < 512;
    trial.msgs = char(trial.codes(msgInd,1)-256)';
    trial.msgs(trial.msgs=='$') = '';
    variables = regexp(trial.msgs,';','split');
    for j = 1:length(variables)
        
        % Initialize boolean flag that will determine whether this variable
        % is ultimately appended to the structure
        AppendVariable = true;
        
        % Split the variable assignment string at the '=' point
        StringParts = regexp(variables{j},'=','split');
 
        switch numel(StringParts)
            
            case 1
                % Deals with cases in such as 
                % 1) VariableName=(null) [append varaible with empty array]
                % 2) (null)              [do not append variable]
                VariableName = StringParts{1};
                VariableValue = '[]';
                
                if isempty(VariableName)
                    AppendVariable = false;
                end
                
            case 2
                % The variable assignment string appears to have a vaild
                % format. Make sure that the value is enclosed in brackets
                % in case the variable is an array.
                VariableName = StringParts{1};
                
                % If the string contains any non-numeric symbols, enclose
                % it in single quotes. If all symbols are numeric, enclose
                % it in brackets
                if any(~ismember(double(StringParts{2}),NumericSet))
                    VariableValue = ['''', StringParts{2},''''];
                else
                    VariableValue = ['[', StringParts{2},']'];
                end
               
                
            otherwise
                
                disp('message string has bizzare format!');
                disp([StringParts{:}]);
           
        end
        
        if AppendVariable
            try
                eval(['trial.', VariableName,'=', VariableValue, ';']);
            catch
                disp(['trial.', VariableName,'=', VariableValue, ';'])
                if ~warnVarFlag
                    disp(['Could not parse variable name: ',variables{j}]);
                    disp(['No more warnings of this type will be displayed']);
                    warnVarFlag = 1;
                end
            end
        end
    end
%     trial.outcome=cdid(cdid>=150 & cdid<160);
%     if length(trial.outcome)>1,
%         disp(['Warning: more than one outcome on trial' num2str(i)]);
%     end

trial.fixmove=cdtime(cdid==4); % remove this? put in something more useful???
trial.stimend = cdofftimes;
trial.fixate=cdtime(cdid==140);
   
trials{i} = trial;
end

