clc; clear; close all;

%% load a file
dataLoc = '~/Downloads/v4-7a';
load('data/mapRecord.mat','mapRecord')

%%
load([dataLoc '/' mapRecord(40).name '_rf.mat'])

%%
% zippy
pos = [280 -130 280];

% helium
pos = [-200 -200 270];

stimPos = [pos(1)-pos(3)/2 pos(2)-pos(3)/2 pos(3) pos(3)];
clf; hold on;
for ii=1:64
    plot(gca,rfv4.staFit_beta(ii,2),rfv4.staFit_beta(ii,4),'.','markersize',15,'color',[0.2 0.9 0.3]*0.8);
    drawellipse(gca,'center',rfv4.staFit_beta(ii,[2 4]),'SemiAxes',abs(rfv4.staFit_beta(ii,[3 5])/2),'Color',[0.2 0.9 0.3],'facealpha',0,'InteractionsAllowed','none','selected',false,'linewidth',1,'edgealpha',0.5);
end
plot(0,0,'r.','markersize',20);
rectangle('Position',stimPos,'LineWidth',2,'EdgeColor','k')
% axis([-200 960 -540 200])

rectangle('Position',[rfv4.pos(1)-rfv4.pos(3) rfv4.pos(2)-rfv4.pos(3) rfv4.pos(3)*2 rfv4.pos(3)*2],'LineWidth',2,'EdgeColor','b')

% get 5 degree ticks
ticks = 5*(200./rad2deg(atan((200*(609.6/sqrt(1920^2 + 1080^2)))/540)));

% zippy
fixPlot(gca,[-200 800],[-500 200],'','',-4*ticks:ticks:ticks*4,-4*ticks:ticks:ticks*4)

% helium
fixPlot(gca,[-800 200],[-500 200],'','',-4*ticks:ticks:ticks*4,-4*ticks:ticks:ticks*4)

axis normal
% axis equal %%% bug in matlab messes up the axes if you do this before
% randomly resizing the figure window??