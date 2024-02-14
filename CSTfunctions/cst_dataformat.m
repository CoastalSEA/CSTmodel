function output = cst_dataformat(funcall,varargin) 
%
%-------function help------------------------------------------------------
% NAME
%   cst_dataformat.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   CST model data format
% USAGE
%   obj = cst_dataformat(funcall,varargin)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%   Format of input designed to be consistent with CSTmodel genearted
%   output
%
% Author: Ian Townend
% CoastalSEA (c)Feb 2021
%--------------------------------------------------------------------------
%
    switch funcall
        %standard calls from muiDataSet - do not change if data class 
        %inherits from muiDataSet. The function getPlot is called from the
        %Abstract method tabPlot. The class definition can use tabDefaultPlot
        %define plot function in the class file, or call getPlot
        case 'getData'
          output = getData(varargin{:});
        case 'dataQC'
            output = dataQC(varargin{1});  
        case 'getPlot'
            %output = 0; if using the default tab plot in muiDataSet, else
            output = getPlot(varargin{:});
    end
end
%%
%--------------------------------------------------------------------------
% getData
%--------------------------------------------------------------------------
function dst = getData(obj,filename) 
    %read and load a data set from a file
    [dataX,dataHT,dataUT,x,t]  = readInputData(filename);             
    if isempty(dataX), dst = []; return; end

    dataX = cellfun(@transpose,dataX,'UniformOutput',false);
    if x(1)>x(end)
        x = fliplr(x);
        dataX = cellfun(@fliplr,dataX,'UniformOutput',false);
        dataHT = fliplr(dataHT);
        dataUT = fliplr(dataUT);
    end

    %set metadata
    [dsp1,dsp2] = setDSproperties;
    
    %each variable should be an array in the 'results' cell array
    %if model returns single variable as array of doubles, use {results}
    dataX = cellfun(@transpose,dataX,'UniformOutput',false);
    dst1 = dstable(dataX{:},'DSproperties',dsp1);
    dst1.Dimensions.X = x;     %grid x-coordinate
    dst1.MetaData = metaclass(obj).Name; %Any additional information to be saved';
    dst.AlongEstuary = dst1;
    
    if ~isempty(dataHT) && ~isempty(dataUT)
        input = {dataHT,dataUT};
        dst2 = dstable(input{:},'RowNames',hours(t.h),'DSproperties',dsp2);
        dst2.Dimensions.X = x;     %grid x-coordinate   
        dst2.MetaData = metaclass(obj).Name; %Any additional information to be saved';    
        dst.TidalCycle = dst2; 
    end
end
%%
function [dataX,dataHT,dataUT,x,t] = readInputData(filename)
    %default is to load the along channel data (MSL,z-amp,u-amp,depth)    
    dataSpec = '%f %f %f %f %f'; 
    [data,~] = readinputfile(filename,1,dataSpec); %in dsfunctions
    if isempty(data), return; end
    x = data{1}';
    dataX = data(2:end);
    
    dataHT = []; dataUT = []; t = [];
    %prompt to add the XT data for elevation     
    [fname,path,nfiles] = getfiles('MultiSelect','off',...
                'FileType','*.txt;*.csv','PromptText','Select X-T Elevation file:');
    if nfiles>0        
        filename = [path fname];    %single select returns char
        %read Elevation data file
        data = readmatrix(filename,'NumHeaderLines',1);
        t.h = data(:,1);
        dataHT = data(:,2:end);
    end

    %prompt to add the XT data for velocity
    [fname,path,nfiles] = getfiles('MultiSelect','off',...
                'FileType','*.txt;*.csv','PromptText','Select X-T Velocity file:');
    if nfiles>0        
        filename = [path fname];    %single select returns char
        %read Velocity data file
        data = readmatrix(filename,'NumHeaderLines',1);
        t.u = data(:,1);
        dataUT = data(:,2:end);
    end
end
%%
%--------------------------------------------------------------------------
% dataDSproperties
%--------------------------------------------------------------------------
function [dsp1,dsp2] = setDSproperties(~) 
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
                                            'RiverVel'},...
        'Description',{'Mean water level',...
                    'Tidal elevation amplitude',...
                    'Tidal velocity amplitude',...
                    'River flow velocity'},...
        'Unit',{'m','m','m/s','m/s'},...
        'Label',{'Mean water level (m)',...
                 'Elevation (m)',...
                 'Velocity (m/s)',...
                 'Velocity (m/s)'},...
        'QCflag',repmat({'model'},1,4)); 
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
        'Name',{'Elevation','Velocity'},...
        'Description',{'Elevation','Tidal velocity'},...
        'Unit',{'m','m/s'},...
        'Label',{'Elevation (m)','Velocity (m/s)'},...
        'QCflag',{'data','data'}); 
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
%%
%--------------------------------------------------------------------------
% dataQC
%--------------------------------------------------------------------------
function output = dataQC(obj)                        % <<Add any quality control to be applied (optional)
    %quality control a dataset
    % datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
    % dst = obj.Data.(datasetname);      %selected dstable
    warndlg('No quality control defined for this format');
    output = [];    %if no QC implemented in dataQC
end
%%
%--------------------------------------------------------------------------
% getPlot
%--------------------------------------------------------------------------
function ok = getPlot(obj,src)                       % <<Add code for bespoke Q-Plot is required (optional)
    %generate a plot on the src graphical object handle    
    ok = 0;  %ok=0 if no plot implemented in getPlot
    %return some other value if a plot is implemented here
end



