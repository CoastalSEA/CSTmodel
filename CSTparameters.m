classdef CSTparameters < muiPropertyUI                
%
%-------class help---------------------------------------------------------
% NAME
%   CSTparameterse.m
% PURPOSE
%   Class for input parameters to the CSTmodel
% USAGE
%   obj = CSTparameters.setInput(mobj); %mobj is a handle to Main UI
% SEE ALSO
%   inherits muiPropertyUI
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
%      
    properties (Hidden)
        %abstract properties in muiPropertyUI to define input parameters
        PropertyLabels = {'Estuary length (m)',...
            'Width at mouth (m)',...
            'Width convergence length (m)',...
            'Area at mouth (m^2)',...
            'Area convergence length (m)',...
            'River width (m)',...
            'River Area (m^2)',...
            'Distance from mouth to estuary/river switch (m)',...
            'Manning friction coefficient [mouth switch head]',...
            'Storage width ratio [mouth switch head]',... 
            'Mean tide level at mouth (mOD)',...
            'Tidal amplitude (m)',...
            'Tidal period (hr)',...
            'River discharge (m3/s)'}
        %abstract properties in muiPropertyUI for tab display
        TabDisplay   %structure defines how the property table is displayed 
    end
    
    properties
        EstuaryLength   %estuary length (m) aka length of model domain
        MouthWidth      %width at mouth (m)
        WidthELength    %width convergence length (m) =0 import from file
        MouthCSA        %area at mouth (m^2)
        AreaELength     %area convergence length (m)  =0 import from file     
        RiverWidth      %upstream river width (m) 
        RiverCSA        %upstream river cross-sectional area (m^2)
        xTideRiver      %distance from mouth to estuary/river switch
        Manning         %Manning friction coefficient [mouth switch head]
        StorageRatio    %storage width ratio [mouth switch head] 
        MTLatMouth      %mean tide level at mouth (mOD)
        TidalAmplitude  %tidal amplitude (m)
        TidalPeriod     %tidal period (hr) 
        RiverDischarge  %river discharge (m^3/s) +ve downstream        
    end    

%%   
    methods (Access=protected)
        function obj = CSTparameters(mobj)             
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
            classname = 'CSTparameters';               
            obj = getClassObj(mobj,'Inputs',classname);
            if isempty(obj)
                obj = CSTparameters(mobj);               
            end
            
            %use muiPropertyUI function to generate UI
            if nargin<2 || editflag
                %add nrec to limit length of props UI (default=12)
                obj = editProperties(obj,14);  
                %add any additional manipulation of the input here
            end
            setClassObj(mobj,'Inputs',classname,obj);
        end     
    end
%%        
        %add other functions to operate on properties as required   
end