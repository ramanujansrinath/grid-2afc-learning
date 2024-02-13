function rf = getRF_sta(mResp,pos,badNeurons)
    ex = [max(pos(:,1:2))+round(max(pos(:,3)/2)); min(pos(:,1:2))-round(max(pos(:,3)/2))];
    [xx,yy] = meshgrid(ex(2,1):ex(1,1),ex(2,2):ex(1,2));
    % [xx,yy] = meshgrid(-400:2:100,-400:2:100);
    yy = flipud(yy);
    sta = zeros([size(xx) size(mResp,2)]);
    % stafit = zeros([size(xx) size(mResp,2)]);
    stafit_beta = zeros([size(mResp,2) 5]);
    com = nan(size(mResp,2),3);
    h = getFitFuncHand(size(xx)); % for fitting
    xvec = [xx(:) yy(:)]; % for fitting
    for ii=1:size(mResp,2)
        if ~badNeurons(ii)
            rr = mResp(:,ii);
            staT = zeros(size(xx)); staN = zeros(size(xx));
            for jj=1:length(rr)
                cx = pos(jj,1);
                cy = pos(jj,2);
                cr = pos(jj,3)/2;
                idx = ((xx-cx).^2 + (yy-cy).^2)<(cr^2);
                staT(idx) = staT(idx)+rr(jj);
                staN(idx) = staN(idx)+1;
            end
            staT = staT./staN;
            sta(:,:,ii) = staT;
            % thresh = mean(staT(~isnan(staT)))-std(staT(~isnan(staT)))/4;
            % staB = staT;
            % staB(staT<thresh) = 0;
            % staB(staB>0) = 1;
            % staB(isnan(staB)) = 0;
            % 
            % [xxx,yyy] = ndgrid(1:size(staT, 1), 1:size(staT, 2));
            % rowcentre = sum(xxx(staB) .* staT(staB)) / sum(staT(staB));
            % colcentre = sum(yyy(staB) .* staT(staB)) / sum(staT(staB));

            yvec = staT(:); yvec(isnan(yvec)) = 0;
            beta = nlinfit(xvec,yvec,h,[1 20 20 20 20]);
            % stafit(:,:,ii) = reshape(h(beta,xvec),size(xx));
            stafit_beta(ii,:) = beta;
        end
    end
    rf.x = xx;
    rf.y = yy;
    rf.com = com;
    rf.sta = sta;
    % rf.staFit = stafit;
    rf.staFit_beta = stafit_beta;
end

function h = getFitFuncHand(xSize)
    h = @getGaussian2d;
    function z = getGaussian2d(beta,X)
    % beta = [a mu_x sig_x mu_y sig_y]
        a = beta(1);
        mu1 = beta(2);
        sig1 = beta(3);
        mu2 = beta(4);
        sig2 = beta(5);
        x = X(:,1); x = reshape(x,xSize);
        y = X(:,2); y = reshape(y,xSize);

        z = 1/(2*pi*sig1*sig2);

        c1 = ((x-mu1).^2)/(2*sig1^2);
        c2 = ((y-mu2).^2)/(2*sig2^2);

        z = a * z .* exp(-(c1 + c2));
        z = z(:);
    end
end

