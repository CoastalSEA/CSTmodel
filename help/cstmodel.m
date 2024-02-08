%% CSTmodel
% Model to compute the mean tide level, high and low water levels, tidal 
% velocity amplitude and river velocity along the length of a convergent 
% estuary 

%% Licence
% The code is provided as Open Source code (issued under a GNU General 
% Public License).

%% Requirements
% CSTmodel is written in Matlab(TM) and requires v2016b, or later. In addition, 
% CSTmodel requires both the <matlab:doc('dstoolbox') dstoolbox> and the 
% <matlab:doc('muitoolbox') muitoolbox>

%% Background
% The model computes the mean tide level, high and low water levels, 
% tidal velocity amplitude and river velocity along the length of a 
% convergent estuary using the analytical model of Cai, Savenije and 
% Toffolon (hence the CST model) as described in (Savenije, 2005; Cai, 2014).

%% CSTmodel classes
% * *CSTmodel* - defines the behaviour of the main UI.
% * *CSTparameters* - defines the model input parameters.
% * *CSTrunparams* - defines the model run time parameters.
% * *CSTformprops* - load estuary form properties from file and display on
% the Form tab
% * *CSTrunmodel* - Handle the running of the model, saving of results and 
% display on the X-Plot and XT-Plot tabs.

%% CSTmodel functions
% *cst_model* - model code modified from source provided by Huayang Cai

%% Manual
% The <matlab:cst_open_manual manual> provides further details of setup and 
% configuration of the model. Sample input files can be found in
% the example folder <matlab:cst_example_folder here>. 

%% See Also
% <matlab:doc('muitoolbox') muitoolbox>, <matlab:doc('dstoolbox') dstoolbox>.
	