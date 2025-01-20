function [EArr,nuArr,GArr,KArr,LinE,NH,UBF,VBF,dVB] = func_Pades_runElastographyVideos_rik_edited(X,Y,UB,VB,UC,VC,inds,runLinE,runNH)

% Wrapper for elastography of cardiomyocyte videos


%% Filter high frequency with FFT and also find the derivatives
% divergence of displacment dv
dVB = nan(size(UB)); 
% Filtered displacements
% UBF = nan(size(UB)); VBF = nan(size(UB));
UBF = nan([ size(UB,[1 2]) length(inds)]); 
VBF = UBF;
UCF = UBF; VCF = VBF;

dx = X(1,2) - X(1);
dy = Y(2,1) - Y(1);

for i = 1 : length(inds)
    ttU = UB(:,:,inds(i));
    ttV = VB(:,:,inds(i));
    
    UBF(:,:,i) = ttU; VBF(:,:,i) = ttV;

    dUdx = dfdx_pade_2D_rik(ttU,dx);
%     dUdy = dfdy_pade_2D_rik(squeeze(UBF(:,:,i)),dy); % Not needed
%     dVdx = dfdx_pade_2D_rik(squeeze(VBF(:,:,i)),dx); % Not needed
    dVdy = dfdy_pade_2D_rik(ttV,dy);

    if ~isempty(UC)
        ttU = UC(:,:,inds(i));
        ttV = VC(:,:,inds(i));
        UCF(:,:,i) = ttU; VCF(:,:,i) = ttV;
    end
    
    UBF(:,:,i) = ttU; VBF(:,:,i) = ttV;

    
%     [dUdx,dUdy] = Func_1stDer_PadesScheme(squeeze(UBF(:,:,i)),dx,dy);
%     [dVdx,dVdy] = Func_1stDer_PadesScheme(squeeze(VBF(:,:,i)),dx,dy);
%    
    dVB(:,:,i) = dUdx + dVdy;
    
end

if isempty(UC)
    UCF = UBF; VCF = VBF;
end

%% Fit (E,nu) and Fourier tractions


% inds = [40 90 120]; % Indices of the peak in the time series
% Postinds = [6 22 38 55 71 87 104 120];

if nargin <= 5
    runNH = 1;
    runLinE = 1;
end

% [LinE, NH] = runoptimNHLinE_Pades(UCF,VCF,UBF,VBF,dVB,X,Y,inds,runLinE,runNH);
[LinE, NH] = runOptimNHLinEWPades(UCF,VCF,UBF,VBF,X,Y,runLinE,runNH);




EArr=[];nuArr=[];
GArr=[];KArr=[];

if runLinE
for i = 1: length(inds)
EArr(i)=LinE(i).sol.E;
nuArr(i)=LinE(i).sol.nu;
end; end

if runNH
for i = 1: length(inds)
GArr(i)=NH(i).sol.G;
KArr(i)=NH(i).sol.K;
end; 
end
end
