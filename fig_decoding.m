%% prelim
load('data/exptRecord.mat')
sessIds = [20,23,26,27,28,31,35,39,42,48,49,50,51,52,54,55,56];
exptRecord = exptRecord(sessIds);
exptRecord = exptRecord([exptRecord.nCorrect]>100);
% exptRecord = exptRecord(cellfun(@(x) length(x)==25,{exptRecord.stimOpp_num}) & cellfun(@(x) length(x)==25,{exptRecord.stimRF_num}));
% exptRecord = exptRecord(randi(length(exptRecord)));

for ii=1:length(exptRecord)
    disp('++++++++++++++++++++++++++++++++++++')
    disp([num2str(ii) ': ' exptRecord(ii).name])
    load(['~/Downloads/v4-7a/' exptRecord(ii).name '_dense.mat'],'params','resp','resp_base')
    % r(ii,:) = prelim2_grid_2afc(params,resp,resp_base,0);
    r_sess(:,:,ii) = prelim5_grid_2afc(params,resp,resp_base);
end

%% boxplots
figure('pos',[1000,319,601,919],'color','w'); clf
titleStr = {{'shape decoder' 'across tasks'} {'color decoder' 'across tasks'} {'shape decoder' 'shape task'} {'color decoder' 'shape task'} {'shape decoder' 'color task'} {'color decoder' 'color task'}};
for ii=1:6
    subplot(3,2,ii); 
    notBoxPlot([squeeze(r_sess(ii,1,:)),squeeze(r_sess(ii,2,:)),squeeze(r_sess(ii,3,:))]); 
    fixPlot(gca,[0 4],[-0.2 1],'','decoding accuracy',1:3,0:0.25:1,titleStr{ii})
    set(gca,'XTickLabel',{'shape' 'color' 'choice'})
end

%% scatters
figure('pos',[1616,930,601,308],'color','w');
subplot(121)
line([0 1],[0 1],'linestyle','--','color','k','linewidth',2); hold on;
plot(squeeze(r_sess(3,1,:)),squeeze(r_sess(5,1,:)),'.','markersize',18);
plot(squeeze(r_sess(3,2,:)),squeeze(r_sess(5,2,:)),'.','markersize',18);
plot(squeeze(r_sess(3,3,:)),squeeze(r_sess(5,3,:)),'.','markersize',18);
fixPlot(gca,[-0.2 1],[-0.2 1],'shape task trials','color task trials',0:0.25:1,0:0.25:1,'shape decoder performance')
% legend('Location','northwest')

subplot(122)
line([0 1],[0 1],'linestyle','--','color','k','linewidth',2); hold on;
plot(squeeze(r_sess(4,1,:)),squeeze(r_sess(6,1,:)),'.','markersize',18);
plot(squeeze(r_sess(4,2,:)),squeeze(r_sess(6,2,:)),'.','markersize',18);
plot(squeeze(r_sess(4,3,:)),squeeze(r_sess(6,3,:)),'.','markersize',18);
fixPlot(gca,[-0.2 1],[-0.2 1],'shape task trials','color task trials',0:0.25:1,0:0.25:1,'color decoder performance',{'' 'shape decoding' 'color decoding' 'choice decoding'})
legend('Location','southeast')


%%
function r_sess = prelim5_grid_2afc(params,resp,resp_base)
    diagStimNum = [5 9 13 17 21];
    diagTrials = ismember([params.stimRF_num],diagStimNum) & ismember([params.stimOpp_num],diagStimNum);
    colorTrials = (mod([params.stimRF_num],5)-mod([params.stimOpp_num],5)) == 0;
    shapeTrials = ~colorTrials;
    colorTrials = colorTrials & ~diagTrials; % & ~offDiagTrials;
    shapeTrials = shapeTrials & ~diagTrials; % & ~offDiagTrials;
    
    colorDiff = colorTrials;
    % colorDiff = (mod([params.stimRF_num],5)-mod([params.stimOpp_num],5)) == 0;
    eid = [3*ones(1,32) ones(1,64) 3*ones(1,32)];
    resp = resp(:,eid==1);
    resp_base = resp_base(:,eid==1);
    good = mean(resp)>1.1*mean(resp_base); % true(1,size(resp,2));
    resp = resp(:,good);

    resp_red = pca(resp','NumComponents',10);
    
    stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(1:5,1,5))];
    colIds = stimVals([params.stimRF_num],1);
    shpIds = stimVals([params.stimRF_num],2);
    choices = [params.selected]';
    
    % the seemingly random shuffling after r gets assigned
    % is to format it in the way that i will plot it later.
    % it's silly.

    % all trials
    r = get_dec(resp_red,shpIds,resp_red,colIds,resp_red,choices); r_sess([1 2 3]) = r;
    r = get_dec(resp_red,colIds,resp_red,shpIds,resp_red,choices); r_sess([5 4 6]) = r;
    
    % shape task
    r = get_dec(resp_red(shapeTrials,:),shpIds(shapeTrials),resp_red(shapeTrials,:),colIds(shapeTrials),resp_red(shapeTrials,:),choices(shapeTrials)); r_sess([7 8 9]) = r;
    r = get_dec(resp_red(shapeTrials,:),colIds(shapeTrials),resp_red(shapeTrials,:),shpIds(shapeTrials),resp_red(shapeTrials,:),choices(shapeTrials)); r_sess([11 10 12]) = r;

    % color task
    r = get_dec(resp_red(colorDiff,:),shpIds(colorDiff),resp_red(colorDiff,:),colIds(colorDiff),resp_red(colorDiff,:),choices(colorDiff)); r_sess([13 14 15]) = r;
    r = get_dec(resp_red(colorDiff,:),colIds(colorDiff),resp_red(colorDiff,:),shpIds(colorDiff),resp_red(colorDiff,:),choices(colorDiff)); r_sess([17 16 18]) = r;

    r_sess = reshape(r_sess,[3 6])';
end

% train on x1, test on x1, x2, and x3
function r = get_dec(x1,y1,x2,y2,x3,y3)
    nFold = 100;
    r_fold = nan(nFold,3);
    nTrainTestTrials = floor(length(y1)/2);
    for ff=1:nFold
        train_1_idx = sort(randperm(length(y1),nTrainTestTrials));
        test_1_idx = 1:length(y1); 
        test_1_idx(ismember(test_1_idx,train_1_idx)) = [];

        beta = regress(y1(train_1_idx),x1(train_1_idx,:));

        r_fold(ff,1) = corr(x1(test_1_idx,:)*beta,y1(test_1_idx));
        r_fold(ff,2) = corr(x2*beta,y2);
        r_fold(ff,3) = corr(x3*beta,y3);
    end
    mult =  repmat(2*(0.5-double(sum(r_fold<0)==nFold)),nFold,1);
    r_fold = r_fold.*mult;
    r = mean(r_fold);
end