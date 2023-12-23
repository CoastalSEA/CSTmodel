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
        function loadData(mobj)
            %read and load a data set from a file
            obj = CSTformprops;                      
            [data,~,filename] = readInputData(obj);             
            if isempty(data), return; end
            dsp = setDSproperties(obj);  %initialise dsproperties for data
            
            %code to parse input data and assign to varData
            rdata = data{1};
            vardata = data(2:end);

            %load the results into a dstable  
            dst = dstable(vardata{:},'DSproperties',dsp); 
            dst.Dimensions.X = rdata;
            %assign metadata about data
            dst.Source{1} = filename;
            obj.FormData = dst;
            %setDataRecord classobj, muiCatalogue obj, dataset, classtype
            setClassObj(mobj,'Inputs','CSTformprops',obj);          
        end 
    end   
%%
    methods
        function tabPlot(obj,src,mobj)
            %generate plot for display on Form tab
            %plots the model form if defined in CSTparameters and the
            %observed form if loaded in CSTformprops
            ht = findobj(src,'Type','axes');
            delete(ht);
            ax = axes('Parent',src,'Tag','Form');
            %create three subplots
            s1 = subplot(3,1,1,ax);
            s2 = subplot(3,1,2);
            s3 = subplot(3,1,3);

            dst = obj.FormData; 
            if ~isempty(dst)            
                %plot observed data from CSTformparams
                if ~isprop(dst,'Amtl')
                    dst = activatedynamicprops(dst);
                end
                X = dst.Dimensions.X;
                subplot(s1)
                plot(X,dst.Amtl,'DisplayName','Observed'); %plot distance v CSA
                %
                subplot(s2)
                plot(X,dst.Whw,'DisplayName','High water');%plot distance v Width HW             
                hold on
                plot(X,dst.Wlw,'DisplayName','Low water'); %plot distance v Width LW
                %
                subplot(s3)
                if all(isnan(dst.N))
                    plot(X,zeros(size(X)),'DisplayName','Observed');                  
                else
                    plot(X,dst.N,'DisplayName','Observed');    %plot distance v N
                end
            end 
            %
            inpobj = getClassObj(mobj,'Inputs','CSTparameters');
            if ~isempty(inpobj) && ~isempty(inpobj.AreaELength)
                %plot model form based on CSTparameters
                Le = inpobj.EstuaryLength;   %estuary length (m)   
                Wm = inpobj.MouthWidth;      %width at mouth (m)
                Lw = inpobj.WidthELength;    %width convergence length (m) =0 import from file
                Am = inpobj.MouthCSA;        %area at mouth (m^2)
                La = inpobj.AreaELength;     %area convergence length (m)  =0 import from file     
                Wr = inpobj.RiverWidth;      %upstream river width (m) 
                Ar = inpobj.RiverCSA;        %upstream river cross-sectional area (m^2)
                xT = inpobj.xTideRiver;      %distance from mouth to estuary/river switch
                N = inpobj.Manning;          %Manning friction coefficient [mouth switch head]
                if exist('X','var')~=1
                    X = 0:1000:Le;
                end
                
                Ax = Ar+(Am-Ar)*exp(-X/La); 
                Wx = Wr+(Wm-Wr)*exp(-X/Lw); 
                Ks = interp1([0 xT max(X)],N,X,'linear');
                
                subplot(s1)
                hold on
                plot(X,Ax,'r--','DisplayName','Model'); %plot distance v CSA
                hold off
                subplot(s2)
                hold on
                plot(X,Wx,'r--','DisplayName','Model'); %plot distance v Width
                hold off
                subplot(s3)
                hold on
                plot(X,Ks,'r--','DisplayName','Model'); %plot distance v Manning
                hold off
            end
            %add title, axis labels and legends
            subplot(s1);
            ylabel('Area (m^2)');
            legend
            subplot(s2);
            ylabel('Width (m)');
            legend
            subplot(s3);
            ylabel('Mannings N');
            xlabel('Distance from mouth (m)'); 
            legend
            if isempty(dst)
                sgtitle('Modelled Estuary Form Properties','FontSize',10);
            else
                sgtitle(sprintf('Estuary Form Properties\nFile: %s',(dst.Source{1})),'FontSize',10); 
            end           
        end     
    end
%%
    methods (Access = private)
        function [data,header,filename] = readInputData(~) 
            %read wind data (read format is file specific).
            [fname,path,~] = getfiles('FileType','*.txt');
            if fname==0, data = []; header = []; filename = []; return; end
            filename = [path fname];
            dataSpec = '%f %f %f %f %f'; 
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
                'Name',{'Amtl','Whw','Wlw','N'},...                  
                'Description',{'Area at mean tide level',...
                               'Width at high water',...
                               'Width at low water',...
                               'Mannings N'},...
                'Unit',{'m/^2','m','m','-'},...
                'Label',{'Area (m^2)','Width (m)','Width (m)','Mannings N'},...
                'QCflag',repmat({'data'},1,4));  
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