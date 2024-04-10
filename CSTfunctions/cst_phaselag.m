function [phase,pkphase] = cst_phaselag(x,y,t,isplot)
%
%-------header-------------------------------------------------------------
% NAME
%   cst_phaselag.m
% PURPOSE
%   compute the phase lag of y from x
% USAGE
%   phase = cst_phaselag(x,y,t)
% INPUTS
%   x - reference variable
%   y - phase variable
%   t - time (s)
%   isplot - true if plot to be produced
% OUTPUTS
%   phase - time lag (s) of y relative to x
% NOTES 
%   %test data - uncommment to run test case
%   x=[-0.306639756	-0.336069326	-0.363165842	-0.389082688	-0.416865018	-0.446736396	-0.477111534	-0.508389044	-0.539703515	-0.570127609	-0.600347078	-0.629631592	-0.658771673	-0.686774718	-0.713162336	-0.734461649	-0.739297426	-0.675104006	-0.418008975	-0.107124744	0.028078373	0.191809728	0.366501528	0.557640981	0.651226937	0.747452027	0.824125792	0.878519988	0.900599505	0.880297662	0.824325391	0.755885296	0.642726483	0.542648414	0.445293427	0.373746164	0.311508717	0.261430753	0.213256017	0.174466733	0.135555696	0.107583707	0.077895006	0.04137296	-0.000436868	-0.044585288	-0.0871421	-0.126779776	-0.163181426	-0.195246904];
%   y=[-0.681461348	-0.681950699	-0.683611739	-0.686993791	-0.689935144	-0.690141773	-0.689164111	-0.686682576	-0.682422767	-0.677905309	-0.673369262	-0.668403727	-0.663794786	-0.658927143	-0.653516555	-0.645708184	-0.622376519	-0.536800953	-0.263718142	0.099910446	0.287201364	0.42503359	0.501862547	0.523541462	0.546359918	0.519726937	0.457541307	0.385894135	0.317139943	0.236951842	0.124328104	-0.005138884	-0.138582044	-0.265308753	-0.363703964	-0.448266672	-0.512758179	-0.567893037	-0.6122616	-0.64605713	-0.672012081	-0.695304463	-0.711723862	-0.718747288	-0.718462262	-0.715341125	-0.710922379	-0.705427026	-0.70174046	-0.701017408];
%   T=12.4*3600;  tint=T/(length(x)-1);   t= 0:tint:T;
%   % phase = 0.759 hrs using xcorr
%   % pkphase = 1.012 using peaks seperation
% SEE ALSO
%   used in cst_decompose_velocity.m, part of the CSTmodel
%
% Author: Ian Townend
% CoastalSEA (c) Apr 2024
%--------------------------------------------------------------------------
%
    if nargin==0, isplot = true; end
    xint = length(x);
    yint = length(y);
    tint = length(t);
    delt = t(2)-t(1);
    if xint~=yint || xint~=tint
        warndlg('Input variables x and y or t are not the same size')
        phase = []; return; 
    end
    
    %compute lag using crosscorrelation between variables
    [r,lags] = xcorr(x,y,ceil(tint/2),'coeff');
    [~,idx] = max(r);
    phase = lags(idx)*delt;
    
    %compute lag using seperation of peaks
    T = t(end)/3600;
    tpkx= getpeak(x,t,mean(x),T); %peak value above mean within +/-T hour range
    tpky= getpeak(y,t,mean(y),T);
    if isempty(tpkx) || isempty(tpky)
        pkphase = 0;
    else
        pkphase = tpkx-tpky;
        if pkphase<0, pkphase = 0; end
    end

    if isplot
        checkPlot(x,y,t/3600,phase/3600);
    end
end
%%
function tpk= getpeak(v,t,thr,sep)
    %find the time of the peak value in the cycle    
    [loc,pkv]=peaksoverthreshold(v,thr,4,t/3600,sep);
    if isempty(loc), tpk = []; return; end
    if length(loc)>1
        [~,idv] = max(pkv);
        loc = loc(idv);
    end
    tpk = t(loc);
end
%%
function checkPlot(x,y,t,ph)
    hf = figure('Tag','PlotFig');
    ax = axes(hf);
    plot(ax,t,x,'DisplayName','x-variable')
    hold on
    plot(ax,t,y,'DisplayName','y-variable')
    hold off
    legend
    title(sprintf('Phase lag of y from x with phase = %g hrs',ph))
end