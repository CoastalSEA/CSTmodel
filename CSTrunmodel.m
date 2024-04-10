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
            if rnpobj.useObs
                estobj = getObservedForm(obj,mobj);
            else
                estobj = [];
            end
            %
            try
                [res,xy,mtime] = cst_model(inpobj,rnpobj,estobj);
            catch ME
                %remove the waitbar if program did not complete
                hw = findall(0,'type','figure','tag','TMWWaitbar');
                delete(hw);
                warndlg('No solution found in cst_model');
                delete(obj);
                throw(ME)
            end
            %
            if isempty(res)
                warndlg('No solution found in cst_model'); return; %probable error in data input
            end  
            %now assign results to object properties  
            modeltime = seconds(mtime{1});  %durataion data for rows 
            modeltime.Format = 'h';
%--------------------------------------------------------------------------
% Assign model output to a dstable using the defined dsproperties meta-data
%--------------------------------------------------------------------------                   
            %each variable should be an array in the 'results' cell array
            %if model returns single variable as array of doubles, use {results}
            dsp = modelDSproperties(obj,rnpobj);
            dst1 = dstable(res.X{:},'DSproperties',dsp.xHyd); 
            dst1.Dimensions.X = xy{:,1};     %grid x-coordinate
            dst2 = dstable(res.F{:},'DSproperties',dsp.xForm);      
            dst2.Dimensions.X = xy{:,1};     %grid x-coordinate           
            dst3 = dstable(res.XT{:},'RowNames',modeltime,'DSproperties',dsp.xtHyd);
            dst3.Dimensions.X = xy{:,1};     %grid x-coordinate
%--------------------------------------------------------------------------
% Save results
%--------------------------------------------------------------------------                        
            %assign metadata about model
            dst1.Source = metaclass(obj).Name;
%             dst1.MetaData = 'Any additional information to be saved';
            dst2.Source = metaclass(obj).Name;
%             dst2.MetaData = 'Any additional information to be saved';
            dst3.Source = metaclass(obj).Name;
%             dst3.MetaData = 'Any additional information to be saved';            
            dst.AlongChannelHydro = dst1;
            dst.AlongChannelForm = dst2;
            dst.TidalCycleHydro = dst3;            
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
        function tabPlot(obj,src,mobj) %abstract class for muiDataSet
            %generate plot for display on Q-Plot tab             
            switch src.Tag
                case {'xPlot','FigButton'}
                    tabcb =  @(src,evdat)tabPlot(obj,src,mobj);
                    ax = tabfigureplot(obj,src,tabcb,false); %rotate button not required
                    cst_x_plot(obj,ax);
                case 'xtPlot'
                    cst_xt_plot(obj,src);
            end            
        end
    end 
    
%%    
    methods (Access = private)
        function estobj =  getObservedForm(obj,mobj)
            %
            estobj = getClassObj(mobj,'Inputs','CSTformprops');  %can be empty
            if ~isempty(estobj)
                activatedynamicprops(estobj.Data.AlongChannelForm); %ensures variables are active
            end
            impobj = getClassObj(mobj,'Cases','CSTdataimport');  %can be empty

            if isempty(estobj) && isempty(impobj)
                warndlg('No data loaded');
            elseif ~isempty(impobj) && isempty(estobj)
                estobj = userSelection(obj,mobj,impobj);
            elseif ~isempty(estobj) && ~isempty(impobj)
                answer =  questdlg('Use estuary Form Properties or Imported Dataset?',...
                          'Form plot','Form Properties','Imported Data','Imported Data');
                if strcmp(answer,'Imported Data')
                    estobj = userSelection(mobj,impobj);
                end
            end
        end
        
%%
function dsp= modelDSproperties(~,rnp) 
            %define a dsproperties struct and add the model metadata
            dsp.xHyd = struct('Variables',[],'Row',[],'Dimensions',[]); 
            dsp.xtHyd = dsp.xHyd;
            %define each variable to be included in the data table and any
            %information about the dimensions. dstable Row and Dimensions can
            %accept most data types but the values in each vector must be unique
            
            %struct entries are cell arrays and can be column or row vectors
            %static ouput (mean tide values as a function of X)
            dsp.xHyd.Variables = struct(...                       
                'Name',{'MeanTideLevel','TidalElevAmp','LWHWratio',...
                            'TidalVelAmp','RiverVel'},...
                'Description',{'Mean water level',...
                            'Tidal elevation amplitude',...
                            'LW/HW ratio',...
                            'Tidal velocity amplitude',...
                            'River flow velocity'},...
                'Unit',{'mAD','m','-','m/s','m/s'},...
                'Label',{'Mean water level (mAD)',...
                         'Elevation amplitude (m)',...
                         'LW/HW ratio (-)',...
                         'Velocity amplitude (m/s)',...
                         'Velocity (m/s)'},...
                'QCflag',repmat({'model'},1,5)); 
            dsp.xHyd.Row = struct(...
                'Name',{''},...
                'Description',{''},...
                'Unit',{''},...
                'Label',{''},...
                'Format',{''});        
            dsp.xHyd.Dimensions = struct(...    
                'Name',{'X'},...
                'Description',{'Chainage'},...
                'Unit',{'m'},...
                'Label',{'Distance from mouth (m)'},...
                'Format',{'-'});  
            
            %dynamic values (function of X anf T)
            dsp.xtHyd.Variables = struct(...                       
                'Name',{'Elevation','TidalVel','RiverVel','StokesVel'},...
                'Description',{'Elevation','Tidal velocity',...
                               'River velocity','Stokes drift velocity'},...
                'Unit',{'m','m/s','m/s','m/s'},...
                'Label',{'Elevation (m)','Velocity (m/s)','Velocity (m/s)',...
                         'Velocity (m/s)'},...
                'QCflag',repmat({'model'},1,4)); 
            dsp.xtHyd.Row = struct(...
                'Name',{'Time'},...
                'Description',{'Time'},...
                'Unit',{'h'},...
                'Label',{'Time (h)'},...
                'Format',{'h'});         
            dsp.xtHyd.Dimensions = struct(...    
                'Name',{'X'},...
                'Description',{'Chainage'},...
                'Unit',{'m'},...
                'Label',{'Distance from mouth (m)'},...
                'Format',{'-'});  

            dsp.xForm = dsp.xHyd;
            dsp.xForm.Variables = struct(...
                'Name',{'Amtl','Hmtl','Whw','Wlw','N'},...                  
                'Description',{'Area at mean tide level',...
                               'Hydraulic depth at mean tide level',...
                               'Width at high water',...
                               'Width at low water',...                              
                               'Mannings N'},...
                'Unit',{'m^2','m','m','m','-'},...
                'Label',{'Area (m^2)','Depth (m)','Width (m)','Width (m)',...
                                                        'Mannings N'},...
                'QCflag',repmat({'data'},1,5)); 

            if rnp.isfull
                dsp.xHyd.Variables = struct(...                       
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
                    'Unit',{'mAD','m','-','m/s','m/s','m/s','-','1:m','m^2'},...                         
                    'Label',{'Mean water level (m)',...
                             'Elevation amplitude (m)',...
                             'LW/HW ratio (-)',...
                             'Velocity amplitude (m/s)',...
                             'Velocity (m/s)','Velocity (m/s)',...
                             'Phase angle','Intertidal slope (1:m)',...
                             'Cross-sectional area (m^2)'},...                         
                    'QCflag',repmat({'model'},1,9)); 
            end

            

        end
    end    
end