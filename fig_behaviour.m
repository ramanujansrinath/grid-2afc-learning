clear; close all; clc

%% load a file
dataLoc = '~/Downloads/v4-7a';
load('data/exptRecord.mat','exptRecord')
load([dataLoc '/' exptRecord(22).name '_dense.mat'])
plotPsychometric(params)

%%
function plotPsychometric(params)
    diagStimNum = [5 9 13 17 21];
    diagTrials = ismember([params.stimRF_num],diagStimNum) & ismember([params.stimOpp_num],diagStimNum);
    colorTrials = (mod([params.stimRF_num],5)-mod([params.stimOpp_num],5)) == 0;
    shapeTrials = ~colorTrials;
    colorTrials = colorTrials & ~diagTrials;
    shapeTrials = shapeTrials & ~diagTrials;
    
    stimVals = [mat2vec(repmat(1:5,5,1)) mat2vec(repmat(5:-1:1,1,5))];
    colIds_1 = stimVals([params.stimRF_num],1);
    colIds_2 = stimVals([params.stimOpp_num],1);
    
    shpIds_1 = stimVals([params.stimRF_num],2);
    shpIds_2 = stimVals([params.stimOpp_num],2);
    choices = [params.selected]';
    
    clf; hold on;
    
    diff_col = colIds_1(colorTrials)-colIds_2(colorTrials);
    xx = unique(diff_col);
    mm = groupsummary(choices(colorTrials),diff_col,'mean')-1;
    ss = groupsummary(choices(colorTrials),diff_col,'std')./sqrt(groupsummary(choices(colorTrials),diff_col,'nnz'));
    patch([xx;flipud(xx)],[mm-ss/2;flipud(mm+ss/2)],[0.9 0.5 0.2],'edgecolor','none','facealpha',0.5)
    plot(xx,mm,'-o','color',[0.9 0.5 0.2],'LineWidth',2,'MarkerFaceColor','w');
    
    diff_shp = shpIds_1(shapeTrials)-shpIds_2(shapeTrials);
    xx = unique(diff_shp);
    mm = groupsummary(choices(shapeTrials),diff_shp,'mean')-1;
    ss = groupsummary(choices(shapeTrials),diff_shp,'std')./sqrt(groupsummary(choices(shapeTrials),diff_shp,'nnz'));
    patch([xx;flipud(xx)],[mm-ss/2;flipud(mm+ss/2)],[0.2 0.5 0.9],'edgecolor','none','facealpha',0.5)
    plot(xx,mm,'-o','color',[0.2 0.5 0.9],'LineWidth',2,'MarkerFaceColor','w');
    
    diff_shp = shpIds_1(diagTrials)-shpIds_2(diagTrials);
    xx = unique(diff_shp);
    mm = groupsummary(choices(diagTrials),diff_shp,'mean')-1;
    ss = groupsummary(choices(diagTrials),diff_shp,'std')./sqrt(groupsummary(choices(diagTrials),diff_shp,'nnz'));
    patch([xx;flipud(xx)],[mm-ss/2;flipud(mm+ss/2)],[0.2 0.7 0.2],'edgecolor','none','facealpha',0.5)
    plot(xx,mm,'-o','color',[0.2 0.7 0.2],'LineWidth',2,'MarkerFaceColor','w');
    
    fixPlot(gca,[-4.8 4.8],[-0.1 1.1],'stim difference','probability of saccde to RF',-4:4,0:0.25:1,'',{'' 'color' '' 'shape' '' 'diagonal'})
end