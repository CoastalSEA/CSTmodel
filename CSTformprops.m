classdef CSTformprops < handle                              
%
%-------class help---------------------------------------------------------
% NAME
%   CSTformprops.m
% PURPOSE
%   Class to import and hold the width and area data used in the CSTmodel
% USAGE
%   obj = CSTformprops()
% NOTE
%   file format is a header and five columns of data
%   x, Amtl, Whw, Wlw, Manning_N(optional)
%   distance from mouth, Area at mean tide level, Width at high water, 
%   Width at low water, Mannings N
% SEE ALSO
%   uses dstable and dscatalogue
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2021
%--------------------------------------------------------------------------
%    
    properties  
        Data    %struct to hold AlongChannelForm dstable        
    end

    properties (Dependent)
        Wmtl    %width at mean tide level (Amtl/Hmtl)
        Wratio  %intertidal storage ratio (Whw/Wlw)
        Wint    %intertidal width (Whw-Wlw)
    end

    methods 
        function obj = CSTformprops()                
            %class constructor
        end
    end
%%    
    methods (Static)
        function dst = loadData(mobj,isext)
            %read and load a data set from a file
            if nargin<2
                isext = false; %if true - use class to initialise table but don't save instance
            end
            obj = CSTformprops;                      
            [data,~,filename] = readInputData(obj);             
            if isempty(data), dst = []; return; end

            %code to parse input data and assign to vardata
            isflip = false;
            x = data{1}';
            dataX = data(2:end);
            dataX = cellfun(@transpose,dataX,'UniformOutput',false);
            if x(1)>x(end)
                x = fliplr(x);
                dataX = cellfun(@fliplr,dataX,'UniformOutput',false);
                isflip = true;
            end

            %initialise dsproperties for data
            dsp = setDSproperties(obj); 

            %load the results into a dstable  
            dst = dstable(dataX{:},'DSproperties',dsp); 
            dst.Dimensions.X = x;
            if isempty(dst.DataTable.Properties.CustomProperties.Dimensions.X)
                dst = []; return;
            end

            %assign metadata about data
            dst.MetaData = isflip; %flag to indicate if data was reversed from source
            dst.Source = filename;  %char not cell because multiple tables
            if isext                %true if called  by data import class
                delete(obj);
            else
                obj.Data.AlongChannelForm = dst; %mirrors struct used by CSTdataimport
                %assign CSTformprops instance to the model Inputs struct
                setClassObj(mobj,'Inputs','CSTformprops',obj); 
            end
        end 
    end   
%%
    methods
        function Wmtl = get.Wmtl(obj)
            %width at mean tide level as Area/Hydraulic depth if hydraulic
            %depth is not all nans
            dst = obj.Data.AlongChannelForm;
            if sum(dst.Hmtl,'omitnan')>0        %Hmtl values have been loaded  
                Wmtl = dst.Amtl./dst.Hmtl;
            else
                Wmtl = dst.Wlw+(dst.Whw-dst.Wlw)/2.57;      %assume F&A ideal profile
            end
        end

%%
        function Wratio = get.Wratio(obj)
            %intertidal storage ratio
            dst = obj.Data.AlongChannelForm;
            Wratio = dst.Whw./dst.Wlw;
        end
        
%%
        function Wint = get.Wint(obj)
            %intertidal storage ratio
            dst = obj.Data.AlongChannelForm;
            Wint = dst.Whw-dst.Wlw;
        end

%%
        function tabPlot(obj,src,mobj)
            %redirect of cst_formplot which CSTdataimport also uses
            cst_formplot(obj,src,mobj);         
        end    
    end
%%
    methods (Access = private)
        function [data,header,filename] = readInputData(~) 
            %read wind data (read format is file specific).
            [fname,path,~] = getfiles('FileType','*.txt;*.csv',...
                                'PromptText','Select X-form data file:');
            if fname==0, data = []; header = []; filename = []; return; end
            filename = [path fname];
            dataSpec = '%f %f %f %f %f %f'; 
            nhead = 1;     %number of header lines
            [data,header] = readinputfile(filename,nhead,dataSpec);
        end       
%%        
        function dsp = setDSproperties(~)
            %define the metadata properties for the demo data set
            dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
            %define each variable to be included in the data table and any
            %information about the dimensions. dstable Row and Dimensions can
            %accept most data types but the values in each vector must be unique
            
            %struct entries are cell arrays and can be column or row vectors
            dsp.Variables = struct(...
                'Name',{'Amtl','Hmtl','Whw','Wlw','N'},...                  
                'Description',{'Area at mean tide level',...
                               'Hydraulic depth at mean tide level',...
                               'Width at high water',...
                               'Width at low water',...                              
                               'Mannings N'},... %optional
                'Unit',{'m^2','m','m','m','-'},...
                'Label',{'Area (m^2)','Depth (m)','Width (m)','Width (m)',...
                                                        'Mannings N'},...
                'QCflag',repmat({'data'},1,5));  
            dsp.Row = struct(...
                'Name',{''},...
                'Description',{''},...
                'Unit',{''},...
                'Label',{''},...
                'Format',{''});        
            dsp.Dimensions = struct(...    
                'Name',{'X'},...
                'Description',{'Chainage'},...
                'Unit',{'m'},...
                'Label',{'Distance from mouth (m)'},...
                'Format',{''});  
        end
    end
end