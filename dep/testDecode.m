load('/Users/ramanujan/Downloads/v4-7a/zippy_grid_2afc_240806-134454_dense.mat')
    eid = [3*ones(1,32) ones(1,64) 3*ones(1,32)];
    resp = resp(:,eid==1);
    resp_base = resp_base(:,eid==1);
    good = mean(resp)>1.2*mean(resp_base); % true(1,size(resp,2));
    resp = resp(:,good);
    resp_red = pca(resp','NumComponents',10);

figure('color','w')
[col,cc] = decodeFn(colIds,resp_red); 
subplot(121); hold on;
line([0 6],[0 6],'linestyle','--','color',[0.5 0.5 0.5]); 
notBoxPlot(col,colIds);
fixPlot(gca,[0 6],[0 6],'color','decoded color',1:5,1:5,{'color decoding' ['r = ' num2str(round(cc,3))]})

[shp,cc] = decodeFn(shpIds,resp_red); 
subplot(122); hold on;
line([0 6],[0 6],'linestyle','--','color',[0.5 0.5 0.5]); 
notBoxPlot(shp,shpIds);
fixPlot(gca,[0 6],[0 6],'curvature','decoded curvature',1:5,1:5,{'curvature decoding' ['r = ' num2str(round(cc,3))]})

