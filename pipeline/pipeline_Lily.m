clear; clc
% addpath('neuroshare')      
% addpath('matlabtools/neuroshare/')
fn = 'C:\Users\Cohen Lab\Documents\Data\240701\testustim_0107240001';
% fn = 'Z:\Ram\data\neural\v4-7a\231208\zippy_imgMap_231208-115220';
% fn = '/Volumes/Colada/Lily/Zippy/230803/230803zones0001';
% fn = '/Users/lily/Desktop/pipelinecode/NeuralDataZippy/230913/230913redZones3x30002';
pipeline_test_fn(fn);
% trials = cell2mat(pipeline_test_fn(fn));
% load('230824_trialinfo.mat')
% trials = cell2mat(trials);
% trials = trials([trials.good]==1);
%trials.msgs(trials.msgs=='$') = '';


%%
trials = cell2mat(trials);
trials = trials([trials.good]==1);
chid = trials(1).channels(:,1);
% renumber = find(chid>128);
% chid(renumber) = chid(renumber)-96;
resp = nan(length(trials),length(chid));
for ii=1:length(trials)
    resp(ii,:) = arrayfun(@(jj) sum(trials(ii).spikes(:,1)==chid(jj)),1:length(chid));
end

chan7a=1:64;
V4chan=65:128;
% 
% % chan7a=[1 3 4];
% % V4chan=[];
% 
%     channels=V4chan;
%     listBad=[];
%     for unit=1:length(V4chan)
%         thisUnit=V4chan(unit);
%         tmp=resp(:,thisUnit);
%         z=zscore(tmp);
%         bad=find(abs(z)>3);
%         listBad=[listBad; bad];
%     end
%     uniqueBad=unique(listBad);
%     for i=1:length(uniqueBad)
%         thisBad=uniqueBad(i);
%         numBadChannels(i)=sum(listBad==thisBad);
%     end
% 
%     tmp2=find(numBadChannels>(length(V4chan)/2));
%     badTrialsV4=uniqueBad(tmp2);
% 
%     goodTrialsV4=ones(1,length(alltrialsnormal));
%     goodTrialsV4(badTrialsV4)=0;

% STA v4
[pos,~,grp] = unique([[trials.x]' [trials.y]' [trials.s]'],'rows');
pos(:,3) = pos(:,3); %*10;

x = unique(pos(:,1));
y= flipud(unique(pos(:,2)));

mResp = groupsummary(resp,grp,'mean');
rf = getRF_sta(mResp,pos);

%%

figure('name','7a'); set(gcf,'color','w','pos',[147,155,1072,642]); 
ha = tight_subplot(6,12,0.02,0.02,0.02);
for ii=1:64 % numchannels on each array
    chan = chan7a(ii);
    imagesc(rf.x(:),rf.y(:),rf.sta(:,:,chan),'parent',ha(ii));
    % could be useful to plot example waypoints on top of RF maps later
    % but how to scale size>>?
    hold(ha(ii),'on');
    axis(ha(ii),'image','off');
    set(ha(ii),'ydir','normal');
    plot(0,0,'w.','parent',ha(ii),'markersize',10);
    set(ha(ii),'xTickLabel',x);
    set(ha(ii),'yTickLabel',y);


end

figure('name','V4'); set(gcf,'color','w','pos',[147,155,1072,642]); 
ha = tight_subplot(6,12,0.02,0.02,0.02);
for ii=1:64 % numchannels on each array
    chan = V4chan(ii);
    imagesc(rf.x(:),rf.y(:),rf.sta(:,:,chan),'parent',ha(ii));
    % could be useful to plot example waypoints on top of RF maps later
    % but how to scale size>>?
    hold(ha(ii),'on');
    axis(ha(ii),'image','off');
    set(ha(ii),'ydir','normal');
    plot(0,0,'w.','parent',ha(ii),'markersize',10);
    set(ha(ii),'xTickLabel',x);
    set(ha(ii),'yTickLabel',y);


end


%%

function trials = pipeline_test_fn(FileName)
    exist([FileName '.nev'],'file')
    % open up nev file (this function may need to be compiled)
    nev=readNEV( [FileName '.nev']);
    
    % renumber channels (keep this!!)
    renumber = find(nev(:,1)> 128); % reset channels coming from B bank (starts at 129) to be 33-128;
    nev(renumber,1) = nev(renumber,1) - 96;
    
    %dar added continuous signal extraction
    %extract the eye signals (x and y), pupil signal, and diode trace
    %extract_all_data is recommended because it correctly handles paused files
    [analogSignals.xVals, analogSignals.eyeX] = extract_all_data('Analog 1k', 10241, [FileName '.ns2']);
    analogSignals.xVals = analogSignals.xVals';
    [~, analogSignals.eyeY] = extract_all_data('Analog 1k', 10242, [FileName '.ns2']);
    %dar added diode extraction
    [analogSignals.diodeXvals, diodeData] = extract_all_data('Analog 30k', 10244, [FileName '.ns5']);
    analogSignals.diodeData = diodeData';
    %pupil
    [~, analogSignals.pupil] = extract_all_data('Analog 1k', 10243, [FileName '.ns2']);
%     
%     %get and save the behavioral and physiology data
    trials = gettrialinfo(nev, analogSignals); 
%         trials = gettrialinfo(nev); 

%     removethese = [154 303 447 601 755 908 1205];
%     trials(removethese,:)=[];%this removes the trials that don't match the other schemas for plotting PSTHs
   
    %dar added microsaccade detection code
%     [trials] = detectEyeMvmt_texform(trials);
    
    thisname=[FileName '_trialinfo.mat'];
    save(thisname,'trials','FileName')
    

end