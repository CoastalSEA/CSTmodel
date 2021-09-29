classdef CSTmodelUI < muiModelUI                     
%
%-------class help---------------------------------------------------------
% NAME
%   CSTmodelUI.m
% PURPOSE
%   Main GUI for a generic model interface, which implements the 
%   muiModelUI abstract class to define main menus.
% SEE ALSO
%   Abstract class muiModelUI.m and tools provided in muitoolbox
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
% 
    properties  (Access = protected)
        %implement properties defined as Abstract in muiModelUI
        vNumber = '2.0'
        vDate   = 'Oct 2021'
        modelName = 'CSTmodel'                     
        %Properties defined in muiModelUI that need to be defined in setGui
        % ModelInputs  %classes required by model: used in isValidModel check 
        % DataUItabs   %struct to define type of muiDataUI tabs for each use                         
    end
    
    methods (Static)
        function obj = CSTmodelUI                       
            %constructor function initialises GUI
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
            %obj.ModelInputs.<model classname> = {'Param_class1',Param_class2',etc}
            %                                        % << Edit to model and input parameters classnames 
            obj.ModelInputs.CSTmodel = {'CSTparameters','CSTrunparams'};
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
                                                              % << Edit menu to suit model 
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
            menu.Project(2).List = {'Edit Description','Edit Data Set',...
                                    'Save Data Set','Delete Case','Reload Case',...
                                    'View Case Settings'};                                               
            menu.Project(2).Callback = repmat({@obj.projectMenuOptions},[1,6]);
            
            % submenu for 'Export/Import'                                          
            menu.Project(3).List = {'Export Case','Import Case'};
            menu.Project(3).Callback = repmat({@obj.projectMenuOptions},[1,2]);
            
            %% Setup menu -------------------------------------------------
            menu.Setup(1).List = {'Model Parameters','Run Parameters',...
                     'Estuary Properties','Import Data','Model Constants'};                                    
            menu.Setup(1).Callback = [repmat({@obj.setupMenuOptions},[1,3]),...
                                          {'gcbo;'},{@obj.setupMenuOptions}];
            %add separators to menu list (optional - default is off)
            menu.Setup(1).Separator = {'off','off','off','on','on'}; %separator preceeds item
            
            % submenu for Import Data (if these are changed need to edit
            % loadMenuOptions to be match)
            menu.Setup(2).List = {'Load','Add','Delete','Quality Control'};
            menu.Setup(2).Callback = repmat({@obj.loadMenuOptions},[1,4]);
            
            %% Run menu ---------------------------------------------------
            menu.Run(1).List = {'Run Model','Derive Output'};
            menu.Run(1).Callback = repmat({@obj.runMenuOptions},[1,2]);
            
            %% Plot menu --------------------------------------------------  
            menu.Analysis(1).List = {'Plots','Statistics'};
            menu.Analysis(1).Callback = repmat({@obj.analysisMenuOptions},[1,2]);
            
            %% Help menu --------------------------------------------------
            menu.Help(1).Callback = {@obj.Help}; %make model specific?
            
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
            tabs.Cases  = {'   Cases  ',@obj.refresh};        % << Edit tabs to suit model 
            tabs.Inputs = {'  Inputs  ',@obj.InputTabSummary};
            tabs.Form = {'   Form   ',@obj.getFormPlot};
            tabs.xPlot   = {'  X-Plot  ',@obj.getTabData};
            tabs.xtPlot   = {'  XT-Plot  ',@obj.getTabData};
            tabs.Stats = {'   Stats   ',@obj.getTabData};
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
                                                             % << Edit input properties classnames 
            props = {...                                     % << Add additional inputs and adjust layout
                'CSTparameters','Inputs',[0.95,0.48],{180,60},'Input parameters:';...
                'CSTrunparams','Inputs',[0.95,0.95],{180,60},'Run parameters:'};
        end    
 %%
        function setTabAction(~,src,cobj)
            %function required by muiModelUI and sets action for selected
            %tab (src)
            switch src.Tag                                   
                case 'xPlot' 
                     tabPlot(cobj,src);
                case 'xtPlot'
                     xt_tabPlot(cobj,src);
                case 'Stats'
                     tabStats(cobj,src);   
            end
        end    
%%
        function getFormPlot(obj,src,~)
            %plot the estuary form properties
            cobj = getClassObj(obj,'Inputs','CSTformprops');
            if isempty(cobj)
                cobj = CSTformprops();
            end
            if isempty(cobj), return; end
            tabPlot(cobj,src,obj);
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
                case 'Model Constants'
                    obj.Constants = editProperties(obj.Constants);
            end
        end  
%%
        function loadMenuOptions(obj,src,~)
            %callback functions to import data
            classname = 'muiUserData';
            switch src.Text
                case 'Load'
                    fname = sprintf('%s.loadData',classname);
                    callStaticFunction(obj,classname,fname); 
                case 'Add'
                    useCase(obj.Cases,'single',classname,'addData');
                case 'Delete'
                    useCase(obj.Cases,'single',classname,'deleteData');
                case 'Quality Control'
                    useCase(obj.Cases,'single',classname,'qcData');
            end
            DrawMap(obj);
        end   

        %% Run menu -------------------------------------------------------
        function runMenuOptions(obj,src,~)
            %callback functions to run model
            switch src.Text                   
                case 'Run Model'                             
                    CSTmodel.runModel(obj); 
                case 'Derive Output'
                    obj.mUI.Manip = muiManipUI.getManipUI(obj);
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
        function Help(~,~,~)
            docsearch CSTmodel                              
        end
    end
end    
    
    
    
    
    
    
    
    
    
    