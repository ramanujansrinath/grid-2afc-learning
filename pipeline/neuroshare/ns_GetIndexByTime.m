function [ns_RESULT, Index] = ns_GetIndexByTime(hFile, EntityID, Time, Flag)
% ns_GetIndexByTime - Retrieves an entity index by time
% Usage:
% 
% [ns_RESULT, Index] = ns_GetIndexByTime(hFile, EntityID, Time, Flag)
% Description:
% 
% Searches in the file referenced by hFile for the data item identified by 
% the index EntityID.  The flag specifies whether to locate the data item 
% that starts before or after the time Time.  The index of the requested 
% data item is returned in Index.
% 
% Parameters:
% 
% hFile               Handle/Identification number to an open file.
% 
% EntityID            Identification number of the entity in the data file.
% 
% Time                Time of the data to search for
% 
% Flag                Flag specifying whether the index to be retrieved 
%                     belongs to the data item occurring before or after 
%                     the specified time Time.  The flags are defined:
% 
%                     Return the data entry occurring before          -1
%                     and inclusive of the time dTime.
% 
%                     Return the data entry occurring at or            0
%                     closest to the time dTime.
%
%                     Return the data entry occurring after and       +1
%                     inclusive of the time dTime.
%
% Return Values:
% 
% Index               Variable to receive the entry index. Index is a cell
%                     array Index Values.
% 
% ns_RESULT           This function returns ns_OK if the file is 
%                     successfully opened. Otherwise one of the following 
%                     error codes is generated:
% 
% ns_BADFILE          Invalid file handle passed to function
% 
% ns_BADENTITY        Invalid or inappropriate entity identifier specified
% 
% ns_FILEERROR        File access or read error
% 
% ns_BADINDEX         Unable to find an valid index

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     The Wisteria Neuroshare Importer is free software: you can 
%     redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     The Wisteria Neuroshare Importer is distributed in the hope that it 
%     will be useful, but WITHOUT ANY WARRANTY; without even the implied 
%     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
%     See the GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with the Wisteria Neuroshare Importer.  If not, see 
%     <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Index = [];

%check hFile
if ~isstruct(hFile)
    ns_RESULT = 'ns_BADFILE';
    return
end

%check Entity
if ~(isnumeric(EntityID))||...
    (EntityID > length(hFile.Entity))||...
    (EntityID < 1)||...
    (uint16(EntityID)~=EntityID)
    ns_RESULT = 'ns_BADENTITY';
    return
end
fileInfo = hFile.FileInfo(hFile.Entity(EntityID).FileType);

if Time<0||Time>(double(fileInfo.TimeSpan)/30000)
    ns_RESULT = 'ns_BADTIME';
    return
end
validFlags = [-1 0 1];
if ~any(Flag==validFlags)
    ns_RESULT = 'ns_BADFLAG';
    return
end


ns_RESULT = 'ns_OK';
TimeSamp = Time*30000/fileInfo.Period;

if strcmp(hFile.Entity(EntityID).EntityType, 'Analog')
    TimeList = [fileInfo.TimeStamps(1,:);(sum(fileInfo.TimeStamps))];
    idx = find(TimeList(2,:)+1-TimeSamp, 1); %pause index
    IndexList = [0,cumsum(fileInfo.TimeStamps(2:2:end-1))]+1;
    Index = IndexList(idx)+TimeSamp-TimeList(1,idx);
    if TimeList(1,idx)>TimeSamp %between pauses
        List = double([TimeList(2, idx-1), TimeList(1,idx)]);
        [rte, idx] = min(abs(List-TimeSamp)); %#ok<ASGLU>
        if ~Flag
            idx = max(1+Flag,1);
        end
        Index = List(idx);
    end
    return
elseif strcmp(hFile.Entity(EntityID).EntityType, 'Segment')
    TimeStamps = fileInfo.MemoryMap.Data.TimeStamp(...
        fileInfo.MemoryMap.Data.PacketID==...
        hFile.Entity(EntityID).ElectrodeID);
    [rte, Index] = min(abs(double(TimeStamps)-TimeSamp)); %#ok<ASGLU>
    if Flag&&(TimeStamps(Index)~=TimeSamp)
        Index = max(Index+Flag,1);
    end
    return
elseif strcmp(hFile.Entity(EntityID).EntityType, 'Event')
    packetReason = {'Digital Input',...
                            'Input Ch 1',...
                            'Input Ch 2',...
                            'Input Ch 3',...
                            'Input Ch 4',...
                            'Input Ch 5'};
    idx = find(strcmp(packetReason,  hFile.Entity(EntityID).Reason));
    eventClass = fileInfo.MemoryMap.Data.Class(...
        fileInfo.MemoryMap.Data.PacketID == 0);
    TimeStamps = fileInfo.MemoryMap.Data.TimeStamp(bitget(eventClass,idx));
    [rte, Index] = min(abs(double(TimeStamps)-TimeSamp)); %#ok<ASGLU>
    if Flag&&(TimeStamps(Index)~=TimeSamp)
        Index = max(Index+Flag,1);
    end
end
    
    
    