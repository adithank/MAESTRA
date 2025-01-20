function [costVal,uu] = objFuncDefNH_FourierTraction_Pades(K,G,M,deltaX,deltaY,shTerm,bulkTerm,uBeads,delInds)
    
    % Compressible N-H formulation in terms of First Piola-Kirchoff tensor
    % P = mu * (F - F^-T) + lam * (J-1) * J * F^-T 
    % P = mu * shTerm + lam * bulkTerm;
    
    N = numel(uBeads)./2;
    
    
    P = G * shTerm + K * bulkTerm;
    
    P11 = squeeze( P(:,:,1,1) ) ;
    P12 = squeeze( P(:,:,1,2) ) ;
    P21 = squeeze( P(:,:,2,1) ) ;
    P22 = squeeze( P(:,:,2,2) ) ;
    
    X = delInds{1};
    Y = delInds{2};

    Xind = zeros(size(X)); Yind = zeros(size(Y));
    Xind(5:end-4,5:end-4) = X(5:end-4,5:end-4);
    Yind(5:end-4,5:end-4) = Y(5:end-4,5:end-4);
    inds = (X == Xind) & (Y == Yind);

%     [dP11dx,~] = Func_1stDer_PadesScheme(P11,deltaX,deltaY); % sigma_xx
%     [~,dP22dy] = Func_1stDer_PadesScheme(P22,deltaX,deltaY); % sigma_yy
%     [~,dP12dy] = Func_1stDer_PadesScheme(P12,deltaX,deltaY); % sigma_xy
%     [dP21dx,~] = Func_1stDer_PadesScheme(P21,deltaX,deltaY); % sigma_yx
    dP11dx = dfdx_pade_2D_rik(P11,deltaX); % sigma_xx
    dP22dy = dfdy_pade_2D_rik(P22,deltaY); % sigma_yy
    dP12dy = dfdy_pade_2D_rik(P12,deltaY); % sigma_xy
    dP21dx = dfdx_pade_2D_rik(P21,deltaX); % sigma_yx
%     
%     [~,~,dP11dx,~] = FourierFiltAndDiff(X,Y,P11,P11,0.6);
%     [~,~,~,dP22dy] = FourierFiltAndDiff(X,Y,P22,P22,0.6);
%     [~,~,~,dP12dy] = FourierFiltAndDiff(X,Y,P12,P12,0.6);
%     [~,~,dP21dx,~] = FourierFiltAndDiff(X,Y,P21,P21,0.6);
    
%     dP11dx = imgaussfilt(dP11dx,0.5); dP22dy = imgaussfilt(dP22dy,0.8);
%     dP21dx = imgaussfilt(dP21dx,0.5); dP12dy = imgaussfilt(dP12dy,0.8);
    
    ttx = -(dP11dx+dP12dy);
    tty = -(dP22dy+dP21dx);

    ttx = ttx * (10/0.325); % sig = T / h
    tty = tty * (10/0.325);

    % Try with Fourier method (Forward)
    % Zero-pad with HW (Ricardo's code)
    % alpha = 0.2;
    % 
    % HWx = zeros(size(X)) ;
    % HWy=HWx;
    % Lx = range(X(:));
    % Ly = range(Y(:));
    % 
    % HWx(X<=alpha*(Lx)/2) = (1 + cos(pi*(2*X(X<=alpha*(Lx)/2)/(alpha*(Lx))-1)))/2 ;
    % HWx((X>alpha*(Lx)/2).*(X<=(Lx)*(1-alpha/2))>0) = 1 ;
    % HWx(X>(Lx)*(1-alpha/2)) = (1 + cos(pi*(2*X(X>(Lx)*(1-alpha/2))/(alpha*(Lx))-2/alpha+1)))/2 ;
    % 
    % HWy(Y<=alpha*(Ly)/2) = (1 + cos(pi*(2*Y(Y<=alpha*(Ly)/2)/(alpha*(Ly))-1)))/2 ;
    % HWy((Y>alpha*(Ly)/2).*(Y<=(Ly)*(1-alpha/2))>0) = 1 ;
    % HWy(Y>(Ly)*(1-alpha/2)) = (1 + cos(pi*(2*Y(Y>(Ly)*(1-alpha/2))/(alpha*(Ly))-2/alpha+1)))/2 ;
    % 
    % HW=HWx.*HWy;
    % 
    % ttx = ttx .* HW;
    % tty = tty .* HW;
    % 
    % padSize = 20;
    % ttx = padarray(ttx,[padSize padSize]);
    % tty = padarray(tty,[padSize padSize]);

    [ny,nx] = size(ttx);

    [uux,uuy] = performTFMLinButlerForward(nx,ny,deltaX,deltaY,ttx,tty);
    % hs = 150/0.325; Es = 8e3; nus = 0.45;
    % [uux,uuy] = performTFM2DFiniteThickLinButler(X,Y,ttx,tty,Es,nus,hs,1);

    % uux = uux(padSize+1:end-padSize,padSize+1:end-padSize);
    % uuy = uuy(padSize+1:end-padSize,padSize+1:end-padSize);
    
%     [uux,uuy] = FourierFiltAndDiff(X,Y,uux,uuy,0.6);
% uux = imgaussfilt(uux,0.8);
% uuy = imgaussfilt(uuy,0.8);

    uu = [uux(:); uuy(:)];
    %     uu(delInds) = nan; % To remove contribution from close to 0 cell deformation
    
    costVal = sqrt( mean( (uBeads(inds) - uu(inds)).^2 ) );
   
    
end




