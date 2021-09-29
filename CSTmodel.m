classdef CSTmodel < muiDataSet                        
%
%-------class help---------------------------------------------------------
% NAME
%   CSTmodel.m
% PURPOSE
%   Calculate the mean tide level and tidal amplitude along an estuary
%   only works for a single channel (not a network)
% SEE ALSO
%   muiDataSet
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
%     
    properties
        %inherits Data, RunParam, MetaData and CaseIndex from muiDataSet
        %Additional properties:     
    end
    
    methods (Access = private)
        function obj = CSTmodel()                      
            %class constructor
        end
    end      
%%
    methods (Static)        
%--------------------------------------------------------------------------
% Model implementation
%--------------------------------------------------------------------------         
        function obj = runModel(mobj,varargin)
            %function to run a simple 2D diffusion model
            obj = CSTmodel;                           
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
% Model code  <<INSERT MODEL CODE or CALL MODEL>>
%--------------------------------------------------------------------------
            if isa(mobj,'CSTmodelUI')
                %model called from CSTmodel UI interface
                inpobj = getClassObj(mobj,'Inputs','CSTparameters');
                rnpobj = getClassObj(mobj,'Inputs','CSTrunparams');
                estobj = getClassObj(mobj,'Inputs','CSTformprops');  
            else
                %model called from external program (eg asmita)
                
            end
            [resX,resXT,mtime,xy] = cst_model(inpobj,rnpobj,estobj);
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
    end
%%
    methods
        function tabPlot(obj,src) %abstract class for muiDataSet
            %generate plot for display on Q-Plot tab
            dst = obj.Data.AlongEstuaryValues;
            x = dst.Dimensions.X; 
            z = dst.MeanTideLevel;  %mean tide level
            a = dst.TidalElevAmp;  %tidal amplitude
			U = dst.TidalVelAmp;  %tidal velocity amplitude
			v = dst.RiverVel;  %river velocity 
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
			plot(x,U,'--c')             %plot tidal velocity
			plot(x,v,'--g')             %plot river velocity
            hold off
            xlabel('Distance from mouth (m)'); 
            ylabel('Velocity (m/s)'); 
			legend('MTL','HWL','LWL','Hydraulic depth',...
                'Tidal velocity','River velocity','Location','best');			
            title ('Along channel variation');
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plot
        end
%%
        function xt_tabPlot(obj,src) 
            %generate plot for display on Q-Plot tab
            dst = obj.Data.TidalCycleValues;
            x = dst.Dimensions.X; 
            t = dst.RowNames;
            ht = findobj(src,'Type','axes');
            delete(ht);
            ax = axes('Parent',src,'Tag','Profile');
            
            %create animation and add slider to allow user to scroll
            
        end
    end 
%%    
    methods (Access = private)
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