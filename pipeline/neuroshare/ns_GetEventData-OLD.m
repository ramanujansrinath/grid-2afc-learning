function [ns_RESULT, TimeStamp, Data, DataSize] = ...
    ns_GetEventData(hFile, EntityID, Index)
% ns_GetEventData - Retrieves event data by index
% Usage:
% [ns_RESULT, TimeStamp, Data, DataSize] =...
%                        ns_GetEventData(hFile, EntityID, Index)
% Description:
% 
% Returns the data values from the file referenced by hFile and the Event 
% Entity EntityID.  The Event data entry specified by Index is written to 
% Data and the timestamp of the entry is returned to TimeStamp.  
% Upon return of the function, the value at DataSize contains the number of
% bytes actually written to Data.
%
% Parameters:
%
% hFile               Handle/Identification number to an open file.
% EntityID            Identification number of the entity in the data file.
% Index               The index number of the requested Event data item.
%
% Return Values:
% 
% TimeStamp           Variable that receives the timestamp of the Event 
%                     data item.
%
% Data                Variable that receives the data for the Event entry.
%                     The format of data is specified by the member 
%                     EventType in ns_EVENTINFO.
%
% DataSize            Variable that receives the actual number of bytes of 
%                     data retrieved in the data buffer.
%
% ns_RESULT           This function returns ns_OK if the file is 
%                     successfully opened. Otherwise one of the following 
%                     error codes is generated:
%
% ns_BADFILE          Invalid file handle passed to function
% ns_BADENTITY        Invalid or inappropriate entity identifier specified
% ns_BADINDEX         Invalid entity index specified
% ns_FILEERROR        File access or read error

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

TimeStamp = [];
Data = [];
DataSize = [];
if ~isstruct(hFile)
    ns_RESULT = 'ns_BADFILE';
    return
end

%check Entity
if ~(isnumeric(EntityID))||...
    (uint16(EntityID)~=EntityID)||...
    (EntityID > length(hFile.Entity))||...
    (EntityID < 1)||...
    ~strcmp(hFile.Entity(EntityID).EntityType, 'Event')
    ns_RESULT = 'ns_BADENTITY';
    return
end

% check Index
if Index<1||Index>hFile.Entity(EntityID).Count
    ns_RESULT = 'ns_BADINDEX';
    return
end

ns_RESULT = 'ns_OK';
DataSize = 2;
% construct the fileInfo structure for the specifies entityID
fileInfo = hFile.FileInfo(hFile.Entity(EntityID).FileType);
% Cell array of Packet Reasons
packetReason = {'Digital Input',...
                        'Input Ch 1',...
                        'Input Ch 2',...
                        'Input Ch 3',...
                        'Input Ch 4',...
                        'Input Ch 5'};
% find the packet reason and get its index in the packetReason cell array.
% get all of the events for the specified entityID. get the TimeStamp of
% the index of the event for the specified entityID. skip to the data for
% the event in the nev file. read out the data. If Packet Reason is
% 'Digital Input' read data as uint16, else read it as int16.
idx = find(strcmp(packetReason,  hFile.Entity(EntityID).Reason));
eventClass = fileInfo.MemoryMap.Data.Class(...
    fileInfo.MemoryMap.Data.PacketID == 0);
posEvent = find(bitget(eventClass,idx), Index);
TimeStamp = double(fileInfo.MemoryMap.Data.TimeStamp(posEvent(end)))/30000;
offset = fileInfo.BytesHeaders +...
    fileInfo.BytesDataPacket *...
    (posEvent(end)-1) +...
    8 + (idx-1)*2;
fseek(fileInfo.FileID, offset, -1);
if idx == 1
    Data = fread(fileInfo.FileID, 1, '*uint16');
else
    Data = fread(fileInfo.FileID, 1, '*int16');
end


