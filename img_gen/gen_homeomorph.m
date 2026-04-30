close all; clc; clear

%% triangle
r = ones(1,3);
th = pi/2 + linspace(0,2*pi,4); th(end) = [];
[x,y] = pol2cart(th,r);
pts_tri = [x;y]';

%% circle
r = ones(1,90);
th = pi/2 + linspace(0,2*pi,91); th(end) = [];
[x,y] = pol2cart(th,r);
pts_cir = [x;y]';

%% make triangle with oversampled points
x1 = linspace(pts_tri(1,1),pts_tri(2,1),31);
x2 = linspace(pts_tri(2,1),pts_tri(3,1),31);
x3 = linspace(pts_tri(3,1),pts_tri(1,1),31);
pts_tricir(:,1) = [x1 x2(2:end) x3(2:end-1)]';

y1 = linspace(pts_tri(1,2),pts_tri(2,2),31);
y2 = linspace(pts_tri(2,2),pts_tri(3,2),31);
y3 = linspace(pts_tri(3,2),pts_tri(1,2),31);
pts_tricir(:,2) = [y1 y2(2:end) y3(2:end-1)]';

%% make all shapes
nShape = 5; sh = cell(1,nShape);
for ii=1:size(pts_cir,1)
    x1 = linspace(pts_tricir(ii,1),pts_cir(ii,1),nShape);
    y1 = linspace(pts_tricir(ii,2),pts_cir(ii,2),nShape);
    for jj=1:nShape
        sh{jj}(ii,:) = [x1(jj) y1(jj)];
    end
end

%% plot overlapping
% subplot(121)
% % patch(pts_tri(:,1),pts_tri(:,2),[0.7 0.6 0.1],'edgecolor','none','facealpha',0.5)
% patch(pts_cir(:,1),pts_cir(:,2),[0.1 0.4 0.9],'edgecolor','none','facealpha',0.5)
% patch(pts_tricir(:,1),pts_tricir(:,2),[0.9 0.9 0.1],'edgecolor','none','facealpha',0.5)
% axis equal; axis off;
% 
% subplot(122)
% for ii=1:nShape
%     patch(sh{ii}(:,1),sh{ii}(:,2),[0.9 0.9 0.1],'edgecolor','k','facealpha',0.2)
% end
% axis equal; axis off;

%% plot all to see grid
figure('color',[240 240 240]/256,'pos',[171,359,356,327]);
nCol = 5; 
col1 = [0 0 1];
col2 = [1 1 1];
col1 = [0 0 1];
col2 = [0.3333 0.3333 0.3333];
cols = [linspace(col1(1),col2(1),nCol);...
        linspace(col1(2),col2(2),nCol);...
        linspace(col1(3),col2(3),nCol)]';

ha = tight_subplot(nCol,nShape,0.05);
ha = reshape(ha,nShape,nCol)';
for jj=1:nCol
    for ii=1:nShape
        % subplot(nCol,nShape,ii+(jj-1)*nShape)
        patch(sh{ii}(:,1),sh{ii}(:,2),cols(jj,:),'facealpha',1,'edgecolor','none','parent',ha(jj,ii));
        
        % axis(ha(jj,ii),[-1.1 1.1 -1.1 1.1])
        axis(ha(jj,ii),'equal'); axis(ha(jj,ii),'off');
    end
end

%% plot each to save
figure('color',[0.2 0.2 0.2],'pos',[400,400,400,400]);
nCol = 5; 
% day 1
col1 = [0.2 0.4 0.9];
col2 = [0.7 0.7 0.1];

% day 2
col1 = [0 0.8 1];
col2 = [1 0.8 0];

% day 3
col1 = [0 0 1];
col2 = [0.3333 0.3333 0.3333];

% day n
col1 = [0 0 1];
col2 = [1 1 1];

cols = [linspace(col1(1),col2(1),nCol);...
        linspace(col1(2),col2(2),nCol);...
        linspace(col1(3),col2(3),nCol)]';

for jj=1:nCol
    for ii=1:nShape
        clf
        % subplot(nCol,nShape,ii+(jj-1)*nShape)
        patch(sh{ii}(:,1),sh{ii}(:,2),cols(jj,:),'edgecolor','none')
        axis(gca,'equal'); axis(gca,'off');
        screen2png('temp.png');
        theImage = imread('temp.png');

        save(['img/img_1_' num2str(ii+(jj-1)*nShape) '.mat'],'theImage')
    end
end