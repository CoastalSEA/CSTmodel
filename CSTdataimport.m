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
        function loadData(muicat,classname)
            %load user data set from one or more files
            obj = CSTdataimport();
            
            msg1 = 'You will be prompted to load 3 files,';
            msg2 = 'in the following order:';
            msg3 = '1) Along channel properties, msl, amp, etc';
            msg4 = '2) X-T variation in water level';
            msg5 = '3) X-T variation in velocity';
            msg6 = 'Press Cancel if water level or velocity not available';
            msg7  = 'X & T intervals must be the same in all files';
            msgtxt = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s',msg1,msg2,...
                                                msg3,msg4,msg5,msg6,msg7);
            hm = msgbox(msgtxt,'Load file');
            waitfor(hm)

            [fname,path,nfiles] = getfiles('MultiSelect',obj.FileSpec{1},...
                'FileType',obj.FileSpec{2},'PromptText','Select X-properties file:');
            if nfiles==0
                return;
            else
                filename = [path fname];    %single select returns char
            end
            
            %get data
            funcname = 'getData';
            [dst,ok] = callFileFormatFcn(obj,funcname,obj,filename);
            if ok<1 || isempty(dst), return; end
            %assign metadata about data, Note dst can be a struct
            dst = updateSource(dst,filename,1);

            setDataSetRecord(obj,muicat,dst,'data');
            getdialog(sprintf('Data loaded in class: %s',classname));
            %--------------------------------------------------------------
            function dst = updateSource(dst,filename,jf)
                if isstruct(dst)
                    fnames = fieldnames(dst);
                    for i=1:length(fnames)
                        dst.(fnames{i}).Source{jf,1} = filename;
                    end
                else
                    dst.Source{jf,1} = filename;
                end
            end
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
    end
end