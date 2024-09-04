classdef CSTdataimport < muiDataSet  
%
%-------class help---------------------------------------------------------
% NAME
%   CSTdataimport.m
% PURPOSE
%   Class to import a data set, adding the results to dstable
%   and a record in a dscatlogue (as a property of muiCatalogue)
% USAGE
%   obj = CSTdataimport()
% SEE ALSO
%   inherits muiDataSet and uses dstable and dscatalogue
%   format files used to load data of varying formats (variables and file format)
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
%    
    properties  
        %inherits Data, RunParam, MetaData and CaseIndex from muiDataSet
        % importing data requires muiDataSet propertiesm DataFormats and
        % FileSpec to be defined in class constructor.
    end

    properties (Dependent)
        Wmtl    %width at mean tide level (Amtl/Hmtl)
        Wratio  %intertidal storage ratio (Whw/Wlw)
        Wint    %intertidal width (Whw-Wlw)
    end

    properties (Transient)
        ModelMovie
    end

%%
    methods 
        function obj = CSTdataimport()     
            %class constructor
            %initialise list of available input file formats. Format is:
            %{'label 1','formatfile name 1';'label 2','formatfile name 2'; etc}
            obj.DataFormats = {'Default format','cst_dataformat'};
            %define file specification, format is: {multiselect,file extension types}
            obj.FileSpec = {'off','*.txt;*.csv'};     
            obj.idFormat = 1;
        end
    end
%%   
    methods (Static)
        function loadData(mobj,classname)
            %load user data set from one or more files
            obj = CSTdataimport();
            
            msg1 = 'You will be prompted to load 4 files,in the following order:';
            msg2 = 'in the following order:';
            msg3 = '1) Along-channel form data, Amtl, Whw, etc';
            msg4 = '2) X-T variation in water level';
            msg5 = '3) X-T variation in velocity';
            msg6 = 'Press Cancel if water level or velocity not available';
            msg7  = 'X & T intervals must be the same in all files';
            msgtxt = sprintf('%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s',msg1,msg2,...
                                            msg3,msg4,msg5,msg6,msg7);
            hm = msgbox(msgtxt,'Load file');
            waitfor(hm)

            FormData = CSTformprops.loadData(mobj,true);
            if isempty(FormData), return; end
            x = FormData.Dimensions.X;
            isflip = FormData.MetaData;
            
            %get data
            funcname = 'getData';
            [dst,ok] = callFileFormatFcn(obj,funcname,obj,x,isflip);
            if ok<1 || isempty(dst), return; end
            dst.AlongChannelForm = FormData;  %add form data to dst

            %if velocity imported, decompose to tidal, river and stokes
            dst = cst_decompose_velocity(dst);

            setDataSetRecord(obj,mobj.Cases,dst,'data');
            getdialog(sprintf('Data loaded in class: %s',classname));
        end         
    end
%%
    methods
        function tabPlot(obj,src,mobj)
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

%%
        function output = dataQC(obj)
            %quality control a dataset
            % datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
            % dst = obj.Data.(datasetname);      %selected dstable
            warndlg('No quality control defined for this format');
            output = [];    %if no QC implemented in dataQC
        end   

%%
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

    end
end