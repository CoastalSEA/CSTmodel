function output = cst_dataformat(funcall,varargin) 
%
%-------function help------------------------------------------------------
% NAME
%   cst_dataformat.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   CST model data format
% USAGE
%   obj = cst_dataformat(obj,funcall)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%   Channel Coastal Observatory (CCO) data
%   https://www.channelcoast.org/
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
    
    %set metadata
    [dsp1,dsp2] = setDSproperties;
    
    %each variable should be an array in the 'results' cell array
    %if model returns single variable as array of doubles, use {results}
    dataX = cellfun(@transpose,dataX,'UniformOutput',false);
    dst1 = dstable(dataX{:},'DSproperties',dsp1);
    dst1.Dimensions.X = x;     %grid x-coordinate

    dst2 = dstable(dataHT,dataUT,'RowNames',hours(t),'DSproperties',dsp2);
    dst2.Dimensions.X = x;     %grid x-coordinate    

    %assign metadata about model (details of source file are dealt with in
    %muiDataSet.loadData)
    dst1.MetaData = metaclass(obj).Name; %Any additional information to be saved';
    dst2.MetaData = metaclass(obj).Name; %Any additional information to be saved';    

    dst.AlongEstuaryValues = dst1;
    dst.TidalCycleValues = dst2;              
end
%%
function [dataX,dataHT,dataUT,x,t] = readInputData(filename)
    %default is to load the along channel data (MSL,z-amp,u-amp,depth)    
    dataSpec = '%f %f %f %f %f'; 
    [data,~] = readinputfile(filename,1,dataSpec); %see muifunctions
    if isempty(data), return; end
    x = data{1};
    dataX = data(2:end);
    
    %prompt to add the XT data for elevation and velocity
    dataHT = []; dataUT = []; t = [];
    [fname,path,nfiles] = getfiles('MultiSelect','on',...
                'FileType','*.txt;*.csv','PromptText','Select H & U file:');
    if nfiles==0        
        return;
    elseif iscell(fname)
        filename = [path fname{1}]; %multiselect returns cell array
    else
        filename = [path fname];    %single select returns char
    end
    %read first data file
    dataSpec = repmat('%f\t',1,length(x)); %+1 accounts for t column
    dataSpec = [dataSpec,'%f'];
    data{1} = readmatrix(filename,'NumHeaderLines',1);
    [~,header{1}] = readinputfile(filename,1,dataSpec); %see muifunctions
    if isempty(data),return; end
    %read second data file
    
    if iscell(fname) && length(fname)>1
        filename = [path fname{2}];
        data{2} = readmatrix(filename,'NumHeaderLines',1);
        [~,header{2}] = readinputfile(filename,1,dataSpec); %see muifunctions
    end
    %assign to elevation and velocity variables using header text
    for i=1:length(header)
        headtxt = strip(header{i}{1});
        if contains('Elevation',headtxt)
            dataHT = data{i};
        elseif contains('Velocity',headtxt)
            dataUT = data{i};
        end
    end
    t = dataHT(:,1);
    dataHT = dataHT(:,2:end);
    if ~isempty(dataUT)
        dataUT = dataUT(:,2:end);
    end
    
%     nt = size(dataHT,1);
%     tstep = 12.4*60/nt;
%     answer = inputdlg({'Number of time steps','Time step (mins)'},'CSTimport',...
%                        1,{num2str(nt),num2str(tstep)});
%     if ~isempty(answer)
%         nt = str2double(answer{1});
%         tstep = str2double(answer{2});
%     end
%     t = 0:tstep:nt*tstep;   
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
        'Name',{'MeanTideLevel','TidalElevAmp','TidalVelAmp','HydDepth'},...
        'Description',{'Mean water level',...
                    'Tidal elevation amplitude',...
                    'Tidal velocity amplitude',...
                    'Hydraulic depth'},...
        'Unit',{'m','m','m/s','m'},...
        'Label',{'Mean water level (m)',...
                 'Elevation amplitude (m)',...
                 'Velocity (m/s)','Depth (m)'},...
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
        'QCflag',repmat({'model'},1,2)); 
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
    warndlg('No qualtiy control defined for this format');
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



