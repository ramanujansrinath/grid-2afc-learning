clc; clear; close all

addpath('dep')
mapRecord = crawlForFiles;
dataLoc = '~/Downloads/v4-7a';
mapRecord(15) = [];

%% get/parse all data
for ii=1:length(mapRecord)
    exptName = mapRecord(ii).path(1+find(mapRecord(ii).path=='/',1,'last'):end);
    disp(exptName)
    if ~exist([dataLoc '/' exptName '_dense.mat'],'file')
        disp('... getting remote')
        load([mapRecord(ii).path '_trialinfo'])
        load(mapRecord(ii).path)
        
        clearvars params resp resp_base
        for tt=1:length(trials)
            if trials{tt}.good
                params(tt).set = trials{tt}.set;
                params(tt).num = trials{tt}.num;
                params(tt).x = trials{tt}.x;
                params(tt).y = trials{tt}.y;
                params(tt).s = trials{tt}.s;
                params(tt).good = trials{tt}.good;
                params(tt).spikes = trials{tt}.spikes(:,[1 3]);
                params(tt).spikes(:,2) = params(tt).spikes(:,2)-trials{tt}.stimstart;
    
                sp = params(tt).spikes(:,1);
                t_sp = params(tt).spikes(:,2);
    
                respDur = trials{tt}.stimend-trials{tt}.stimstart;
                respLims = [0.05 respDur];
                baseLims = [-0.1 0];
                
                sp_idx = t_sp > baseLims(1) & t_sp < respLims(2); % find all spikes in the window
                sp_ch = sp(sp_idx); % the channels the spikes were on
                [sp_ch,idx] = sort(sp_ch); % sort by channel
                sp_ts = t_sp(sp_idx); % get spike timestamps (in s)
                sp_ts = sp_ts(idx); % sort in the same way as channels
                
                params(tt).resp      = histcounts(sp_ch(sp_ts > respLims(1)),0.5:1:128.5)/respDur;
                params(tt).resp_base = histcounts(sp_ch(sp_ts < baseLims(2)),0.5:1:128.5)/0.1;
                
                resp(tt,:) = params(tt).resp;
                resp_base(tt,:) = params(tt).resp_base;
            end
        end

        save([mapRecord(ii).path '_dense'],'params','resp','resp_base')
        save([dataLoc '/' exptName '_dense.mat'],'params','resp','resp_base')
    else
        load([dataLoc '/' exptName '_dense.mat'],'params','resp','resp_base')
    end

    mapRecord(ii).name = exptName;
    mapRecord(ii).nTrials = length(params);
    mapRecord(ii).nCorrect = sum([params.good]);
    mapRecord(ii).set = unique([params.set]);
    mapRecord(ii).num = unique([params.num]);
    mapRecord(ii).x = unique([params.x]);
    mapRecord(ii).y = unique([params.y]);
    mapRecord(ii).s = unique([params.s]);
    mapRecord(ii).rfPos = [];
    
    % if actual rf map expt, save the RFs
    if length(unique([params.x]))>1
        if ~exist([dataLoc '/' exptName '_rf.mat'],'file')
            disp('... saving rf')
            rfv4 = rfmap_save(params,resp);
            save([dataLoc '/' exptName '_rf.mat'],'rfv4')
        else
            load([dataLoc '/' exptName '_rf.mat'],'rfv4')
        end
        % rfmap_plot(rfv4)
        mapRecord(ii).rfPos = rfv4.pos;
    end
end
save('data/mapRecord.mat','mapRecord')
% mapRecord = mapRecord([mapRecord.nTrials]>100);

%%
load([dataLoc '/' mapRecord(26).name '_rf.mat'],'rfv4')
rfmap_plot(rfv4)

%% helpers
function rfv4 = rfmap_save(params,resp)    
    eid = [3*ones(1,32) ones(1,64) 3*ones(1,32)];
    badTrials = cellfun(@isempty,{params.set});
    resp(badTrials,:) = [];
    params(badTrials) = [];

    resp(~[params.good],:) = [];
    params(~[params.good]) = [];
    v4sites = resp(:,eid == 1);

    % STA v4
    [pos,~,grp] = unique([[params.x]' [params.y]' [params.s]'],'rows');
    mResp = groupsummary(v4sites,grp,'mean');
    rfv4 = getRF_sta(mResp,pos,zeros(1,64));
    xx = median(rfv4.staFit_beta(:,2));
    yy = median(rfv4.staFit_beta(:,4));
    rr(1) = median(abs(rfv4.staFit_beta(:,3)));
    rr(2) = median(abs(rfv4.staFit_beta(:,5)));
    rr = min(rr)/2;
    rfv4.pos = [xx yy rr];
    rfv4.posDeg = rad2deg(atan(([xx yy rr]*(609.6/sqrt(1920^2 + 1080^2)))/540));
end

function rfmap_plot(rfv4)
    pos = [375 -200 400];
    % pos = [-274 -198 340];
    stimPos = [pos(1)-pos(3)/2 pos(2)-pos(3)/2 pos(3) pos(3)];

    figure('color','w','pos',[147,86,754,711]); 
    ha = tight_subplot(8,8,0.02,0.02,0.02);
    for ii=1:64
        imagesc(rfv4.x(:),rfv4.y(:),rfv4.sta(:,:,ii),'parent',ha(ii));
        hold(ha(ii),'on');
        axis(ha(ii),'image','off');
        set(ha(ii),'ydir','normal');
        plot(0,0,'w.','parent',ha(ii),'markersize',10);
        rectangle('Position',stimPos,'LineWidth',2,'EdgeColor','w','parent',ha(ii))
%         drawellipse(ha(ii),'center',rfv4.staFit_beta(ii,[2 4]),'SemiAxes',abs(rfv4.staFit_beta(ii,[3 5])/2),'Color','k','facealpha',0,'InteractionsAllowed','none','selected',false,'linewidth',1);
    end
    
    figure('color','w','pos',[909,350,254,445]);
    ha = tight_subplot(2,1); axes(ha(1))
    imagesc(rfv4.x(:),rfv4.y(:),mean(rfv4.sta,3));
    axis image; set(gca,'ydir','normal'); hold on;
    plot(0,0,'k.','parent',gca,'markersize',10);
    rectangle('Position',stimPos,'LineWidth',2,'EdgeColor','w')
    axis([-200 960 -540 200])
    title(['V4: pix ' num2str(round(rfv4.pos))])
    
    axes(ha(2)); 
 
    % clf; hold on;
    for ii=1:64
        plot(gca,rfv4.staFit_beta(ii,2),rfv4.staFit_beta(ii,4),'.','markersize',15,'color',[0.2 0.9 0.3]*0.8);
        drawellipse(gca,'center',rfv4.staFit_beta(ii,[2 4]),'SemiAxes',abs(rfv4.staFit_beta(ii,[3 5])/2),'Color',[0.2 0.9 0.3],'facealpha',0,'InteractionsAllowed','none','selected',false,'linewidth',1,'edgealpha',0.5);
    end
    plot(0,0,'r.','markersize',20);
    rectangle('Position',stimPos,'LineWidth',2,'EdgeColor','k')
    axis([-200 960 -540 200])
   
    rectangle('Position',[rfv4.pos(1)-rfv4.pos(3) rfv4.pos(2)-rfv4.pos(3) rfv4.pos(3)*2 rfv4.pos(3)*2],'LineWidth',2,'EdgeColor','b')
    
    % get 5 degree ticks
    ticks = 5*(200./rad2deg(atan((200*(609.6/sqrt(1920^2 + 1080^2)))/540)));
    fixPlot(gca,[-200 800],[-500 200],'','',-4*ticks:ticks:ticks*4,-4*ticks:ticks:ticks*4)
    axis normal
    axis equal
end


function mapRecord = crawlForFiles
    filelist = cell(1);
    rootDir = '/Volumes/colada/Ram/data/neural/v4-7a';
    dirs = dir([rootDir '/24*']);
    for ii=1:length(dirs)
        files_grid = dir([rootDir '/' dirs(ii).name '/*map*trial*']);
        filelist = [filelist cellfun(@(x) strrep([rootDir '/' dirs(ii).name '/' x],'_trialinfo.mat',''),{files_grid.name},'UniformOutput',false)];
        % if length(files_nev) ~= length(files_grid)
        %     for jj=1:length(files_nev)
        %         files_nev.name(jj)
        %     end
        % end
    end
    filelist(1) = [];
    mapRecord = cell2struct(filelist,'path',1);
end
