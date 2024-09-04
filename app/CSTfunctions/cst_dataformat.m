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
function dst = getData(obj,x,isflip) 
    %read and load a data set from a file
    [dataHT,dataUT,t,meta]  = readInputData();             
    if isempty(dataHT) && isempty(dataUT), dst = []; return; end
    

    if isflip %assumes that columns are ordered in the same sequence as the form data
        dataHT = fliplr(dataHT);
        dataUT = fliplr(dataUT);
    end

    %set metadata
    dsp = setDSproperties;
    
    if ~isempty(dataHT) && all(size(dataHT)==size(dataUT))
        datablank = zeros(size(dataHT)); %river and stokes velocities derived internally
        input = {dataHT,dataUT,datablank,datablank};
        dst1 = dstable(input{:},'RowNames',hours(t.h),'DSproperties',dsp);
        dst1.Dimensions.X = x;     %grid x-coordinate
        dst1.Source = meta;        %char not cell because multiple tables
        dst1.MetaData = metaclass(obj).Name; %Any additional information to be saved';    
        dst.TidalCycleHydro = dst1; 
    else
        warndlg('Dimensions of Elevation and Velocity data must be the same')
        dst = [];
    end
end
%%
function [dataHT,dataUT,t,meta] = readInputData()
    %default is to load the along channel data (MSL,z-amp,u-amp,depth)    
    dataHT = []; dataUT = []; t = []; meta = [];
    %prompt to add the XT data for elevation     
    [fname,path,nfiles] = getfiles('MultiSelect','off',...
                'FileType','*.txt;*.csv','PromptText','Select X-T Elevation file:');
    if nfiles>0        
        filename = [path fname];    %single select returns char
        %read Elevation data file
        data = readmatrix(filename,'NumHeaderLines',1);
        t.h = data(:,1);
        dataHT = data(:,2:end);
        meta = [filename,' & '];
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
        meta = sprintf('%s%s',meta,filename); 
    end
end
%%
%--------------------------------------------------------------------------
% dataDSproperties
%--------------------------------------------------------------------------
function dsp = setDSproperties(~) 
    %define a dsproperties struct and add the model metadata
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]); 
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique

    %tidal cycle values
    dsp.Variables = struct(...                       
        'Name',{'Elevation','TidalVel','RiverVel','StokesVel'},...
        'Description',{'Elevation','Tidal velocity',...
                       'River velocity','Stokes drift velocity'},...
        'Unit',{'m','m/s','m/s','m/s'},...
        'Label',{'Elevation (m)','Velocity (m/s)','Velocity (m/s)',...
                 'Velocity (m/s)'},...
        'QCflag',{'data','data','deived','derived'}); 
    dsp.Row = struct(...
        'Name',{'Time'},...
        'Description',{'Time'},...
        'Unit',{'h'},...
        'Label',{'Time (h)'},...
        'Format',{'h'});         
    dsp.Dimensions = struct(...    
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



