%% prelim
clear; close all; clc
addpath('dep');
load('data/exptRecord.mat')
exptRecord = exptRecord([exptRecord.nCorrect]>100);
exptRecord = exptRecord(cellfun(@(x) length(x)==25,{exptRecord.stimOpp_num}) & cellfun(@(x) length(x)==25,{exptRecord.stimRF_num}));
exptRecord = exptRecord(34:46);
r_sess = nan(6,3,length(exptRecord));
r_xpred = nan(3,6,length(exptRecord));
r_choice_gen = nan(2,4,length(exptRecord));

for ii=1:length(exptRecord)
    disp('++++++++++++++++++++++++++++++++++++')
    disp([num2str(ii) ': ' exptRecord(ii).name])
    load(['~/Downloads/v4-7a/' exptRecord(ii).name '_dense.mat'],'params','resp','resp_base')
    [r_sess(:,:,ii),r_xpred(:,:,ii),r_choice_gen(:,:,ii)] = prelim5_grid_2afc(params,resp,resp_base);
end

%% boxplots
figure('pos',[1000,319,601,919],'color','w'); clf
titleStr = {{'shape decoder' 'across tasks'} {'color decoder' 'across tasks'} {'shape decoder' 'rule 0 task'} {'color decoder' 'rule 0 task'} {'shape decoder' 'rule 1 task'} {'color decoder' 'rule 1 task'}};
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
% fixPlot(gca,[-0.2 1],[-0.2 1],'rule 0 trials','rule 1 trials',0:0.25:1,0:0.25:1,'shape decoder performance')
% legend('Location','northwest')

subplot(122)
line([0 1],[0 1],'linestyle','--','color','k','linewidth',2); hold on;
plot(squeeze(r_sess(4,1,:)),squeeze(r_sess(6,1,:)),'.','markersize',18);
plot(squeeze(r_sess(4,2,:)),squeeze(r_sess(6,2,:)),'.','markersize',18);
plot(squeeze(r_sess(4,3,:)),squeeze(r_sess(6,3,:)),'.','markersize',18);
% fixPlot(gca,[-0.2 1],[-0.2 1],'rule 0 trials','rule 1 trials',0:0.25:1,0:0.25:1,'color decoder performance',{'' 'shape decoding' 'color decoding' 'choice decoding'})
legend('Location','southeast')

%% xpred box
figure('pos',[1000,900,876,338],'color','w'); clf
titleStr = {{'shape decoder' 'trained on rule 0'} {'color decoder' 'trained on rule 0'} {'choice decoder' 'trained on rule 0'}};
for ii=1:3
    subplot(1,3,ii); 
    notBoxPlot(squeeze(r_xpred(ii,:,:))'); 
    fixPlot(gca,[0 7],[-1 1],'tested on','decoding accuracy',1:6,-1:0.5:1,titleStr{ii})
    set(gca,'XTickLabel',{'r0 shape' 'r0 color' 'r0 choice' 'r1 shape' 'r1 color' 'r1 choice'})
end

%% gen dec plot
figure('pos',[1000,900,876,338],'color','w'); clf
titleStr = {{'gen choice decoder' 'tested on rule 0'} {'gen choice decoder' 'tested on rule 1'}};
for ii=1:2
    subplot(1,2,ii); 
    notBoxPlot(squeeze(r_choice_gen(ii,:,:))'); 
    fixPlot(gca,[0 5],[-1 1],'tested on','decoding accuracy',1:4,-1:0.5:1,titleStr{ii});
    set(gca,'XTickLabel',{'all choices' 'shape' 'color' ['r' num2str(ii-1) ' choice']})
end


%%
function [r_sess,r_xpred,r_choice_gen] = prelim5_grid_2afc(params,resp,resp_base)
    if ~isfield(params,'rule')
        disp('... no rules')
        r_sess = nan(6,3);
        r_xpred = nan(3,6);
        r_choice_gen = nan;
        return;
    end
    if sum([params.rule] == 0)== 0 || sum([params.rule] == 1) == 0
        disp('... no rule switches')
        r_sess = nan(6,3);
        r_xpred = nan(3,6);
        r_choice_gen = nan;
        return;
    end

    % rule = [params.rule];
    % rule_guess = guess_rule(params);
    % good_tr_idx = rule==rule_guess;
    good_tr_idx = [params.correct]==[params.selected];

    params = params(good_tr_idx);
    resp = resp(good_tr_idx,:);
    resp_base = resp_base(good_tr_idx,:);
    % rule = rule(good_tr_idx);

    eid = [3*ones(1,32) ones(1,64) 3*ones(1,32)];
    resp = resp(:,eid==1);
    resp_base = resp_base(:,eid==1);
    good = mean(resp)>1.1*mean(resp_base); % true(1,size(resp,2));
    resp = resp(:,good);

    resp_red = pca(resp','NumComponents',10);
    
    % split by rule and visualize shape and color axes
    plot_shape_color_rule(params,resp_red,0);

    % split trials into rule 0 and 1 and project choices on feature axes
    r_sess = get_splitTrialDec(params,resp_red);

    % x-decode choice, shape, color across rules
    r_xpred = get_xpred(params,resp_red);

    % get a general choice decoder across rules and decode features and choices
    r_choice_gen = get_choice_genDec(params,resp_red);
end

%%
function plot_shape_color_rule(params,resp_red,doPlot)
    if doPlot
        stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(1:5,1,5))];
        colIds = stimVals([params.stimRF_num],1);
        shpIds = stimVals([params.stimRF_num],2);
        rule = [params.rule]';
        
        subplot(231); 
        scatter3(resp_red(:,1),resp_red(:,2),resp_red(:,3),20,rule,'filled'); title('pca rule')
        fix3dPlot(gca,[],[],[],'pc1','pc2','pc3'); set(gca,'xtick',[],'ytick',[],'ztick',[])
        colormap(subplot(231), [0.8 0.4 0.1; 0.1 0.7 0.5])
    
        subplot(232); 
        scatter3(resp_red(:,1),resp_red(:,2),resp_red(:,3),20,colIds,'filled'); title('pca color')
        fix3dPlot(gca,[],[],[],'pc1','pc2','pc3'); set(gca,'xtick',[],'ytick',[],'ztick',[])
        colormap(subplot(232), round([linspace(247,87,5)' linspace(240,181,5)' linspace(107,229,5)'])/255)
        
        subplot(233); 
        scatter3(resp_red(:,1),resp_red(:,2),resp_red(:,3),20,shpIds,'filled'); title('pca shape')
        fix3dPlot(gca,[],[],[],'pc1','pc2','pc3'); set(gca,'xtick',[],'ytick',[],'ztick',[])
        colormap(subplot(233), round([linspace(62,188,5)' linspace(62,188,5)' linspace(62,188,5)'])/255)
    end
end

function r_xpred = get_xpred(params,resp_red)
    rule0Trials = [params.rule] == 0;
    rule1Trials = [params.rule] == 1;

    stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(1:5,1,5))];
    colIds = stimVals([params.stimRF_num],1);
    shpIds = stimVals([params.stimRF_num],2);
    choices = [params.selected]';

    r_xpred(1,:) = get_dec...
        (resp_red(rule0Trials,:),shpIds(rule0Trials),...
        {resp_red(rule0Trials,:),resp_red(rule0Trials,:),...
        resp_red(rule1Trials,:),resp_red(rule1Trials,:),resp_red(rule1Trials,:)},...
        {colIds(rule0Trials),choices(rule0Trials),...
        shpIds(rule1Trials),colIds(rule1Trials),choices(rule1Trials)});

    r_xpred(2,:) = get_dec...
        (resp_red(rule0Trials,:),colIds(rule0Trials),...
        {resp_red(rule0Trials,:),resp_red(rule0Trials,:),...
        resp_red(rule1Trials,:),resp_red(rule1Trials,:),resp_red(rule1Trials,:)},...
        {shpIds(rule0Trials),choices(rule0Trials),...
        shpIds(rule1Trials),colIds(rule1Trials),choices(rule1Trials)});
    r_xpred(2,:) = swapnum(r_xpred(2,:),{[1 2]}); % swap 1 and 2

    r_xpred(3,:) = get_dec...
        (resp_red(rule0Trials,:),choices(rule0Trials),...
        {resp_red(rule0Trials,:),resp_red(rule0Trials,:),...
        resp_red(rule1Trials,:),resp_red(rule1Trials,:),resp_red(rule1Trials,:)},...
        {colIds(rule0Trials),shpIds(rule0Trials),...
        shpIds(rule1Trials),colIds(rule1Trials),choices(rule1Trials)});
    r_xpred(3,:) = swapnum(r_xpred(3,:),{[1 3]}); % swap 1 and 3
end

function r_choice_gen = get_choice_genDec(params,resp_red)
    rule0Trials = [params.rule] == 0;
    rule1Trials = [params.rule] == 1;

    stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(1:5,1,5))];
    colIds = stimVals([params.stimRF_num],1);
    shpIds = stimVals([params.stimRF_num],2);
    choices = [params.selected]';

    % doing it in two goes just to keep it clean
    r_choice_gen(1,:) = get_dec...
        (resp_red,choices,...
        {resp_red(rule0Trials,:),resp_red(rule0Trials,:),resp_red(rule0Trials,:)},...
        {shpIds(rule0Trials),colIds(rule0Trials),choices(rule0Trials)});

    r_choice_gen(2,:) = get_dec...
        (resp_red,choices,...
        {resp_red(rule1Trials,:),resp_red(rule1Trials,:),resp_red(rule1Trials,:)},...
        {shpIds(rule1Trials),colIds(rule1Trials),choices(rule1Trials)});
end

function r_sess = get_splitTrialDec(params,resp_red)
    rule0Trials = [params.rule] == 0;
    rule1Trials = [params.rule] == 1;

    stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(1:5,1,5))];
    colIds = stimVals([params.stimRF_num],1);
    shpIds = stimVals([params.stimRF_num],2);
    choices = [params.selected]';
    
    % the seemingly random shuffling after r gets assigned
    % is to format it in the way that i will plot it later.
    % it's silly.

    % all trials
    r = get_dec(resp_red,shpIds,{resp_red,resp_red},{colIds,choices}); r_sess([1 2 3]) = r;
    r = get_dec(resp_red,colIds,{resp_red,resp_red},{shpIds,choices}); r_sess([5 4 6]) = r;
    
    % rule 0
    r = get_dec(resp_red(rule0Trials,:),shpIds(rule0Trials),{resp_red(rule0Trials,:),resp_red(rule0Trials,:)},{colIds(rule0Trials),choices(rule0Trials)}); r_sess([7 8 9]) = r;
    r = get_dec(resp_red(rule0Trials,:),colIds(rule0Trials),{resp_red(rule0Trials,:),resp_red(rule0Trials,:)},{shpIds(rule0Trials),choices(rule0Trials)}); r_sess([11 10 12]) = r;

    % rule 1
    r = get_dec(resp_red(rule1Trials,:),shpIds(rule1Trials),{resp_red(rule1Trials,:),resp_red(rule1Trials,:)},{colIds(rule1Trials),choices(rule1Trials)}); r_sess([13 14 15]) = r;
    r = get_dec(resp_red(rule1Trials,:),colIds(rule1Trials),{resp_red(rule1Trials,:),resp_red(rule1Trials,:)},{shpIds(rule1Trials),choices(rule1Trials)}); r_sess([17 16 18]) = r;

    r_sess = reshape(r_sess,[3 6])';
end



% train on x1, test on x1, x2, x3, ..., xn
function r = get_dec(x1,y1,xn,yn)
    nFold = 100;
    r_fold = nan(nFold,length(xn)+1);
    nTrainTestTrials = floor(length(y1)/2);
    for ff=1:nFold
        train_1_idx = sort(randperm(length(y1),nTrainTestTrials));
        test_1_idx = 1:length(y1); 
        test_1_idx(ismember(test_1_idx,train_1_idx)) = [];

        beta = regress(y1(train_1_idx),x1(train_1_idx,:));

        r_fold(ff,1) = corr(x1(test_1_idx,:)*beta,y1(test_1_idx));
        for jj=1:length(xn)
            r_fold(ff,jj+1) = corr(xn{jj}*beta,yn{jj});
        end
    end
    % mult =  repmat(2*(0.5-double(sum(r_fold<0)==nFold)),nFold,1);
    % r_fold = r_fold.*mult;
    r = mean(r_fold);
end

function vec = swapnum(vec,swaps)
    for ii=1:length(swaps)
        temp = vec(swaps{ii}(1));
        vec(swaps{ii}(1)) = vec(swaps{ii}(2));
        vec(swaps{ii}(2)) = temp;
    end
end