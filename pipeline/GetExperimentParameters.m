function [ ExperimentParameters , VariableList ] = GetExperimentParameters( nev )

TrialStartCode = 1;
NumericSet = double(unique([num2str(0:9),' ',',','.','-','e']));
EP = struct();
ExperimentParameters = struct();

% Get the part of the nev file that occurs before the first trial start
% code. This is the region that will contain the experiment parameters
% information.
CodesChannelIndex = nev(:,1) == 0;
CodesChannelArray = nev(CodesChannelIndex,:);

ParametersEndIndex = find(CodesChannelArray(:,2) == TrialStartCode,1,'first');
ParametersSegment = CodesChannelArray(1:ParametersEndIndex,2);
ParametersArray = char(ParametersSegment((ParametersSegment >= 256) & (ParametersSegment < 512)) - 256);

VariableList =  regexp(ParametersArray',';','split');

for VariableIDX = 1:length(VariableList)
    
    % Initialize boolean flag that will determine whether this variable
    % is ultimately appended to the structure
    AppendVariable = true;
    
    % Split the variable assignment string at the '=' point
    StringParts = regexp(VariableList{VariableIDX},'=','split');
    
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
            EP.(VariableName) = eval(VariableValue);
        catch
            disp(['trial.', VariableName,'=', VariableValue, ';'])
            disp(['Could not parse variable name: ',VariableList{VariableIDX}]);
            disp(['No more warnings of this type will be displayed']);
        end
    end
end


ExperimentParameters = EP;




end

