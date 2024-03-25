function cst_formplot(obj,src,mobj)
%
%-------header-------------------------------------------------------------
% NAME
%   cst_formplot.m
% PURPOSE
%   generate plot for display on Form tab
% USAGE
%   cst_formplot(obj,src,mobj)
% INPUTS
%   obj - class handle for CSTrunmodel or CSTdataimport
%   src - handle for Figure or Tab
%   mobj - handle to model
% OUTPUTS
%   along-channel graphic areas, widths and Manning N
% NOTES 
%   plots the model form if defined in CSTparameters and the observed form 
%   if loaded in CSTformprops
% SEE ALSO
%   cst_xt_plot.m, cst_x_plot
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2024
%-------------------------------------------------------------------------
%
    ht = findobj(src,'Type','axes');
    delete(ht);
    ax = axes('Parent',src,'Tag','Form');
    %create three subplots
    s1 = subplot(3,1,1,ax);
    s2 = subplot(3,1,2);
    s3 = subplot(3,1,3);

    dst = obj.AlongChannelForm; 
    if ~isempty(dst)            
        %plot observed data from CSTformparams
        if ~isprop(dst,'Amtl')
            dst = activatedynamicprops(dst);
        end
        X = dst.Dimensions.X;
        subplot(s1)
        plot(X,dst.Amtl,'DisplayName','Observed'); %plot distance v CSA
        %
        subplot(s2)
        plot(X,dst.Whw,'DisplayName','High water');%plot distance v Width HW             
        hold on
        plot(X,dst.Wlw,'DisplayName','Low water'); %plot distance v Width LW
        %
        subplot(s3)
        if all(isnan(dst.N))
            plot(X,zeros(size(X)),'DisplayName','Observed');                  
        else
            plot(X,dst.N,'DisplayName','Observed');    %plot distance v N
        end
    end 
    %
    inpobj = getClassObj(mobj,'Inputs','CSTparameters');
    if ~isempty(inpobj) && ~isempty(inpobj.AreaELength)
        %plot model form based on CSTparameters
        Le = inpobj.EstuaryLength;   %estuary length (m)   
        Wm = inpobj.MouthWidth;      %width at mouth (m)
        Lw = inpobj.WidthELength;    %width convergence length (m) =0 import from file
        Am = inpobj.MouthCSA;        %area at mouth (m^2)
        La = inpobj.AreaELength;     %area convergence length (m)  =0 import from file     
        Wr = inpobj.RiverWidth;      %upstream river width (m) 
        Ar = inpobj.RiverCSA;        %upstream river cross-sectional area (m^2)
        xT = inpobj.xTideRiver;      %distance from mouth to estuary/river switch
        N = inpobj.Manning;          %Manning friction coefficient [mouth switch head]
        if exist('X','var')~=1
            X = 0:1000:Le;
        end
        
        Ax = Ar+(Am-Ar)*exp(-X/La); 
        Wx = Wr+(Wm-Wr)*exp(-X/Lw); 
        Ks = interp1([0 xT max(X)],N,X,'linear');
        
        subplot(s1)
        hold on
        plot(X,Ax,'r--','DisplayName','Model'); %plot distance v CSA
        hold off
        subplot(s2)
        hold on
        plot(X,Wx,'r--','DisplayName','Model'); %plot distance v Width
        hold off
        subplot(s3)
        hold on
        plot(X,Ks,'r--','DisplayName','Model'); %plot distance v Manning
        hold off
    end
    %add title, axis labels and legends
    subplot(s1);
    ylabel('Area (m^2)');
    legend
    subplot(s2);
    ylabel('Width (m)');
    legend
    subplot(s3);
    ylabel('Mannings N');
    xlabel('Distance from mouth (m)'); 
    legend
    if isempty(dst)
        sgtitle('Modelled Estuary Form Properties','FontSize',10);
    else
        sgtitle(sprintf('Estuary Form Properties\nFile: %s',...
                dst.Source{1}),'Interpreter','none','FontSize',8); 
    end           

end