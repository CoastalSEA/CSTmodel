classdef CSTdataimport < muiDataSet  
%
%-------class help---------------------------------------------------------
% NAME
%   CSTdataimport.m
% PURPOSE
%   Class to import a data set, adding the results to dstable
%   and a record in a dscatlogue (as a property of muiCatalogue)
% USAGE
%   obj = CSTdataimport()
% SEE ALSO
%   inherits muiDataSet and uses dstable and dscatalogue
%   format files used to load data of varying formats (variables and file format)
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
%    
    properties  
        %inherits Data, RunParam, MetaData and CaseIndex from muiDataSet
        % importing data requires muiDataSet propertiesm DataFormats and
        % FileSpec to be defined in class constructor.
        %Additional properties:  
    end
    
    methods 
        function obj = CSTdataimport()     
            %class constructor
            %initialise list of available input file formats. Format is:
            %{'label 1','formatfile name 1';'label 2','formatfile name 2'; etc}
            obj.DataFormats = {'Default format','cst_dataformat'};
            %define file specification, format is: {multiselect,file extension types}
            obj.FileSpec = {'off','*.txt;*.csv'};        
        end
%%
        function tabPlot(obj,src)
            %generate plot for display on Q-Plot tab
            dst = obj.Data.AlongEstuaryValues;
            x = dst.Dimensions.X; 
            z = dst.MeanTideLevel;  %mean tide level
            a = dst.TidalElevAmp;  %tidal amplitude
			U = dst.TidalVelAmp;  %tidal velocity amplitude
            d = dst.HydDepth;  %hydraulic depth
            ht = findobj(src,'Type','axes');
            delete(ht);
            ax = axes('Parent',src,'Tag','Q-Plot');
			yyaxis left
            plot(x,z,'-r');             %plot time v elevation
            hold on
            plot(x,(z+a),'-.b')       %plot high water level
            plot(x,(z-a),'-.b')       %plot low water level
			plot(x,(z-d),'-k');       %hydraulic depth below mean tide level
            ylabel('Elevation (mOD)'); 
			yyaxis right
			plot(x,U,'--','Color',mcolor('orange')) %plot tidal velocity
% 			plot(x,v,'--','Color',mcolor('green'))) %plot river velocity
            hold off
            xlabel('Distance from mouth (m)'); 
            ylabel('Velocity (m/s)'); 
			legend('MTL','HWL','LWL','Hydraulic depth',...
                'Tidal velocity','Location','best');			
            title ('Along channel variation');
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plot
        end     
%%
        function xt_tabPlot(obj,src) 
            %generate plot for display on Q-Plot tab
            dst = obj.Data.TidalCycleValues;
            if ~isprop(dst,'Elevation')
                dst = activatedynamicprops(dst);
            end
            x = dst.Dimensions.X; 
            t = dst.RowNames;            
            plabels.y1 = dst.VariableLabels{1}; %plot labels
            plabels.y2 = dst.VariableLabels{2};
            
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
            ax.Position = [0.16,0.18,0.65,0.75]; %make space for slider bar
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
            hold(ax,'off')
        end
%%
        function output = dataQC(obj)
            %quality control a dataset
            % datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
            % dst = obj.Data.(datasetname);      %selected dstable
            warndlg('No qualtiy control defined for this format');
            output = [];    %if no QC implemented in dataQC
        end      
    end
%%    
    methods (Access = private)
        function pinput = getPlotInput(~,dst,ptype,jxt)
            %get the variables for the selected x or t value
            h = dst.Elevation;
            U = dst.Velocity;
            if strcmp('X @ T',ptype)
                pinput.h = h(jxt,:);
                pinput.U = U(jxt,:);
            else
                pinput.h = h(:,jxt);
                pinput.U = U(:,jxt);
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
            hp(2).YDataSource = 'pinput.h';
            hp(1).YDataSource = 'pinput.U';  
        end
%%
        function setPlot(~,ax,xax,pin,plabels)
            %generate the plot for selected subset of x-t data            
            yyaxis left
            plot(ax,xax,pin.h,'-b','DisplayName','Elevation');   
            ylabel(plabels.y1)
            yyaxis right
			plot(ax,xax,pin.U,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity')%plot tidal velocity
            legend('Location','best') 
            ylabel(plabels.y2)
            xlabel(plabels.x)
            title(plabels.title)
        end
%%
        function setYaxisLimits(~,ax,dst)
            %set the Y axis limits so they do not change when plot updated
            h = dst.Elevation;
            U = dst.Velocity;
            U(U>3) = NaN;  %apply mask to remove excessively             
            U(U<-3) = NaN; %large velocities (eg infinity)
            lim1 = floor(min(h,[],'All'));
            lim2 = ceil(max(h,[],'All'));
            lim3 = floor(min(U,[],'All'));
            lim4 = ceil(max(U,[],'All'));
            yyaxis left          %fix left y-axis limits
            ax.YLim = [lim1,lim2];
            yyaxis right         %fix right y-axis limits
            ax.YLim = [lim3,lim4];
        end  
%%
        function hm = setSlideControl(obj,hfig,ptype,svar,dst,stxt)
            %intialise slider to set different Q values   
            invar = struct('sval',[],'smin',[],'smax',[],...
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
            pinput = getPlotInput(obj,dst,ptype,idx); %#ok<NASGU>
            yyaxis 'left';
            hpl = ax.Children;            
            yyaxis 'right';
            hpr = ax.Children;
            hp = [hpr;hpl];
            refreshdata(hp,'caller');
            drawnow;
        end    
    end
end