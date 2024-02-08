function cst_xt_plot(obj,src)
%
%-------header-------------------------------------------------------------
% NAME
%   cst_xt_plot.m
% PURPOSE
%   plot variations in time or distance on a tab or figure
% USAGE
%   cst_xt_plot(obj,ax)
% INPUTS
%   obj - class handle for CSTrunmodel or CSTdataimport
%   src - handle for Figure or Tab
% OUTPUTS
%   along channel tidal cycle sample by time or distance showing water 
%   levels and velocities
% NOTES 
%   used in CSTmodel as tabPlot for CSTrunmodel and CSTdataimport
% SEE ALSO
%   cst_x_plot.m
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2024
%-------------------------------------------------------------------------
%
    setnames = fieldnames(obj.Data);
    if any(strcmp(setnames,'TidalCycle'))
        dst = obj.Data.TidalCycle;
        if ~isprop(dst,'Elevation')
        dst = activatedynamicprops(dst);
        end
    else
        warndlg('No X-T data found'); return;
    end

    x = dst.Dimensions.X; 
    t = dst.RowNames;            
    plabels.y1 = dst.VariableLabels{1}; %plot labels
    plabels.y2 = dst.VariableLabels{2};
    plabels.subtitle = sprintf('Case: %s',dst.Description);
    
    ptype = questdlg('Type of plot?','XT plot','X @ T','T @ X','X @ T');
    if strcmp('X @ T',ptype)
        xax = x;  %assign x-axis variable as x
        svar = t; %slider selects t value to plot
        plabels.x = dst.DimensionLabels{1};
        plabels.title = 'Along-channel Variation at time, T';                
        stxt = 'Time = ';
    else
        xax = t;  %assign x-axis variable as t
        svar = x; %slider selects x value to plot
        plabels.x = dst.TableRowName;
        plabels.title = 'Time Variation at distance, X';
        stxt = 'Distance = ';
    end
    
    ht = findobj(src,'Type','axes');
    delete(ht);
    ax = axes('Parent',src,'Tag','PlotFigAxes');
    ax.Position = [0.12,0.18,0.76,0.7]; %make space for slider bar
    hm = setSlideControl(obj,src,ptype,svar,dst,stxt);
    
    pinput = getPlotInput(obj,dst,ptype,1);
    setPlot(obj,ax,xax,pinput,plabels);
    hp = setDataSources(obj,ax);
    
    ax.YLimMode = 'manual';
    setYaxisLimits(obj,ax,dst)
    nint = length(svar);
    if isdatetime(svar) || isduration(svar)
        svar = time2num(svar);
    end
    Mframes(nint,1) = getframe(gcf);
    Mframes(1,1) = getframe(gcf);
    for i=2:nint
        pinput = getPlotInput(obj,dst,ptype,i); %#ok<NASGU>
        refreshdata(hp,'caller')                
        hm(1).Value = svar(i);
        hm(3).String = string(string(svar(i)));
        drawnow;                 
        Mframes(i,1) = getframe(gcf); %NB print function allows more control of resolution 
    end
    obj.ModelMovie = Mframes;
    hold(ax,'off')
end

%%
function pinput = getPlotInput(~,dst,ptype,jxt)
    %get the variables for the selected x or t value 
    varnames = dst.VariableNames;
    for i=1:length(varnames)
        var = dst.(varnames{i});
        if strcmp('X @ T',ptype)
            pinput.(varnames{i}) = var(jxt,:);
        else
            pinput.(varnames{i}) = var(:,jxt);
        end
    end
end

%%
function hp = setDataSources(~,ax)
    %set the source variables to be used for each plot line
    yyaxis 'left';
    hpl = ax.Children;            
    yyaxis 'right';
    hpr = ax.Children;
    hp = [hpr;hpl];
    for i=1:length(hp)
        hp(i).YDataSource = sprintf('pinput.%s',hp(i).Tag);
    end
end

%%
function setPlot(~,ax,xax,pin,plabels)
    %generate the plot for selected subset of x-t data   
    if isfield(pin,'Elevation')
        yyaxis left    
        plot(ax,xax,pin.Elevation,'-b','DisplayName','Elevation','Tag','Elevation');   
        ylabel(plabels.y1)
    end

    if isfield(pin,'Velocity')
        yyaxis right
	    plot(ax,xax,pin.Velocity,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity','Tag','Velocity')%plot tidal velocity
        if isfield(pin,'RiverVel')
	        hold on
            plot(ax,xax,pin.RiverVel,'--','Color',mcolor('green'),'DisplayName','River velocity','Tag','RiverVel') %plot river velocity
            plot(ax,xax,pin.StokesVel,'--','Color',mcolor('yellow'),'DisplayName','Stokes velocity','Tag','StokesVel') %plot river velocity
            hold off
        end
    end

    legend('Location','best') 
    ylabel(plabels.y2)
    xlabel(plabels.x)
    title(plabels.title)
    subtitle(plabels.subtitle)
end

%%
function setYaxisLimits(obj,ax,dst)
    %set the Y axis limits so they do not change when plot updated
    if matches('Elevation',dst.VariableNames)
        setHaxisLimits(obj,ax,dst)
    end
    %
    if matches('Velocity',dst.VariableNames)
        setUaxisLimits(obj,ax,dst)
    end
end 

%%
function setHaxisLimits(~,ax,dst)
    %set the Y axis limits so they do not change when plot updated
    h = dst.Elevation;
    lim1 = floor(min(h,[],'All'));
    lim2 = ceil(max(h,[],'All'));
    yyaxis left          %fix left y-axis limits
    ax.YLim = [lim1,lim2];
end 

%%
function setUaxisLimits(~,ax,dst)
    %set the Y axis limits so they do not change when plot updated
    varnames = dst.VariableNames;
    AllV = [];
    for i=1:length(varnames)
        AllV = [AllV,dst.(varnames{i})];
    end
    AllV(AllV>3) = NaN;  %apply mask to remove excessively             
    AllV(AllV<-3) = NaN; %large velocities (eg infinity)
    lim1 = floor(min(AllV,[],'All'));
    lim2 = ceil(max(AllV,[],'All'));
    yyaxis right         %fix right y-axis limits
    ax.YLim = [lim1,lim2];
end 

%%
function hm = setSlideControl(obj,hfig,ptype,svar,dst,stxt)
    %intialise slider to set different Q values   
    invar = struct('sval',[],'smin',[],'smax',[],'size', [],...
                   'callback','','userdata',[],'position',[],...
                   'stxext','','butxt','','butcback','');            
    invar.sval = svar(1);      %initial value for slider 
    invar.smin = svar(1);     %minimum slider value
    invar.smax = svar(end);     %maximum slider value
    invar.callback = @(src,evt)updateXTplot(obj,ptype,src,evt); %callback function for slider to use
    invar.userdata = dst;  %pass userdata if required 
    invar.position = [0.15,0.005,0.60,0.04]; %position of slider
    invar.stext = stxt;   %text to display with slider value, if included          
    invar.butxt =  'Save';    %text for button if included
    invar.butcback = @(src,evt)saveanimation2file(obj.ModelMovie,src,evt); %callback for button
    hm = setfigslider(hfig,invar);   
end      

%%
function updateXTplot(obj,ptype,src,~)
    %use the updated slider value to adjust the CST plot
    sldui = findobj(src.Parent,'Tag','figslider');
    dst = sldui.UserData;     %recover userdata
    if strcmp('X @ T',ptype)
        svar = dst.RowNames;
        if isdatetime(svar)  || isduration(svar)
            svar = time2num(svar);
        end
    else
        svar = dst.Dimensions.X;
    end
    
    %use slider value to find the nearest set of results
    stxt = findobj(src.Parent,'Tag','figsliderval');
    idx = find(svar>src.Value,1,'first');            
    XT = svar(idx);
    stxt.String = num2str(XT);     %update slider text

    %figure axes and update plot
    ax = findobj(src.Parent,'Tag','PlotFigAxes'); 
    pinput = getPlotInput(obj,dst,ptype,idx);
    isok = ~any(cellfun(@isempty,struct2cell(pinput)));
    if ~isok, return; end %trap moving cursor to end of slider
    yyaxis 'left';
    hpl = ax.Children;            
    yyaxis 'right';
    hpr = ax.Children;
    hp = [hpr;hpl];
    refreshdata(hp,'caller');
    drawnow;
end






