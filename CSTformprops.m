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
        FormData        
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
                isext = false; %true - use class to initialise table but don't save instance
            end
            obj = CSTformprops;                      
            [data,~,filename] = readInputData(obj);             
            if isempty(data), return; end

            %code to parse input data and assign to vardata
            x = data{1}';
            dataX = data(2:end);
            dataX = cellfun(@transpose,dataX,'UniformOutput',false);
            if x(1)>x(end)
                x = fliplr(x);
                dataX = cellfun(@fliplr,dataX,'UniformOutput',false);
            end

            %initialise dsproperties for data
            dsp = setDSproperties(obj); 

            %load the results into a dstable  
            dst = dstable(dataX{:},'DSproperties',dsp); 
            dst.Dimensions.X = x;
            %assign metadata about data
            dst.Source{1} = filename;
            if isext
                delete(obj);
            else
                obj.FormData = dst;
                %setDataRecord classobj, muiCatalogue obj, dataset, classtype
                setClassObj(mobj,'Inputs','CSTformprops',obj); 
            end
        end 
    end   
%%
    methods
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
                'Name',{'Amtl','Whw','Wlw','Hmtl','N'},...                  
                'Description',{'Area at mean tide level',...
                               'Width at high water',...
                               'Width at low water',...
                               'Hydraulic depth at mean tide level',...
                               'Mannings N'},... %optional
                'Unit',{'m/^2','m','m','m','-'},...
                'Label',{'Area (m^2)','Width (m)','Width (m)','Depth (m)',...
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