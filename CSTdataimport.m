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
    end
%%
    methods 
        function obj = CSTdataimport()     
            %class constructor
            %initialise list of available input file formats. Format is:
            %{'label 1','formatfile name 1';'label 2','formatfile name 2'; etc}
            obj.DataFormats = {'Default format','cst_dataformat'};
            %define file specification, format is: {multiselect,file extension types}
            obj.FileSpec = {'off','*.txt;*.csv'};     
            obj.idFormat = 1;
        end
    end
%%   
    methods (Static)
        function loadData(muicat,classname)
            %load user data set from one or more files
            obj = CSTdataimport();
            
            msg1 = 'You will be prompted to load 3 files,';
            msg2 = 'in the following order:';
            msg3 = '1) Along channel properties, msl, amp, etc';
            msg4 = '2) X-T variation in water level';
            msg5 = '3) X-T variation in velocity';
            msg6 = 'Press Cancel if water level or velocity not available';
            msg7  = 'X & T intervals must be the same in all files';
            msgtxt = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s',msg1,msg2,...
                                                msg3,msg4,msg5,msg6,msg7);
            hm = msgbox(msgtxt,'Load file');
            waitfor(hm)

            [fname,path,nfiles] = getfiles('MultiSelect',obj.FileSpec{1},...
                'FileType',obj.FileSpec{2},'PromptText','Select X-properties file:');
            if nfiles==0
                return;
            else
                filename = [path fname];    %single select returns char
            end
            
            %get data
            funcname = 'getData';
            [dst,ok] = callFileFormatFcn(obj,funcname,obj,filename);
            if ok<1 || isempty(dst), return; end
            %assign metadata about data, Note dst can be a struct
            dst = updateSource(dst,filename,1);

            setDataSetRecord(obj,muicat,dst,'data');
            getdialog(sprintf('Data loaded in class: %s',classname));
            %--------------------------------------------------------------
            function dst = updateSource(dst,filename,jf)
                if isstruct(dst)
                    fnames = fieldnames(dst);
                    for i=1:length(fnames)
                        dst.(fnames{i}).Source{jf,1} = filename;
                    end
                else
                    dst.Source{jf,1} = filename;
                end
            end
        end         
    end
%%
    methods
        function tabPlot(obj,src)
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
            %generate plot for display on Q-Plot tab
            adst = [];
            setnames = fieldnames(obj.Data);
            if any(strcmp(setnames,'TidalCycleElevation'))
                dst.H = obj.Data.TidalCycleElevation;
                if ~isprop(dst(1),'Elevation')
                    dst.H = activatedynamicprops(dst.H);
                end
                plabels.y1 = dst.H.VariableLabels{1}; %plot labels
                adst = dst.H;  %used to set axes values
            end
            
            if any(strcmp(setnames,'TidalCycleVelocity'))
                dst.U = obj.Data.TidalCycleVelocity;
                if ~isprop(dst(1),'Velocity')
                    dst.U = activatedynamicprops(dst.U);
                end
                plabels.y2 = dst.U.VariableLabels{1};
                adst = dst.U;  %used to set axes values
            end

            if isempty(adst), warndlg('No X-T data'); return; end
 
            x = adst.Dimensions.X; 
            t = adst.RowNames;            

            ptype = questdlg('Type of plot?','XT plot','X @ T','T @ X','X @ T');
            if strcmp('X @ T',ptype)
                xax = x;  %assign x-axis variable as x
                svar = t; %slider selects t value to plot
                plabels.x = adst.DimensionLabels{1};
                plabels.title = 'Along-channel Variation at time, T';                
                stxt = 'Time = ';
            else
                xax = t;  %assign x-axis variable as t
                svar = x; %slider selects x value to plot
                plabels.x = adst.TableRowName;
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
            if isfield(dst,'H')
                setHaxisLimits(obj,ax,dst)
            end
            %
            if isfield(dst,'U')
                setUaxisLimits(obj,ax,dst)
            end
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
            warndlg('No quality control defined for this format');
            output = [];    %if no QC implemented in dataQC
        end      
    end
%%    
    methods (Access = private)
        function pinput = getPlotInput(~,dst,ptype,jxt)
            %get the variables for the selected x or t value
            if isfield(dst,'H')
                h = dst.H.Elevation;
                if strcmp('X @ T',ptype)
                    pinput.h = h(jxt,:);
                else
                    pinput.h = h(:,jxt);
                end 
            else
                pinput.h = [];
            end
            %
            if isfield(dst,'U')
                U = dst.U.Velocity;
                if strcmp('X @ T',ptype)
                    pinput.U = U(jxt,:);
                else
                    pinput.U = U(:,jxt);
                end   
            else
                pinput.U = [];
            end
                     
        end
%%
        function hp = setDataSources(~,ax)
            %set the source variables to be used for each plot line
            yyaxis 'left';
            hpl = ax.Children;   
            if ~isempty(hpl)
                hpl.YDataSource = 'pinput.h';
            end
            yyaxis 'right';
            hpr = ax.Children;
            if ~isempty(hpr)
                hpr.YDataSource = 'pinput.U';  
            end
            hp = [hpr;hpl];
        end
%%
        function setPlot(~,ax,xax,pin,plabels)
            %generate the plot for selected subset of x-t data            
            yyaxis left
            if ~isempty(pin.h)
                plot(ax,xax,pin.h,'-b','DisplayName','Elevation');   
                ylabel(plabels.y1)
            end
            yyaxis right
            if ~isempty(pin.U)
                plot(ax,xax,pin.U,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity')%plot tidal velocity
                ylabel(plabels.y2)
            end
            legend('Location','best')             
            xlabel(plabels.x)
            title(plabels.title)
        end
%%
        function channelOuputPlot(obj,ax)
            %default graphic for X-Plot tab or stand-alone figure
            dst = obj.Data.AlongEstuary;
            x = dst.Dimensions.X; 
            z = dst.MeanTideLevel;  %mean tide level
            a = dst.TidalElevAmp;   %tidal amplitude
			U = dst.TidalVelAmp;    %tidal velocity amplitude
            % v = dst.RiverVel;       %river velocity 
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
			% plot(x,v,'--','Color',mcolor('green'),'DisplayName','River velocity') %plot river velocity
            hold off
            xlabel('Distance from mouth (m)'); 
            ylabel('Velocity (m/s)'); 
			legend('Location','best');			
            title ('Along channel variation');
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plo
        end        
%%
        function setHaxisLimits(~,ax,dst)
            %set the Y axis limits so they do not change when plot updated
            h = dst.H.Elevation;
            lim1 = floor(min(h,[],'All'));
            lim2 = ceil(max(h,[],'All'));
            yyaxis left          %fix left y-axis limits
            ax.YLim = [lim1,lim2];
        end 
%%
        function setUaxisLimits(~,ax,dst)
            %set the Y axis limits so they do not change when plot updated
            U = dst.U.Velocity;
            U(U>3) = NaN;  %apply mask to remove excessively             
            U(U<-3) = NaN; %large velocities (eg infinity)
            lim1 = floor(min(U,[],'All'));
            lim2 = ceil(max(U,[],'All'));
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
            adst = struct2cell(dst);
            if strcmp('X @ T',ptype)
                svar = adst{1}.RowNames;
                if isdatetime(svar)  || isduration(svar)
                    svar = time2num(svar);
                end
            else
                svar = adst{1}.Dimensions.X;
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