classdef CSTrunmodel < muiDataSet                        
%
%-------class help---------------------------------------------------------
% NAME
%   CSTrunmodel.m
% PURPOSE
%   Calculate the mean tide level and tidal amplitude along an estuary
%   only works for a single channel (not a network)
% NOTE
%   Default CSTrunparams.DistInt set to 5000. Reducing distance increases 
%   resolution but also run time and sensitivity of solution
% SEE ALSO
%   muiDataSet
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2021
%--------------------------------------------------------------------------
%     
    properties
        %inherits Data, RunParam, MetaData and CaseIndex from muiDataSet
        %Additional properties:     
    end
    
    properties (Transient)
        ModelMovie
    end
    
    methods (Access = private)
        function obj = CSTrunmodel()                      
            %class constructor
        end
    end      
%%
    methods (Static)        
%--------------------------------------------------------------------------
% Model implementation
%--------------------------------------------------------------------------         
        function obj = runModel(mobj)
            %function to run a simple 2D diffusion model
            obj = CSTrunmodel;                           
            [dsp1,dsp2] = modelDSproperties(obj);
            
            %now check that the input data has been entered
            %isValidModel checks the InputHandles defined in ModelUI
            if ~isValidModel(mobj, metaclass(obj).Name)  
                warndlg('Use Setup to define model input parameters');
                return;
            end
            muicat = mobj.Cases;
            %assign the run parameters to the model instance
            %may need to be after input data selection to capture caserecs
            setRunParam(obj,mobj);
%--------------------------------------------------------------------------
% Model code
%--------------------------------------------------------------------------
            %input parameters for model
            inpobj = getClassObj(mobj,'Inputs','CSTparameters');
            rnpobj = getClassObj(mobj,'Inputs','CSTrunparams');
            estobj = getClassObj(mobj,'Inputs','CSTformprops');  %can be empty
            try
                [resX,xy,resXT,mtime] = cst_model(inpobj,rnpobj,estobj);
            catch
                %remove the waitbar if program did not complete
                hw = findall(0,'type','figure','tag','TMWWaitbar');
                delete(hw);
                warndlg('No solution found in cst_model');
                delete(obj);
                return;
            end
            %
            if isempty(resX), return; end  %probable error in data input
            
            %now assign results to object properties  
            modeltime = seconds(mtime{1});  %durataion data for rows 
            modeltime.Format = 'h';
%--------------------------------------------------------------------------
% Assign model output to a dstable using the defined dsproperties meta-data
%--------------------------------------------------------------------------                   
            %each variable should be an array in the 'results' cell array
            %if model returns single variable as array of doubles, use {results}
            dst1 = dstable(resX{:},'DSproperties',dsp1);
            dst1.Dimensions.X = xy{:,1};     %grid x-coordinate
            
            dst2 = dstable(resXT{:},'RowNames',modeltime,'DSproperties',dsp2);
            dst2.Dimensions.X = xy{:,1};     %grid x-coordinate
            
%--------------------------------------------------------------------------
% Save results
%--------------------------------------------------------------------------                        
            %assign metadata about model
            dst1.Source = metaclass(obj).Name;
%             dst1.MetaData = 'Any additional information to be saved';
            dst2.Source = metaclass(obj).Name;
%             dst2.MetaData = 'Any additional information to be saved';
            
            dst.AlongEstuaryValues = dst1;
            dst.TidalCycleValues = dst2;            
            %save results
            setDataSetRecord(obj,muicat,dst,'model');
            getdialog('Run complete');
        end
%%
        function obj = getCSTrunmodel()
            %provide access to CSTrunmodel class instance
            %used in CSTdataimport to access tab plotting functions
            obj = CSTrunmodel;
        end
    end
%%
    methods
        function tabPlot(obj,src) %abstract class for muiDataSet
            %generate plot for display on Q-Plot tab            
            if strcmp(src.Tag,'FigButton')
                hfig = figure('Tag','PlotFig');
                ax = axes('Parent',hfig,'Tag','PlotFig','Units','normalized');
                channelOuputPlot(obj,ax);                
            else
                ht = findobj(src,'Type','axes');
                delete(ht);
                ax = axes('Parent',src,'Tag','Q-Plot');
                channelOuputPlot(obj,ax); 
                hb = findobj(src,'Tag','FigButton');
                if isempty(hb)
                    %button to create plot as stand-alone figure
                    uicontrol('Parent',src,'Style','pushbutton',...
                        'String','>Figure','Tag','FigButton',...
                        'TooltipString','Create plot as stand alone figure',...
                        'Units','normalized','Position',[0.88 0.95 0.10 0.044],...
                        'Callback',@(src,evdat)tabPlot(obj,src));
                else
                    hb.Callback = @(src,evdat)tabPlot(obj,src);
                end
            end
        end
%%
        function xt_tabPlot(obj,src) 
            %generate plot for display on xt-Plot tab
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
            obj.ModelMovie = Mframes;
            hold(ax,'off')
        end
    end 
%%    
    methods (Access = private)
        function pinput = getPlotInput(~,dst,ptype,jxt)
            %get the variables for the selected x or t value
            h = dst.Elevation;
            U = dst.Velocity;
            v = dst.RiverVel;
            s = dst.StokesVel;
            if strcmp('X @ T',ptype)
                pinput.h = h(jxt,:);
                pinput.U = U(jxt,:);
                pinput.v = v(jxt,:);
                pinput.s = s(jxt,:);
            else
                pinput.h = h(:,jxt);
                pinput.U = U(:,jxt);
                pinput.v = v(:,jxt);
                pinput.s = s(:,jxt);
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
            hp(4).YDataSource = 'pinput.h';
            hp(3).YDataSource = 'pinput.U'; 
            hp(2).YDataSource = 'pinput.v'; 
            hp(1).YDataSource = 'pinput.s'; 
        end
%%
        function setPlot(~,ax,xax,pin,plabels)
            %generate the plot for selected subset of x-t data            
            yyaxis left
            plot(ax,xax,pin.h,'-b','DisplayName','Elevation');   
            ylabel(plabels.y1)
            yyaxis right
            hold on
			plot(ax,xax,pin.U,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity')%plot tidal velocity
			plot(ax,xax,pin.v,'--','Color',mcolor('green'),'DisplayName','River velocity') %plot river velocity
            plot(ax,xax,pin.s,'--','Color',mcolor('yellow'),'DisplayName','Stokes velocity') %plot river velocity
            hold off
            legend('Location','best') 
            ylabel(plabels.y2)
            xlabel(plabels.x)
            title(plabels.title)
        end
%%
        function channelOuputPlot(obj,ax)
            %default graphic for X-Plot tab or stand-alone figure
            dst = obj.Data.AlongEstuaryValues;
            x = dst.Dimensions.X; 
            z = dst.MeanTideLevel;  %mean tide level
            a = dst.TidalElevAmp;   %tidal amplitude
			U = dst.TidalVelAmp;    %tidal velocity amplitude
			v = dst.RiverVel;       %river velocity 
			d = dst.HydDepth;       %hydraulic depth
            %gerenate plot
            yyaxis left
            plot(x,z,'-r','DisplayName','MTL'); %plot time v elevation
            hold on
            plot(x,(z+a),'-.b','DisplayName','HWL')%plot high water level
            plot(x,(z-a),'-.b','DisplayName','LWL')%plot low water level
			plot(x,(z-d),'-k','DisplayName','Hydraulic depth')%hydraulic depth below mean tide level
            ylabel('Elevation (mOD)'); 
			yyaxis right
			plot(x,U,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity')%plot tidal velocity
			plot(x,v,'--','Color',mcolor('green'),'DisplayName','River velocity') %plot river velocity
            hold off
            xlabel('Distance from mouth (m)'); 
            ylabel('Velocity (m/s)'); 
			legend('Location','best');			
            title ('Along channel variation');
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plo
        end
%%
        function setYaxisLimits(~,ax,dst)
            %set the Y axis limits so they do not change when plot updated
            h = dst.Elevation;
            U = dst.Velocity;
            v = dst.RiverVel;
            s = dst.StokesVel;
            AllV = [U,v,s];
            AllV(AllV>3) = NaN;  %apply mask to remove excessively             
            AllV(AllV<-3) = NaN; %large velocities (eg infinity)
            lim1 = floor(min(h,[],'All'));
            lim2 = ceil(max(h,[],'All'));
            lim3 = floor(min(AllV,[],'All'));
            lim4 = ceil(max(AllV,[],'All'));
            yyaxis left          %fix left y-axis limits
            ax.YLim = [lim1,lim2];
            yyaxis right         %fix right y-axis limits
            ax.YLim = [lim3,lim4];
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
%%
        function [dsp1,dsp2] = modelDSproperties(~) 
            %define a dsproperties struct and add the model metadata
            dsp1 = struct('Variables',[],'Row',[],'Dimensions',[]); 
            dsp2 = dsp1;
            %define each variable to be included in the data table and any
            %information about the dimensions. dstable Row and Dimensions can
            %accept most data types but the values in each vector must be unique
            
            %struct entries are cell arrays and can be column or row vectors
            %static ouput (mean tide values)
            dsp1.Variables = struct(...                       
                'Name',{'MeanTideLevel','TidalElevAmp','TidalVelAmp',...
                            'RiverVel','HydDepth'},...
                'Description',{'Mean water level',...
                            'Tidal elevation amplitude',...
                            'Tidal velocity amplitude',...
                            'River flow velocity',...
                            'Hydraulic depth'},...
                'Unit',{'m','m','m/s','m/s','m'},...
                'Label',{'Mean water level (m)',...
                         'Elevation amplitude (m)',...
                         'Velocity amplitude (m/s)',...
                         'Velocity (m/s)','Depth (m)'},...
                'QCflag',repmat({'model'},1,5)); 
            dsp1.Row = struct(...
                'Name',{''},...
                'Description',{''},...
                'Unit',{''},...
                'Label',{''},...
                'Format',{''});        
            dsp1.Dimensions = struct(...    
                'Name',{'X'},...
                'Description',{'Chainage'},...
                'Unit',{'m'},...
                'Label',{'Distance from mouth (m)'},...
                'Format',{'-'});  
            
            %dynamic values
            dsp2.Variables = struct(...                       
                'Name',{'Elevation','Velocity','RiverVel','StokesVel'},...
                'Description',{'Elevation','Tidal velocity',...
                               'River velocity','Stokes drift velocity'},...
                'Unit',{'m','m/s','m/s','m/s'},...
                'Label',{'Elevation (m)','Velocity (m/s)','Velocity (m/s)',...
                         'Velocity (m/s)'},...
                'QCflag',repmat({'model'},1,4)); 
            dsp2.Row = struct(...
                'Name',{'Time'},...
                'Description',{'Time'},...
                'Unit',{'h'},...
                'Label',{'Time (h)'},...
                'Format',{'h'});         
            dsp2.Dimensions = struct(...    
                'Name',{'X'},...
                'Description',{'Chainage'},...
                'Unit',{'m'},...
                'Label',{'Distance from mouth (m)'},...
                'Format',{'-'});  
        end
    end    
end