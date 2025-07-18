classdef CSTmodel < muiModelUI                     
%
%-------class help---------------------------------------------------------
% NAME
%   CSTmodel.m
% PURPOSE
%   Main UI for CSTmodel interface, which implements the 
%   muiModelUI abstract class to define main menus.
% SEE ALSO
%   Abstract class muiModelUI.m and tools provided in muitoolbox
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2021
%--------------------------------------------------------------------------
% 
    properties  (Access = protected)
        %implement properties defined as Abstract in muiModelUI
        vNumber = '2.20'
        vDate   = 'May 2024'
        modelName = 'CSTmodel'                     
        %Properties defined in muiModelUI that need to be defined in setGui
        % ModelInputs  %classes required by model: used in isValidModel check 
        % DataUItabs   %struct to define type of muiDataUI tabs for each use                         
    end
    
    methods (Static)
        function obj = CSTmodel                       
            %constructor function initialises GUI
            isok = check4muitoolbox(obj);
            if ~isok, return; end
            %
            obj = setMUI(obj);             
        end
    end
%% ------------------------------------------------------------------------
% Definition of GUI Settings
%--------------------------------------------------------------------------  
    methods (Access = protected)
        function obj = setMUI(obj)
            %initialise standard figure and menus    
            %classes required to run model, format:
            %obj.ModelInputs.<model classname> = {'Param_class1',Param_class2',etc} parameters classnames 
            obj.ModelInputs.CSTrunmodel = {'CSTparameters','CSTrunparams'};
            %tabs to include in DataUIs for plotting and statistical analysis
            %select which of the options are needed and delete the rest
            %Plot options: '2D','3D','4D','2DT','3DT','4DT'
            obj.DataUItabs.Plot = {'2D','3D','2DT','3DT'};  
            %Statistics options: 'General','Timeseries','Taylor','Intervals'
            obj.DataUItabs.Stats = {'General','Timeseries','Taylor'};  
            
            modelLogo = 'CST_logo.jpg';  %default splash figure - edit to alternative
            initialiseUI(obj,modelLogo); %initialise menus and tabs                  
        end    
        
%% ------------------------------------------------------------------------
% Definition of Menu Settings
%--------------------------------------------------------------------------
        function menu = setMenus(obj)
            %define top level menu items and any submenus
            %MenuLabels can any text but should avoid these case-sensitive 
            %reserved words: "default", "remove", and "factory". If label 
            %is not a valid Matlab field name this the struct entry
            %is modified to a valid name (eg removes space if two words).
            %The 'gcbo:' Callback text triggers an additional level in the 
            %menu. Main menu labels are defined in sequential order and 
            %submenus in order following each brach to the lowest level 
            %before defining the next branch.         
                                                            
            MenuLabels = {'File','Tools','Project','Setup','Run',...
                                                        'Analysis','Help'};
            menu = menuStruct(obj,MenuLabels);  %create empty menu struct
            %
            %% File menu --------------------------------------------------
             %list as per muiModelUI.fileMenuOptions
            menu.File.List = {'New','Open','Save','Save as','Exit'};
            menu.File.Callback = repmat({@obj.fileMenuOptions},[1,5]);
            
            %% Tools menu -------------------------------------------------
            %list as per muiModelUI.toolsMenuOptions
            menu.Tools(1).List = {'Refresh','Clear all'};
            menu.Tools(1).Callback = {@obj.refresh, 'gcbo;'};  
            
            % submenu for 'Clear all'
            menu.Tools(2).List = {'Model','Figures','Cases'};
            menu.Tools(2).Callback = repmat({@obj.toolsMenuOptions},[1,3]);

            %% Project menu -----------------------------------------------
            menu.Project(1).List = {'Project Info','Cases','Export/Import'};
            menu.Project(1).Callback = {@obj.editProjectInfo,'gcbo;','gcbo;'};
            
            %list as per muiModelUI.projectMenuOptions
            % submenu for Scenarios
            menu.Project(2).List = {'Edit Description','Edit DS properties','Edit Data Set',...
                                    'Save Data Set','Delete Case','Reload Case',...
                                    'View Case Settings'};                                               
            menu.Project(2).Callback = repmat({@obj.projectMenuOptions},[1,7]);
            menu.Project(2).Separator = {'off','on','off','off','off','on','off'};
            
            % submenu for 'Export/Import'                                          
            menu.Project(3).List = {'Export Case','Import Case'};
            menu.Project(3).Callback = repmat({@obj.projectMenuOptions},[1,2]);
            
            %% Setup menu -------------------------------------------------
            menu.Setup(1).List = {'Model Parameters','Run Parameters',...
                     'Estuary Properties','Import Data','User Data','Model Constants'};                                    
            menu.Setup(1).Callback = [repmat({@obj.setupMenuOptions},[1,5]),...
                                          {@obj.setupMenuOptions}];
            %add separators to menu list (optional - default is off)
            menu.Setup(1).Separator = {'off','off','off','on','off','on'}; %separator preceeds item
            
            %% Run menu ---------------------------------------------------
            menu.Run(1).List = {'Run Model','Derive Output'};
            menu.Run(1).Callback = repmat({@obj.runMenuOptions},[1,2]);
            
            %% Plot menu --------------------------------------------------  
            menu.Analysis(1).List = {'Plots','Statistics'};
            menu.Analysis(1).Callback = repmat({@obj.analysisMenuOptions},[1,2]);
            
            %% Help menu --------------------------------------------------
            menu.Help.List = {'Documentation','Manual'};
            menu.Help.Callback = repmat({@obj.Help},[1,2]);
            
        end
        
%% ------------------------------------------------------------------------
% Definition of Tab Settings
%--------------------------------------------------------------------------
        function [tabs,subtabs] = setTabs(obj)
            %define main tabs and any subtabs required. struct field is 
            %used to set the uitab Tag (prefixed with sub for subtabs). 
            %Order of assignment to struct determines order of tabs in figure.
            %format for tabs: 
            %    tabs.<tagname> = {<tab label>,<callback function>};
            %format for subtabs: 
            %    subtabs.<tagname>(i,:) = {<subtab label>,<callback function>};
            %where <tagname> is the struct fieldname for the top level tab.
            tabs.Cases  = {'   Cases  ',@obj.refresh};        
            tabs.Inputs = {'  Inputs  ',@obj.InputTabSummary};
            tabs.Form = {'   Form   ',@obj.getFormPlot};
            tabs.xPlot   = {'  X-Plot  ',@obj.getTabData};
            tabs.xtPlot   = {'  XT-Plot  ',@obj.getTabData};
            tabs.Stats = {'   Stats   ',@obj.setTabAction};
            subtabs = [];   %empty returned if no subtabs specified
        end
       
%%
        function props = setTabProperties(~)
            %define the tab and position to display class data tables
            %props format: {class name, tab tag name, position, ...
            %               column width, table title}
            % position and column widths vary with number of parameters
            % (rows) and width of input text and values. Inidcative
            % positions:  top left [0.95,0.48];    top right [0.95,0.97]
            %         bottom left [0.45, 0.48]; bottom rigth [0.45,0.97]                                                       
            props = {...                                    
                'CSTparameters','Inputs',[0.95,0.6],{220,120},'Input parameters:';...
                'CSTrunparams','Inputs',[0.95,0.97],{150,60},'Run parameters:'};
        end    
 %%
        function setTabAction(obj,src,cobj)
            %function required by muiModelUI and sets action for selected
            %tab (src)
            msg = 'No results to display';
            switch src.Tag
                case {'xPlot','xtPlot'}
                    valid = {'CSTrunmodel','CSTdataimport'};
                    if ~any(matches(valid,class(cobj))), return; end
                    tabPlot(cobj,src,obj);
                case 'Stats'
                    lobj = getClassObj(obj,'mUI','Stats',msg);
                    if isempty(lobj), return; end
                    tabStats(lobj,src);
            end
        end    
%%
        function getFormPlot(obj,src,~)
            %plot the estuary form properties
            cobj = getClassObj(obj,'Inputs','CSTformprops');
            dobj = getClassObj(obj,'Cases','CSTdataimport');
            if isempty(cobj) && isempty(dobj)
                cobj = CSTformprops();
            elseif ~isempty(dobj) && isempty(cobj)
                %select from data import
                cobj = userSelection(obj,dobj);
            elseif ~isempty(cobj) && ~isempty(dobj)
                answer = questdlg('Use estuary Form Properties or Imported Dataset?',...
                          'Form plot','Form Properties','Imported Data','Imported Data');
                if strcmp(answer,'Imported Data')
                    cobj = userSelection(obj,dobj);
                end
            end
            if isempty(cobj), return; end
            cst_formplot(cobj,src,obj);
        end
%% ------------------------------------------------------------------------
% Callback functions used by menus and tabs
%-------------------------------------------------------------------------- 
        %% File menu ------------------------------------------------------
        %use default menu functions defined in muiModelUI
            
        %% Tools menu -----------------------------------------------------
        %use default menu functions defined in muiModelUI
                
        %% Project menu ---------------------------------------------------
        %use default menu functions defined in muiModelUI           

        %% Setup menu -----------------------------------------------------
        function setupMenuOptions(obj,src,~)
            %callback functions for data input
            switch src.Text
                case 'Model Parameters'                       %
                    CSTparameters.setInput(obj);  
                    %update tab display with input data
                    tabsrc = findobj(obj.mUI.Tabs,'Tag','Inputs');
                    InputTabSummary(obj,tabsrc);
                case 'Estuary Properties'
                    CSTformprops.loadData(obj);
                case 'Run Parameters'
                    CSTrunparams.setInput(obj);
                    %update tab display with input data
                    tabsrc = findobj(obj.mUI.Tabs,'Tag','Inputs');
                    InputTabSummary(obj,tabsrc);
                case 'Import Data'
                    %relace callStaticFunction because need mobj as well as
                    %muicat in CSTdataimport
                    classname = 'CSTdataimport';
                    fncname = sprintf('%s.loadData',classname);
                    heq = str2func(['@(mcat,cname) ',[fncname,'(mcat,cname)']]); 
                    try
                       heq(obj,classname); 
                    catch ME
                        msg = sprintf('Unable to run function %s\nID: ',fncname);
                        disp([msg, ME.identifier])
                        rethrow(ME)                     
                    end     
                case 'User Data'
                    classname = 'muiUserData';
                    fname = sprintf('%s.loadData',classname);
                    callStaticFunction(obj,classname,fname); 
                case 'Model Constants'
                    obj.Constants = editProperties(obj.Constants);
            end
        end  

        %% Run menu -------------------------------------------------------
        function runMenuOptions(obj,src,~)
            %callback functions to run model
            switch src.Text                   
                case 'Run Model'                             
                    CSTrunmodel.runModel(obj); 
                case 'Derive Output'
                    obj.mUI.ManipUI = muiManipUI.getManipUI(obj);
            end            
        end               
            
        %% Analysis menu ------------------------------------------------------
        function analysisMenuOptions(obj,src,~)
            switch src.Text
                case 'Plots'
                    obj.mUI.PlotsUI = muiPlotsUI.getPlotsUI(obj);
                case 'Statistics'
                    obj.mUI.StatsUI = muiStatsUI.getStatsUI(obj);
            end            
        end

        %% Help menu ------------------------------------------------------
        function Help(~,src,~)
            %menu to access online documentation and manual pdf file
            switch src.Text
                case 'Documentation'
                    doc cstmodel
                case 'Manual'
                    cst_open_manual;
            end                              
        end

        %% Check that toolboxes are installed------------------------------
        function isok = check4muitoolbox(~)
            %check that dstoolbox and muitoolbox have been installed
            fname = 'dstable.m';
            dstbx = which(fname);
        
            fname = 'muiModelUI.m';
            muitbx = which(fname);
        
            if isempty(dstbx) && ~isempty(muitbx)
                warndlg('dstoolbox has not been installed')
                isok = false;
            elseif ~isempty(dstbx) && isempty(muitbx)
                warndlg('muitoolbox has not been installed')
                isok = false;
            elseif isempty(dstbx) && isempty(muitbx)
                warndlg('dstoolbox and muitoolbox have not been installed')
                isok = false;
            else
                isok = true;
            end
        end  
    end

%% user form data tabPlot selection----------------------------------------
    methods
        function cobj = userSelection(obj,dobj)
            %prompt user to select from the available data import cases
            if isscalar(dobj), cobj = dobj; return; end
            %select from data import
            promptxt = 'Select case to use:';
            [cobj,~] = selectCaseObj(obj.Cases,[],{'CSTdataimport'},promptxt);
        end
    end
end    
    
    
    
    
    
    
    
    
    
    