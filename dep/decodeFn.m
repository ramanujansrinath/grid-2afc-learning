function [yh,corr_y] = decodeFn(y,X)
    yh = nan(size(y));
    for ii=1:length(y)
        xval = X(ii,:);
        ytrain = y; ytrain(ii) = [];
        xtrain = X; xtrain(ii,:) = [];
        
        yh(ii) = xval*regress(ytrain,xtrain);
    end
    corr_y = corr(yh,y);
end