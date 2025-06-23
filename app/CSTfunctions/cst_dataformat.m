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
function dst = getData(obj,x,isflip,excelfile) 
    %read and load a data set from a file
    dst = [];
    if nargin<4
        [data,xhu,thu,meta]  = readTextData();           
    else
        [data,xhu,thu,meta]  = readExcelData(excelfile);                  
    end
    if isempty(data), return; end
    %check lengths of distance dimension for elevation and velocity
     if isfield(xhu,'h') && length(xhu.h)~=length(x)
         warndlg('No of elevation sections is not consistent with the number of sections in the form file')
         return
     end
     
     if isfield(xhu,'u') && length(xhu.u)~=length(x)
            warndlg('No of velocity sections is not consistent with the number of sections in the form file')
            return
     end
    
    %check lengths of time dimension for elevation and velocity
    if isfield(thu,'h') && isfield(thu,'u') 
        if length(thu.h)~=length(thu.u)
            warndlg('No of elevation and velocity time intervals do not match')
            return
        else
            t = thu.h;
        end
    elseif isfield(thu,'h')    
        t = thu.h;
    else
        t = thu.u;
    end

    if isflip %assumes that columns are ordered in the same sequence as the form data
        data.HT = fliplr(data.HT);
        data.UT = fliplr(data.UT);
    end

    %set metadata
    dsp = setDSproperties;
    
    if ~isempty(data.HT) && all(size(data.HT)==size(data.UT))
        datablank = zeros(size(data.HT)); %river and stokes velocities derived internally
        input = {data.HT,data.UT,datablank,datablank};
        dst1 = dstable(input{:},'RowNames',hours(t),'DSproperties',dsp);
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
function [data,x,t,meta] = readTextData()
    %default is to load the along channel data     
    data = []; x = []; t = []; meta = [];
    %prompt to add the XT data for elevation     
    [fname,path,nfiles] = getfiles('MultiSelect','off',...
                'FileType','*.txt;*.csv','PromptText','Select X-T Elevation file:');
    if nfiles>0        
        filename = [path fname];    %single select returns char
        %read Elevation data file
        fid = fopen(filename, 'r');
        if fid<0
            errordlg('Could not open Elevation file for reading','File read error','modal')
            return;
        end
        for i=1:2
            header{i} = fgets(fid);  %#ok<AGROW>
        end
        indata = readmatrix(filename,'NumHeaderLines',2);
        %t.h = data(:,1);
        t.h = str2double(strsplit(strtrim(header{2})));
        x.h = indata(:,1);
        data.HT = indata(:,2:end)';
        meta = [filename,' & '];
    end

    %prompt to add the XT data for velocity
    [fname,path,nfiles] = getfiles('MultiSelect','off',...
                'FileType','*.txt;*.csv','PromptText','Select X-T Velocity file:');
    if nfiles>0        
        filename = [path fname];    %single select returns char
        %read Velocity data file
        fid = fopen(filename, 'r');
        if fid<0
            errordlg('Could not open Velocity file for reading','File read error','modal')
            return;
        end
        for i=1:2
            header{i} = fgets(fid);  
        end        
        indata = readmatrix(filename,'NumHeaderLines',2);
        t.u = str2double(strsplit(strtrim(header{2})));
        x.u = indata(:,1);
        data.UT = indata(:,2:end)';
        meta = sprintf('%s%s',meta,filename); 
    end
end
%%
function [data,x,t,meta] = readExcelData(filename)
    %default is to load the along channel data (MSL,z-amp,u-amp,depth)    
    data = []; x = []; t = []; meta = [];
    %read Elevation data file
    cell_ids = {'B2';'B3';'A3'};
    ptxt = 'Select Water Level Worksheet:';
    indata = readspreadsheet(filename,false,cell_ids,ptxt); %return a table
    if ~isempty(indata)
        vars = cellfun(@(x) x(2:end),indata.Properties.VariableNames,'UniformOutput',false);
        vars = replace(vars,'_','.');
        t.h = str2double(vars);
        x.h = str2double(indata.Properties.RowNames);
        data.HT = indata{:,:}';
        meta = [filename,' & '];
    end

    %read Velocity data file
    cell_ids = {'B2';'B3';'A3'};
    ptxt = 'Select Velocity Worksheet:';
    indata = readspreadsheet(filename,false,cell_ids,ptxt); %return a table
    if ~isempty(indata)
        vars = cellfun(@(x) x(2:end),indata.Properties.VariableNames,'UniformOutput',false);
        vars = replace(vars,'_','.');
        t.u = str2double(vars);
        x.u = str2double(indata.Properties.RowNames);
        data.UT = indata{:,:}';
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



