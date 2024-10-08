function [ns_RESULT, hFile] = ns_OpenFile(varargin)
% ns_OpenFile - Opens a neural data file
%
% Usage:
% [ns_RESULT, hFile] = ns_OpenFile('filename.ext')
% Returns hFile, a handle that contains information for one or more files 
% with the same base filename specified in the 'filename.txt' argument.
%
% [ns_RESULT, hFile] = ns_OpenFile('filename.ext', 'single')
% Returns hFile, a handle that contains information for only the exact file 
% specified in the 'filename.txt' argument.
%
% [ns_RESULT, hFile] = ns_OpenFile;
% Opens a file browser to graphically select a file.  Note that all
% files with the same base filename will be opened. For example, if you
% click on data001.nev, and data001.ns5 also exists in the same directory, 
% then the handle, hFile, will contain a handle to both data001.nev and 
% data001.ns5.
%
% [ns_RESULT, hFile] = ns_OpenFile('single');
% Opens a file browser to graphically select a file.  Only the exact file 
% specified in the 'filename.txt' argument will be opened, instead of all
% files with the same base filename.
%
% Description:
% Opens the file specified by the given filename and returns a file handle,
% hFile, that is used to access the opened file. hFile is a structure.
%
% Parameters:
% filename           A string that specifies the name of the file to open.
%
% single             A string containing the characters 'single' to switch
%                    the function from parsing all files with similar base 
%                    file names to parsing only the exact file specified.
%
% Return Values:
% hFile              A handle that contains information for one or more 
%                    files. hFile is passed as an argument to subsequent
%                    functions to extract entity and file information.
%                    Implemented as a MATLAB cell array; individual elements
%                    need not be accessed directly.
%
% ns_RESULT          This function returns one of the following status 
%                    codes:
%
%   ns_OK              The file was successfully opened. 
%   ns_TYPEERROR       Library unable to open file type
%   ns_FILEERROR       File access or read error
%
% Note:
% When ns_OpenFile opens a .nev file a cache file is created that holds the
% timestamps and packetIDs for the .nev file. This is memory mapped and the
% memory map object is passed to the file handle.
%
% Remarks:
% This function has to be called before any other Neuroshare function is called.
% All files are opened as read-only.  That is, no writing capabilities are 
% implemented. If the command succeeds in opening the file, the application 
% should call ns_CloseFile for each open file before terminating. If
% ns_CloseFile is not called before another file is opened, the file can
% only be closed using fclose('all');
%
% See also ns_OpenFile, ns_GetEntityInfo, ns_GetAnalogInfo,
% ns_GetAnalogData, ns_CloseFile

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
ns_RESULT = [];
hFile = [];
ext = '.n*';
% Checking input arguments for determining which file to load. 

% If there there are no input arguments OR there is one input argument and 
% the argument is 'single' then a file dialog is open and only the file 
% chosen is used in generating hFile. 

% If there is one input argument and it is a valid nsx/nev file (or base 
% file name) then all files with the same file name are used in generating 
% hFile. If there are 2 input arguments then the first must be a valid 
% nsx/nev file and the second must be 'single' and only the entered file is
% used in generating hFile. 
if      (nargin == 0) ...
    ||( (nargin == 1) && strcmpi(varargin{1}, 'single') )

    [fileName, pathname] = uigetfile( ...
    {'*.nev;*.ns*','All NEV and NSx file formats (*.nev,*.ns*)';},...
    'Nev/NSX Loader');
    % if nothing is found return
    if fileName==0
        return
    end
    flag = nargin;
    [pathname, name, extT] = fileparts(fullfile(pathname, fileName));
    
% file exists or arg is a recording name
elseif    ( ~isempty(dir(strcat(varargin{1}, '*')) ) ... 
        && ( (nargin==1) || ((nargin==2) && strcmpi(varargin{2}, 'single')) ) )
    [pathname, name, extT] = fileparts(varargin{1});
    flag = nargin-1;
else
    ns_RESULT = 'ns_FILEERROR';
    return
end

if flag
    ext = extT;
end

% returning a list of all the chosen files. 
files = dir(fullfile(pathname, [name ext]));
nFiles = length(files);
[fileNames{1:nFiles}] = deal(files.name);
[fileSizes{1:nFiles}] = deal(files.bytes);

% Defining initial values for hFile 
ns_RESULT = cell(nFiles, 1);
ns_RESULT(:,1) = {'ns_OK'};
hFile.Name = name;
hFile.FilePath = pathname;
hFile.TimeSpan = 0;
hFile.Entity = [];
for i = 1:nFiles
    fid = fopen(fullfile(pathname, fileNames{i}), 'rb');
    type = fileNames{i}(end-2:end); % file extension (nsx/nev)
    fileType = fread(fid, 8, '*char')';
    hFile.FileInfo(i).FileID = fid;
    hFile.FileInfo(i).Type = type;
    hFile.FileInfo(i).FileSize = fileSizes{i};
    hFile.FileInfo(i).FileTypeID = fileType;
    if strcmp(fileType, 'NEURALEV') % if nev file
        % skip: File Spec and Additional Flags header Information 
        fseek(fid, 4, 0);
        hFile.FileInfo(i).Label = 'neural events';
        hFile.FileInfo(i).Period = 1;
        hFile.FileInfo(i).BytesHeaders = fread(fid, 1, '*uint32');
        hFile.FileInfo(i).BytesDataPacket = fread(fid, 1, '*uint32');
        % skip: Time Resolution of Time Stamps, Time Resolution of Samples,
        % Time Origin, Application to Create File, and Comment field.
        fseek(fid, 312, 0);
        
        nExtendedHeaders = fread(fid, 1, '*uint32');
        % Get list of extended header PacketIDs: (there are 9 different nev
        % extended headers. Each have a 8 char array PacketID and each
        % extended header has 24 bytes of information with a total size of
        % 8+24=32 bytes. 
        PacketIDs = cellstr(fread(fid, [8, nExtendedHeaders],...
            '8*char=>char', 24)');
        % Get Index of NEUEVWAV extended headers.
        idxEVWAV = find(strcmp(PacketIDs, 'NEUEVWAV'));
        for j = 1:length(idxEVWAV)
            % seek to the next NEUEVWAV extended header from the begining
            % of the file. 
            fseek(fid, 344+(idxEVWAV(j)-1)*32, -1);
            hFile.Entity(j).FileType = i;
            hFile.Entity(j).EntityType = 'Segment';     
            
            % Adding these variables to the structure here though they
            % are not part of the Segment entities so that the Entity
            % structure always has the same variables in it.
            hFile.Entity(j).Reason = 0;
            hFile.Entity(j).Units = '';
            
            hFile.Entity(j).ElectrodeID = fread(fid, 1, '*uint16');
            % skip: Physical Connector
            fseek(fid, 2, 0);
            % scale factor should convert bits to microvolts
            hFile.Entity(j).Scale = fread(fid, 1, 'uint16')*10^-3;
            % skip: Energy Threshold, High Threshold, Low Threshold
            fseek(fid, 6, 0);
            hFile.Entity(j).nUnits = fread(fid, 1, '*uchar');
        end      
        nDataPackets = (hFile.FileInfo(i).FileSize-double(hFile.FileInfo(i).BytesHeaders))...
            /double(hFile.FileInfo(i).BytesDataPacket);
        % create file to hold nev Event information. This file is memory
        % mapped for fast retrieval. 
        cacheFileName = fullfile(pathname, strcat(name, '.cache'));
        if ~exist(cacheFileName, 'file')
            cacheID = fopen(cacheFileName, 'wb');
            fseek(fid, hFile.FileInfo(i).BytesHeaders, -1);
            % write timestamps to cache file
            fwrite(cacheID, fread(fid, nDataPackets,...
                '*uint32', hFile.FileInfo(i).BytesDataPacket-4), 'uint32');         
            fseek(fid, hFile.FileInfo(i).BytesHeaders + 4, -1);
            % write Packet ID to cache file
            fwrite(cacheID, fread(fid, nDataPackets,...
                '*uint16', hFile.FileInfo(i).BytesDataPacket-2), 'uint16');
            fseek(fid, hFile.FileInfo(i).BytesHeaders + 6, -1);
            % write Classification/Insertion Reason to cache file
            fwrite(cacheID, fread(fid, nDataPackets,...
                '*uint8', hFile.FileInfo(i).BytesDataPacket-1), 'uint8');
            fclose(cacheID);
        end
        % create memory map of cache file
        hFile.FileInfo(i).MemoryMap = memmapfile(cacheFileName,   ...
            'Format', {                               ...
            'uint32', [nDataPackets 1] 'TimeStamp';...
            'uint16', [nDataPackets 1] 'PacketID';...
            'uint8', [nDataPackets 1] 'Class'}, ...
            'Repeat', 1);
        % get a list of ElectrodesIDs that have a neural event
        uPacketID = unique(hFile.FileInfo(i).MemoryMap.Data.PacketID);
        % get list of all ElectrodeIDs
        allChan = [hFile.Entity.ElectrodeID];
        % Remove Entities that do not have neural events from the entity
        % list
        hFile.Entity =...
            hFile.Entity(1, ismembc(allChan, uPacketID(uPacketID~=0)));
        % Calculate the Timespan in 30khz
        hFile.FileInfo(i).TimeSpan =...
            double(hFile.FileInfo(i).MemoryMap.Data.TimeStamp(end));
        % update hFile TimeSpan if necessary
        if hFile.TimeSpan < hFile.FileInfo(i).TimeSpan
            hFile.TimeSpan = hFile.FileInfo(i).TimeSpan;
        end

        % get number of occurences of each ElectrodeID in nev file
        Count = arrayfun(@(x)...
            {sum(hFile.FileInfo(i).MemoryMap.Data.PacketID == x)},...
            [hFile.Entity.ElectrodeID]);
        [hFile.Entity.Count]=Count{:};

        % get all digital event information
        if ~uPacketID(1)
            eventClass = hFile.FileInfo(i).MemoryMap.Data.Class(...
                hFile.FileInfo(i).MemoryMap.Data.PacketID == 0);
            packetReason = {'Digital Input',...
                            'Input Ch 1',...
                            'Input Ch 2',...
                            'Input Ch 3',...
                            'Input Ch 4',...
                            'Input Ch 5'};
            EC = length(hFile.Entity);
            k = EC+1;
            
            for j = 1:6
                Count = sum(bitget(eventClass, j));
                if Count
                    hFile.Entity(k).FileType = i;
                    hFile.Entity(k).EntityType = 'Event';
                    hFile.Entity(k).Reason =...
                        packetReason{j};
                    hFile.Entity(k).Count = Count;
                    hFile.Entity(k).ElectrodeID = uint16(0);
                    k=k+1;
                end
            end
        end
        hFile.FileInfo(i).ElectrodeList = [hFile.Entity.ElectrodeID];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Setup Neural Entities
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Setup of 'Entity' struct held by the Neuroshare hFile
        % This needs to match the struct array in hFile.Entity
        NeuralData = struct('ElectrodeID', 0, 'EntityType', 'Neural',...
             'Reason', -1, 'Count', 0, 'Scale', 1, 'Units', '', ...
             'nUnits', 0, 'FileType', i);
        % Get a list of all unique neural entities that have been found
        classList = ...
            sort(unique(hFile.FileInfo(i).MemoryMap.Data(:).Class));
        % Find out how many unique electrodes and classes we have
        nElectrode = length(hFile.FileInfo(i).ElectrodeList);
        nClass = length(classList);
        % create space for the Neural entities.  This array will be put
        % at the end of the hFile.Entity after the Analog entities if 
        % count > 0
        neuralEntities = ...
            repmat(NeuralData, nElectrode*nClass, 1);
        % Create an entity for each possible electrode and class.  A given
        % electrode and class is mapped to it's electrode id and class by
        % index = electrode_index + class_index*nElectrodes
        for iEntity=1:nElectrode
            elecID = hFile.FileInfo(i).ElectrodeList(iEntity);
            indices = ...
                logical(hFile.FileInfo(i).MemoryMap.Data.PacketID==elecID);
            classes = hFile.FileInfo(i).MemoryMap.Data.Class(indices);
            for iClass=1:nClass
                class = classList(iClass);
                neuralIndex = iEntity + (iClass-1)*nElectrode;
                neuralEntities(neuralIndex).ElectrodeID = elecID;
                neuralEntities(neuralIndex).Reason = class;
                neuralEntities(neuralIndex).Count = sum(classes==class);
            end
        end        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is an older version of this that turned out to be extremely slow
% for longer files with many electrode ids.
%         for iEntity=1:length(hFile.FileInfo(i).MemoryMap.Data.PacketID)
%             elecID = hFile.FileInfo(i).MemoryMap.Data.PacketID(iEntity);
% %             timestamp = ...
% %                 hFile.FileInfo(i).MemoryMap.Data(iEntity).timestamp;
%             class = hFile.FileInfo(i).MemoryMap.Data.Class(iEntity);
%             if elecID > 0
%                 fileIndex = ...
%                     find(hFile.FileInfo(i).ElectrodeList==elecID, 1);
%                 classIndex = find(classList==class, 1);
%                 neuralIndex = fileIndex + (classIndex-1)*nElectrode;
%                 neuralEntities(neuralIndex).Count ...
%                     = neuralEntities(neuralIndex).Count + 1;
%             end
%         end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Remove all entities that were not represented in the data.  Now
        % We hold on to this array until AFTER all NSx files are read.
        neuralEntities = ...
            neuralEntities(find([neuralEntities(:).Count]>0));
    elseif strcmp(fileType, 'NEURALSG') %nsx 2.1
        hFile.FileInfo(i).Label = deblank(fread(fid, 16, '*char')');
        hFile.FileInfo(i).Period = fread(fid, 1, 'uint32');
        chanCount = fread(fid, 1, 'uint32');
        hFile.FileInfo(i).ElectrodeList = fread(fid, chanCount, '*uint32');
        hFile.FileInfo(i).BytesHeaders = ftell(fid);
        EC = length(hFile.Entity);
        % calculate the number of data points
        nDataPoints = (hFile.FileInfo(i).FileSize...
            - hFile.FileInfo(i).BytesHeaders)/(2*chanCount);
        for j = EC+1:EC + chanCount
            hFile.Entity(j).FileType = i;
            hFile.Entity(j).EntityType = 'Analog';
            hFile.Entity(j).ElectrodeID =...
                hFile.FileInfo(i).ElectrodeList(j-EC);
            hFile.Entity(j).Scale = 1;
            hFile.Entity(j).Units = 'V';
            hFile.Entity(j).Count = nDataPoints;
        end
        % store timeStamp and number of points in each packet
        hFile.FileInfo(i).TimeStamps = [0; nDataPoints];
        % calculate time span
        hFile.FileInfo(i).TimeSpan = nDataPoints*hFile.FileInfo(i).Period;
        % update timespan if necessary
        if hFile.TimeSpan < hFile.FileInfo(i).TimeSpan
            hFile.TimeSpan = hFile.FileInfo(i).TimeSpan;
        end
    elseif strcmp(fileType, 'NEURALCD') %nsx 2.2
        % skip: File Spec
        fseek(fid, 2, 0);
        hFile.FileInfo(i).BytesHeaders = fread(fid, 1, '*uint32');
        hFile.FileInfo(i).Label = deblank(fread(fid, 16, '*char')');
        % skip: Comment
        fseek(fid, 256, 0);
        hFile.FileInfo(i).Period = fread(fid, 1, 'uint32');
        % skip: Time Resolution of Time Stamps and Time Origin
        fseek(fid, 20, 0);
        chanCount = fread(fid, 1, 'uint32');
        EC = length(hFile.Entity);
        % get information from extended header
        for j = EC+1:EC + chanCount
            hFile.Entity(j).FileType = i;
            hFile.Entity(j).EntityType = 'Analog';
            % skip: Type
            fseek(fid, 2, 0);
            hFile.Entity(j).ElectrodeID = fread(fid, 1, '*uint16');
            % skip: Electrode Label, Physical connector, Connector pin
            fseek(fid, 18, 0);
            % read Min/Max Digital and Min/Max Analog values
            analogScale = fread(fid, 4, 'int16');
            hFile.Entity(j).Scale =...
                (analogScale(4)-analogScale(3))/...
                (analogScale(2)-analogScale(1));
            hFile.Entity(j).Units = fread(fid, 16, '*char')';
            % skip: High/Low Freq Corner, High/Low Freq Order, Hight/Low
            % Filter Type
            fseek(fid, 20, 0);
        end
        hFile.FileInfo(i).ElectrodeList =...
            [hFile.Entity(EC+1:EC + chanCount).ElectrodeID];

        fseek(fid, hFile.FileInfo(i).BytesHeaders, -1);
        hFile.FileInfo(i).TimeStamps = [];
        while(ftell(fid)<hFile.FileInfo(i).FileSize)
            % skip Data Packet header
            % store timeStamps and number of points in each packet
            fseek(fid, 1, 0);
            timeStamps = fread(fid, 1, 'uint32')/hFile.FileInfo(i).Period;
            nPoints = fread(fid, 1, 'uint32');
            
            if ~isempty(timeStamps) && ~isempty(nPoints)
            hFile.FileInfo(i).TimeStamps =...
                [hFile.FileInfo(i).TimeStamps,...
                [timeStamps;nPoints]];
            fseek(fid, 2*double(nPoints)*chanCount, 0);
            else
                disp('NS_OpenFile empty time stamps WARNING')
            end
        end
        % get number of points of each Entity
        [hFile.Entity(EC+1:EC + chanCount).Count] =...
            deal(double(sum(hFile.FileInfo(i).TimeStamps(2,:))));
        % calculate time span
        hFile.FileInfo(i).TimeSpan =...
            (sum(hFile.FileInfo(i).TimeStamps(:,end)))*...
            hFile.FileInfo(i).Period;
        % update timespan if necessary
        if hFile.TimeSpan <hFile.FileInfo(i).TimeSpan
            hFile.TimeSpan = hFile.FileInfo(i).TimeSpan;
        end
    else % if no valid File Type ID, output fileError 
        ns_RESULT(i) = {'ns_FILEERROR'};
        continue;
    end
    hFile = orderfields(hFile);
end
% cat the neural entities to the end of the entity list.
hFile.Entity = [hFile.Entity(:); neuralEntities];
if any(strcmp(ns_RESULT, 'ns_OK'))
    ns_RESULT = 'ns_OK';
else
    hFile = [];
    ns_RESULT = 'ns_FILEERROR';
end
