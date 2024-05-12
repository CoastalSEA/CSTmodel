function  dst = cst_decompose_velocity(dst)
%
%-------header-------------------------------------------------------------
% NAME
%   cst_decompose_velocity.m
% PURPOSE
%   decompose imported velocity into tidal, river and Stokes velocities and 
%   compute additional parameters for comparison with CSTmodel output.
% USAGE
%   dst = cst_decompose_velocity(dst)
% INPUTS
%   dst - struct of the imported dstables
% OUTPUTS
%   dst - imported struct with the velocities adjusted to tidal, river and
%         Stokes velocities
% NOTES 
%   assumes that imported data are at uniform intervals in time
% SEE ALSO
%   used in CSTdataimport.m
%
% Author: Ian Townend
% CoastalSEA (c) Apr 2024
%--------------------------------------------------------------------------
%
    g = 9.81;                           %acceleration due gravity
    %get additional input data
    promptxt = sprintf('Define values use to extract\ntidal, river and Stokes velotities.\n\nRiver discharge at head (m^3/s):');
    promptxt = {promptxt,'Use Actual or Effective CSA (0/1):'};
    answer = inputdlg(promptxt,'Import data',1,{'35000','1'});
    if isempty(answer), return; end    
    Qr0 = -str2double(answer{1});       %river discharge at head (m3/s) -ve downstream
    iseff = str2double(answer{2});      %flag to use effective CSA
    
    dstF = dst.AlongChannelForm;        %Along-channel form properties
    x = dstF.Dimensions.X;              %Along-channel distance from mouth (m)
    xint = length(x);                   %number of intervals
    Amx = dstF.Amtl;                    %along-channel area at MTL (m2)    
    Wmx = getWmtl(dstF);                %along-channel width at MTL (m)
    Hmx = Amx./Wmx;                     %along channel hydraulic depth at MTL (m)

    dstC = dst.TidalCycleHydro;         %Hydraulic properties overe tidal cycle
    t = seconds(dstC.RowNames);         %time over tidal cycle (s)
    delt = t(2)-t(1);                   %times step (s)
    T = t(end)-t(1);                    %period of cycLe (s) - should be one complete cycle
    zxt = dstC.Elevation;               %Along-channel time series of elevations (mAD)
    uxt = dstC.TidalVel;                %Along-channel time series of velocities (m/s)
                                        %NB - this is total and NOT tidal velocity

    %derived along-channel properties -------------------------------------
    mtlx = trapz(delt,zxt,1)/(T);       %mean water level (mAD)
    zxt = zxt-mtlx;                     %tidal elevation rel.to mtl (m)
    
    a1 = abs(max(zxt,[],1));
    a2 = abs(min(zxt,[],1));
    ampx = (a1+a2)/2;                   %tidal amplitude (m)
    LwHw = a2./a1;                      %LW/HW ratio (-)

    msx = (dstF.Whw-dstF.Wlw)./ampx/4;  %intertidal slope (-)

    %decompose velocity into tidal, river and Stokes components -----------   
    I = ones(size(zxt));
    if iseff
        %code to adjust urt based on effective hydraulic CSA (see manual)
        urx = trapz(delt/T,uxt,1);  %intial estimate of river flow based on residual of total velocity   
        % umean = mean(uxt,1);
        % figure; plot(x,urx,x,umean);
        Aeff = Amx;
        imx = abs(urx)>0.1;             %limit velocity at which correction is made
        Aeff(imx) = Qr0./urx(imx);      %effective csa at mtl
        % figure('Tag','PlotFig'); plot(Amx,Aeff,'o');
        %effective hydraulic CSA over tidal cycle
        A =I*diag(Aeff)+zxt.*(I*diag(Wmx)+zxt*diag(msx));
        %integrate tidal mean and rescale CSA to restore tidal mean CSA
        Aeft = trapz(delt/T,A,1);
        A = (I*diag(Aeft./Aeff)).*A;
    else
        %use observed values of csa at mtl to define variation in CSA
        Aeff = Amx;
        A =I*diag(Amx)+zxt.*(I*diag(Wmx)+zxt*diag(msx)); %area over tidal cycle
    end
    urt=Qr0./A;                                      %river velocity scaled 
                                                     %for tidal variation in area
    utt = uxt-urt;   %tidal component of velocity based on linear superposition    
    
    %width, depth and celerity to estimate Stokes velocity
    W = I*diag(Wmx)+2*zxt*diag(msx);                 %width over tidal cycle
    d = A./W;                                        %depth over tidal cycle
    c = sqrt(g*d);                                   %tidal wave celerity
    %iterate to determine the Stokes velocity and correct the tidal velocity
    ut0=utt;
    ust0=utt;
    diff = 10;
    while any(diff>0.0001)
        ust = utt.^2./c;
        utt = ut0-ust;
        diff = abs(ust0-ust);
        ust0=ust;
    end

    %update values in TidalCycleHydro table
    dst.TidalCycleHydro.Elevation = zxt;
    dst.TidalCycleHydro.TidalVel = utt;
    dst.TidalCycleHydro.RiverVel = urt;
    dst.TidalCycleHydro.StokesVel = ust;

    %additional derived along-channel properties --------------------------
    u1=max(utt,[],1);   u2=min(utt,[],1);     
    Ux=max(abs(u1),abs(u2));           %tidal velocity amplitude 
    urx = trapz(delt,urt,1)/(T);       %average along-channel river velocity
    usx = Ux.^2/2./(sqrt(g.*Hmx));     %estimate of the Stoke's drift velocity
   
    %phase lag of elevation relative to velocity    
    phase = zeros(1,xint);  pkph = phase;  isp = false; %creates plot if true
    for j=1:xint
        [phase(j),pkph(j)] = cst_phaselag(zxt(:,j),utt(:,j),t,isp);   %phase lag (s)
    end
    eAx = phase/T*2*pi(); %ratio of csa convergence length to tidal wavelength (La/lambda)
    % figure('Tag','PlotFig'); plot(x,phase/T,x,pkph/T);

    dataX = {mtlx,ampx,LwHw,Ux,urx,usx,eAx,msx,Aeff};

    %add table of along channel properties (matches similar data set from CSTmodel)
    dsp = setDSproperties();
    dst1 = dstable(dataX{:},'DSproperties',dsp);
    dst1.Dimensions.X = x;               %x-coordinates (distance from mouth)
    dst1.MetaData = 'CSTdataimport';     %Any additional information to be saved;
    dst1.Source = 'Derived from inputs for AlongChannelForm and TidalCycleHydro';
    dst.AlongChannelHydro = dst1;
end

%%
function Wmtl = getWmtl(dst)
    %width at mean tide level as Area/Hydraulic depth if hydraulic
    %depth is not all nans. This is a dependent property in CSTdataimport
    %but the instance has not been assigned when this function called
    if sum(dst.Hmtl,'omitnan')>0               %Hmtl values have been loaded  
        Wmtl = dst.Amtl./dst.Hmtl;
    else
        Wmtl = dst.Wlw+(dst.Whw-dst.Wlw)/2.57; %assume F&A ideal profile
    end
end
%%
function dsp = setDSproperties(~) 
    %define a dsproperties struct and add the model metadata
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]); 
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique

    %struct entries are cell arrays and can be column or row vectors
    %static ouput (mean tide values)
    dsp.Variables = struct(...                       
        'Name',{'MeanTideLevel','TidalElevAmp','LWHWratio',...
                'TidalVelAmp','RiverVel',...
                'StokesDrift','PhaseAngle',...  %additions
                'InterSlope','effHydCSA'},...                        
        'Description',{'Mean water level',...
                       'Tidal elevation amplitude',...
                       'LW/HW ratio',...
                       'Tidal velocity amplitude',...
                       'River flow velocity',...                                
                       'Stokes drift over a tide',...
                       'Phase angle',...                          
                       'Intertidal slope',...
                       'Effective hydraulic CSA'},...
        'Unit',{'mAD','m','-','m/s','m/s','m/s','rad','1:m','m^2'},...                         
        'Label',{'Mean water level (m)',...
                 'Elevation amplitude (m)',...
                 'LW/HW ratio (-)',...
                 'Velocity amplitude (m/s)',...
                 'Velocity (m/s)','Velocity (m/s)',...
                 'Phase angle (rad)','Intertidal slope (1:m)',...
                 'Cross-sectional area (m^2)'},...                         
        'QCflag',repmat({'model'},1,9)); 
    dsp.Row = struct(...
        'Name',{''},...
        'Description',{''},...
        'Unit',{''},...
        'Label',{''},...
        'Format',{''});        
    dsp.Dimensions = struct(...    
        'Name',{'X'},...
        'Description',{'Chainage'},...
        'Unit',{'m'},...
        'Label',{'Distance from mouth (m)'},...
        'Format',{'-'});  
end