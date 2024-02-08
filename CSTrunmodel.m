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
            [dsp1,dsp2,dsp3] = modelDSproperties(obj);
            
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
            if ~isempty(estobj)
                activatedynamicprops(estobj.FormData); %ensures variables are active
            end
            %
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
            if length(resX)==5
                dst1 = dstable(resX{:},'DSproperties',dsp1);            
            else
                dst1 = dstable(resX{:},'DSproperties',dsp3);
            end
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
            
            dst.AlongEstuary = dst1;
            dst.TidalCycle = dst2;            
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
        function [dsp1,dsp2,dsp3] = modelDSproperties(~) 
            %define a dsproperties struct and add the model metadata
            dsp1 = struct('Variables',[],'Row',[],'Dimensions',[]); 
            dsp2 = dsp1; 
            %define each variable to be included in the data table and any
            %information about the dimensions. dstable Row and Dimensions can
            %accept most data types but the values in each vector must be unique
            
            %struct entries are cell arrays and can be column or row vectors
            %static ouput (mean tide values as a function of X)
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
            
            %dynamic values (function of X anf T)
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

            dsp3 = dsp1;   %additional variables option
            dsp3.Variables = struct(...                       
                'Name',{'MeanTideLevel','TidalElevAmp','TidalVelAmp',...
                        'RiverVel','HydDepth',...
                        'PhaseAngle','CSA','Width','InterSlope',...%additions
                        'effHydDep','StokesDrift'},...
                'Description',{'Mean water level',...
                            'Tidal elevation amplitude',...
                            'Tidal velocity amplitude',...
                            'River flow velocity',...
                            'Hydraulic depth',...
                            'Phase angle',...
                            'Cross-sectional area',...
                            'Width',...
                            'Intertidal slope',...
                            'Effective hydraulic depth',...
                            'Stokes drift over a tide'},...
                'Unit',{'m','m','m/s','m/s','m',...
                         '-','m^2','m','1:m','m^2','m/2'},...
                'Label',{'Mean water level (m)',...
                         'Elevation amplitude (m)',...
                         'Velocity amplitude (m/s)',...
                         'Velocity (m/s)','Depth (m)',...
                         'Phase angle','Cross-sectional area (m^2)',...
                         'Width (m)','Intertidal slope (1:m)',...
                         'Cross-sectional area (m^2)','Velocity (m/s)'},...
                'QCflag',repmat({'model'},1,11)); 
        end
    end    
end