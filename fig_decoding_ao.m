%% prelim
clear all;
load('data/exptRecord.mat')
exptRecord = exptRecord([exptRecord.nCorrect]>100);
exptRecord = exptRecord(cellfun(@(x) length(x)==25,{exptRecord.stimOpp_num}) & cellfun(@(x) length(x)==25,{exptRecord.stimRF_num}));
% exptRecord = exptRecord(randi(length(exptRecord)));
counter = 0;
for ii=1:length(exptRecord)
    load(['~/Downloads/v4-7a/' exptRecord(ii).name '_dense.mat'],'params','resp','resp_base')
    % r(ii,:) = prelim2_grid_2afc(params,resp,resp_base,0);
    if isfield(params, 'rule') && any([params.rule] == 0) && any([params.rule] == 1)
        counter = counter + 1;
        disp('++++++++++++++++++++++++++++++++++++')
        disp([num2str(ii) ': ' exptRecord(ii).name])
        r_sess(:,:,counter) = prelim5_grid_2afc(params,resp,resp_base);
    end
end



%% boxplots
figure('pos',[1000,319,601,919],'color','w'); clf
titleStr = {{'shape decoder' 'classic'} {'color decoder' 'classic'} {'shape decoder' 'inverted'} {'color decoder' 'inverted'}};
for ii=1:4
    subplot(2,2,ii); 
    notBoxPlot([squeeze(r_sess(ii,1,:)),squeeze(r_sess(ii,2,:)),squeeze(r_sess(ii,3,:)),squeeze(r_sess(ii,4,:))]); 
    fixPlot(gca,[0 4],[-1 1],'','decoding accuracy',1:4,-1:0.25:1,titleStr{ii})
    set(gca,'XTickLabel',{'shape' 'color' 'classic choice' 'inverted choice'})
end

%% scatters
%figure('pos',[1616,930,601,308],'color','w');
%subplot(121)
%line([0 1],[0 1],'linestyle','--','color','k','linewidth',2); hold on;
%plot(squeeze(r_sess(3,1,:)),squeeze(r_sess(5,1,:)),'.','markersize',18);
%plot(squeeze(r_sess(3,2,:)),squeeze(r_sess(5,2,:)),'.','markersize',18);
%plot(squeeze(r_sess(3,3,:)),squeeze(r_sess(5,3,:)),'.','markersize',18);
%fixPlot(gca,[-0.2 1],[-0.2 1],'shape task trials','color task trials',0:0.25:1,0:0.25:1,'shape decoder performance')
% legend('Location','northwest')

%subplot(122)
%line([0 1],[0 1],'linestyle','--','color','k','linewidth',2); hold on;
%plot(squeeze(r_sess(4,1,:)),squeeze(r_sess(6,1,:)),'.','markersize',18);
%plot(squeeze(r_sess(4,2,:)),squeeze(r_sess(6,2,:)),'.','markersize',18);
%plot(squeeze(r_sess(4,3,:)),squeeze(r_sess(6,3,:)),'.','markersize',18);
%fixPlot(gca,[-0.2 1],[-0.2 1],'shape task trials','color task trials',0:0.25:1,0:0.25:1,'color decoder performance',{'' 'shape decoding' 'color decoding' 'choice decoding'})
%legend('Location','southeast')


%%
function r_sess = prelim5_grid_2afc(params,resp,resp_base)
    colorDiff = (mod([params.stimRF_num],5)-mod([params.stimOpp_num],5)) == 0;
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

    % Sort by rule

    colIds_classic = colIds([params.rule] == 0 & get_non_recent(params, 50));
    colIds_inv = colIds([params.rule] == 1 & get_non_recent(params, 50));
    shpIds_classic = shpIds([params.rule] == 0 & get_non_recent(params, 50));
    shpIds_inv = shpIds([params.rule] == 1 & get_non_recent(params, 50));

    choices_classic = choices([params.rule] == 0 & get_non_recent(params, 50));
    choices_inv = choices([params.rule] == 1 & get_non_recent(params, 50));

    resp_red_classic = resp_red([params.rule] == 0 & get_non_recent(params, 50), :);
    resp_red_inv = resp_red([params.rule] == 1 & get_non_recent(params, 50), :);


    % col & shape train on classic, tests on both classic and inverse

    % train on classic shape
    % test on classic shape, classic color, classic choices, inv choices
    r = get_dec(resp_red_classic, shpIds_classic, resp_red_classic, colIds_classic, resp_red_classic, choices_classic, resp_red_inv, choices_inv);
    r_sess([1 2 3 4]) = r;

    % train on classic col
    % test on classic col, classic shape, classic choices, inv choices
    r = get_dec(resp_red_classic, colIds_classic, resp_red_classic, shpIds_classic, resp_red_classic, choices_classic, resp_red_inv, choices_inv);
    r_sess([6 5 7 8]) = r; 

    % train on inv shape
    % test inv shape, inv col, classic choices, inv choices
    r = get_dec(resp_red_inv, shpIds_inv, resp_red_inv, colIds_inv, resp_red_classic, choices_classic, resp_red_inv, choices_inv);
    r_sess([9 10 11 12]) = r; 

    %train on inv color
    %test inv color, inv shape, classic choices, inv choices
    r = get_dec(resp_red_inv, colIds_inv, resp_red_inv, shpIds_inv, resp_red_classic, choices_classic, resp_red_inv, choices_inv);
    r_sess([14 13 15 16]) = r; 

    r_sess = reshape(r_sess,[4 4])';
    
    % ORDER: shp, col, class, inv


    % the seemingly random shuffling after r gets assigned
    % is to format it in the way that i will plot it later.
    % it's silly.

    % all trials
    %r = get_dec(resp_red,shpIds,resp_red,colIds,resp_red,choices); r_sess([1 2 3]) = r;
    %r = get_dec(resp_red,colIds,resp_red,shpIds,resp_red,choices); r_sess([5 4 6]) = r;
    
    % shape task
    %r = get_dec(resp_red(~colorDiff,:),shpIds(~colorDiff),resp_red(~colorDiff,:),colIds(~colorDiff),resp_red(~colorDiff,:),choices(~colorDiff)); r_sess([7 8 9]) = r;
    %r = get_dec(resp_red(~colorDiff,:),colIds(~colorDiff),resp_red(~colorDiff,:),shpIds(~colorDiff),resp_red(~colorDiff,:),choices(~colorDiff)); r_sess([11 10 12]) = r;

    % color task
    %r = get_dec(resp_red(colorDiff,:),shpIds(colorDiff),resp_red(colorDiff,:),colIds(colorDiff),resp_red(colorDiff,:),choices(colorDiff)); r_sess([13 14 15]) = r;
    %r = get_dec(resp_red(colorDiff,:),colIds(colorDiff),resp_red(colorDiff,:),shpIds(colorDiff),resp_red(colorDiff,:),choices(colorDiff)); r_sess([17 16 18]) = r;

    %r_sess = reshape(r_sess,[3 6])';
end

% train on x1, test on x1, x2, x3, and x4
function r = get_dec(x1,y1,x2,y2,x3,y3,x4,y4)
    nFold = 100;
    r_fold = nan(nFold,4);
    nTrainTestTrials = floor(length(y1)/2);
    for ff=1:nFold
        train_1_idx = sort(randperm(length(y1),nTrainTestTrials));
        test_1_idx = 1:length(y1); 
        test_1_idx(ismember(test_1_idx,train_1_idx)) = [];

        beta = regress(y1(train_1_idx),x1(train_1_idx,:));

        r_fold(ff,1) = corr(x1(test_1_idx,:)*beta,y1(test_1_idx));
        r_fold(ff,2) = corr(x2*beta,y2);
        r_fold(ff,3) = corr(x3*beta,y3);
        r_fold(ff,4) = corr(x4*beta,y4);


    end
    %mult =  repmat(2*(0.5-double(sum(r_fold<0)==nFold)),nFold,1);
    %r_fold = r_fold.*mult;
    r = mean(r_fold);
end