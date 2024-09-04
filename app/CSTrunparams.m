classdef CSTrunparams < muiPropertyUI        
%
%-------class help---------------------------------------------------------
% NAME
%   CSTrunparams.m
% PURPOSE
%   Class for run parameters to the CSTmodel
% NOTE
%   Default DistInt set to 5000. Reducing distance increases resolution but
%   also run time and sensitivity of solution
% USAGE
%   obj = CSTrunparams.setInput(mobj); %mobj is a handle to Main UI
% SEE ALSO
%   inherits muiPropertyUI
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
%      
    properties (Hidden)
        %abstract properties in muiPropertyUI to define input parameters
        PropertyLabels = {'Time increment (hr)'...
                          'Distance increment (m)',...
                          'Use observed form, (0/1)',...
                          'Output all properties, (0/1)'};
        %abstract properties in muiPropertyUI for tab display
        TabDisplay   %structure defines how the property table is displayed 
    end
    
    properties
        TimeInt = 0.5   %time increment in analytical model (hrs)
        DistInt = 5000  %distance increment along estuary (m) 
        useObs = false  %flag to indicate whether to use 
        isfull = false  %flag to include all model properties in output
    end    

%%   
    methods (Access=protected)
        function obj = CSTrunparams(mobj)             
            %constructor code:            
            %TabDisplay values defined in UI function setTabProperties used to assign
            %the tabname and position on tab for the data to be displayed
            obj = setTabProps(obj,mobj);  %muiPropertyUI function
        end 
    end
%%  
    methods (Static)  
        function obj = setInput(mobj,editflag)
            %gui for user to set Parameter Input values
            classname = 'CSTrunparams';               
            obj = getClassObj(mobj,'Inputs',classname);
            if isempty(obj)
                obj = CSTrunparams(mobj);       
            end
            
            %use muiPropertyUI function to generate UI
            if nargin<2 || editflag
                %add nrec to limit length of props UI (default=12)
                obj = editProperties(obj);  
                %add any additional manipulation of the input here
            end
            setClassObj(mobj,'Inputs',classname,obj);
        end     
    end   
end