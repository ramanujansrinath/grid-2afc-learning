clear; close all; clc
addpath('dep')
sessIds = [20,23,26,27,28,31,35,39,42,48,49,50,51,52,54,55,56];

%% load a file
dataLoc = '~/Downloads/v4-7a';
load('data/exptRecord.mat','exptRecord')
exptRecord = exptRecord(sessIds);
beta = nan(length(exptRecord),6);
for ii=1:length(exptRecord)
    disp('++++++++++++++++++++++++++++++++++++')
    disp([num2str(ii) ': ' exptRecord(ii).name])
    load([dataLoc '/' exptRecord(ii).name '_dense.mat'])
    beta(ii,:) = plotPsychometric(params);
end

%%
xx = linspace(-4,4,20);
for ii=1:length(exptRecord)
    yy = getSigmoid(beta(ii,1:2),xx);
    plot(subplot(231),xx,yy,'k'); hold on;

    yy = getSigmoid(beta(ii,3:4),xx);
    plot(subplot(232),xx,yy,'k'); hold on;

    yy = getSigmoid(beta(ii,5:6),xx);
    plot(subplot(233),xx,yy,'k'); hold on;

end
fixPlot(subplot(231),[-5 5],[-0.1 1.1],'color diff','p(sacc to rf)',-4:4,0:0.25:1,'color trials')
fixPlot(subplot(232),[-5 5],[-0.1 1.1],'shape diff','p(sacc to rf)',-4:4,0:0.25:1,'shape trials')
fixPlot(subplot(233),[-5 5],[-0.1 1.1],'shape diff','p(sacc to rf)',-4:4,0:0.25:1,'diag trials')

subplot(223); boxplot(beta(:,1:2:6)); 
fixPlot(gca,[0 4],[-1 3.1],'','mid point',1:3,-5:5); 
set(gca,'XTickLabel',{'color' 'shape' 'diag'})

subplot(224); boxplot(beta(:,2:2:6)); 
fixPlot(gca,[0 4],[-10 70],'','slope',1:3,0:50:200); 
set(gca,'XTickLabel',{'color' 'shape' 'diag'})


%%
function beta = plotPsychometric(params)
    beta = nan(1,12);
    diagStimNum = [5 9 13 17 21];
    diagTrials = ismember([params.stimRF_num],diagStimNum) & ismember([params.stimOpp_num],diagStimNum);
    colorTrials = (mod([params.stimRF_num],5)-mod([params.stimOpp_num],5)) == 0;
    shapeTrials = ~colorTrials;
    colorTrials = colorTrials & ~diagTrials; % & ~offDiagTrials;
    shapeTrials = shapeTrials & ~diagTrials; % & ~offDiagTrials;
    nTrials = min([sum(diagTrials),sum(shapeTrials),sum(colorTrials)]);

    if nTrials < 10
        return;
    end

    diagTrials = find(diagTrials);
    shapeTrials = find(shapeTrials);
    colorTrials = find(colorTrials);

    stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(5:-1:1,1,5))];
    colIds_1 = stimVals([params.stimRF_num],1);
    colIds_2 = stimVals([params.stimOpp_num],1);
    
    shpIds_1 = stimVals([params.stimRF_num],2);
    shpIds_2 = stimVals([params.stimOpp_num],2);
    choices = [params.selected]'-1;

    beta_col = nan(100,2);
    beta_shp = nan(100,2);
    beta_diag = nan(100,2);
    for ff=1:100
        diagTrials_ff = datasample(diagTrials,nTrials,'Replace',false);
        shapeTrials_ff = datasample(shapeTrials,nTrials,'Replace',false);
        colorTrials_ff = datasample(colorTrials,nTrials,'Replace',false);

        diff_col = colIds_1(colorTrials_ff)-colIds_2(colorTrials_ff);
        ch_col = choices(colorTrials_ff);
        beta_col(ff,:) = fitAny(diff_col,ch_col,@getSigmoid,[0 10]);
        
        % xx = unique(diff_col);
        % mm = groupsummary(ch_col,diff_col,'mean');
        % ss = groupsummary(ch_col,diff_col,'std')./sqrt(groupsummary(ch_col,diff_col,'nnz'));
        % patch([xx;flipud(xx)],[mm-ss/2;flipud(mm+ss/2)],[0.9 0.5 0.2],'edgecolor','none','facealpha',0.5)
        % plot(xx,mm,'-o','color',[0.9 0.5 0.2],'LineWidth',2,'MarkerFaceColor','w');
    

        diff_shp = shpIds_1(shapeTrials_ff)-shpIds_2(shapeTrials_ff);
        ch_shp = choices(shapeTrials_ff);
        beta_shp(ff,:) = fitAny(diff_shp,ch_shp,@getSigmoid,[0 10]);

        % xx = unique(diff_shp);
        % mm = groupsummary(ch_shp,diff_shp,'mean');
        % ss = groupsummary(ch_shp,diff_shp,'std')./sqrt(groupsummary(ch_shp,diff_shp,'nnz'));
        % patch([xx;flipud(xx)],[mm-ss/2;flipud(mm+ss/2)],[0.9 0.5 0.2],'edgecolor','none','facealpha',0.5)
        % plot(xx,mm,'-o','color',[0.9 0.5 0.2],'LineWidth',2,'MarkerFaceColor','w');
    
        
        diff_diag = colIds_1(diagTrials_ff)-colIds_2(diagTrials_ff);
        ch_diag = choices(diagTrials_ff);
        beta_diag(ff,:) = fitAny(diff_diag,ch_diag,@getSigmoid,[0 10]);

        % xx = unique(diff_diag);
        % mm = groupsummary(ch_diag,diff_diag,'mean');
        % ss = groupsummary(ch_diag,diff_diag,'std')./sqrt(groupsummary(ch_diag,diff_diag,'nnz'));
        % patch([xx;flipud(xx)],[mm-ss/2;flipud(mm+ss/2)],[0.9 0.5 0.2],'edgecolor','none','facealpha',0.5)
        % plot(xx,mm,'-o','color',[0.9 0.5 0.2],'LineWidth',2,'MarkerFaceColor','w');
    
    end
    beta = [mean(beta_col) mean(beta_shp) mean(beta_diag)];
end

function y = getSigmoid(beta,x)
    % beta = [bias maxVal midPt slope];
    c=0;
    s=1;
    d=beta(1);
    m=beta(2);

    y = c + s./(1+exp(-(x-d)*m)); 
end