clc; clear; close all;

%%  network
net = vgg16;
layerNames = arrayfun(@(ii) net.Layers(ii).Name,1:length(net.Layers),'UniformOutput',false);

% for alexnet: 5 pool layers
% layerNames = layerNames(cellfun(@(x) contains(x,'pool'),layerNames));
% rfSize = [227 99]; % for relu3

% for vgg: 5 pool layers
layerNames = layerNames(cellfun(@(x) contains(x,'pool'),layerNames));
% layerNum = 3; rfSize = [224 44]; % for pool3
layerNum = 4; rfSize = [224 100]; % for pool4

%% load images, get responses
nImg = 25;
imPath = 'img';
imgs = nan([rfSize(1) rfSize(1) 3 nImg]);
for ii=1:nImg
    load([imPath '/img_1_' num2str(ii) '.mat'],'theImage')
    imgs(:,:,:,ii) = scaleToRF(theImage,rfSize);
end

%%
resp = activations(net,imgs,layerNames{layerNum});
centralUnits = 2; % extract nxn central units
filtSize = size(resp);
unitIds = (1+filtSize(1))/2 - (centralUnits-1)/2 : (1+filtSize(1))/2 + (centralUnits-1)/2;
cent_resp = resp(unitIds,unitIds,:,:);
res_resp = reshape(resp,numel(resp)/nImg,nImg);

%% dim reduce
nDim = 25;
[red_resp,pca_beta] = pca(res_resp,'NumComponents',nDim);
% this should be nImg x nDim

%% save image data
save('imgData.mat','resp','res_resp','red_resp','imgs','layerNum','rfSize','nDim')
writematrix(red_resp,'shapecol_vgg_resp.csv')

%% helper functions
function scaledImg = scaleToRF(img,rfSize)
    xlim = mean(mean(img,3),1)-255; xlim = [find(xlim,1,'first') find(xlim,1,'last')];
    ylim = mean(mean(img,3),2)-255; ylim = [find(ylim,1,'first') find(ylim,1,'last')];
    % scaleFactor = rfSize(2)/max([diff(xlim) diff(ylim)]);
    [~,idx] = max([diff(ylim) diff(xlim)]);

    imcut = img(ylim(1):ylim(2),xlim(1):xlim(2),:);

    if idx == 1
        imcut = imresize(imcut,[rfSize(2),nan]);
    else
        imcut = imresize(imcut,[nan,rfSize(2)]);
    end

    hpad = (rfSize(1)-size(imcut,1))/2;
    vpad = (rfSize(1)-size(imcut,2))/2;
    imcut = padarray(imcut, floor(hpad), 255,'post');
    imcut = padarray(imcut, ceil(hpad), 255,'pre');
    imcut = padarray(imcut, [0 floor(vpad)], 255,'post');
    imcut = padarray(imcut, [0 ceil(vpad)], 255,'pre');

    scaledImg = imcut;
end
