%% CSTmodel classes and functions
% Summary of classes and functions used by the CSTmodel. Use the Matlab(TM)
% help function in the command window to get further details of each
% function.

%% Classes
% Summary of the classes used by the CSTmodel
%%
% * *CSTdataimport*: import a data set, adding the results to dstable
% and a record in a dscatlogue (as a property of muiCatalogue)
% * *CSTformprops*: import and hold the width and area data used in the CSTmodel
% * *CSTmodel*: main UI for CSTmodel interface, which implements the 
%   muiModelUI abstract class to define main menus
% * *CSTparameters*: input parameters to the CSTmodel
% * *CSTrunmodel*: calculate the mean tide level and tidal amplitude along an estuary
%   only works for a single channel (not a network)
% * *CSTrunparams*: run parameters to the CSTmodel
%

%% Functions
% Summary of functions available in the _CSTfunctions_ folder.
%%
% * *cst_dataformat.m*
% - functions to define metadata, read and load data from file for:
% CST model data format
%
% * *cst_model.m*
% - calculate the mean tide level and tidal amplitude along an estuary
% only works for a single channel (not a network)
%
% * *cst_x_plot.m* – plot along channel variations on a tab or figure
%
% * *cst_xt_plot.m* – plot variations in time or distance on a tab or figure
%
% * *cstmodel_update.m* –  update saved models to newer versions of CSTmodel
%
% * *findzero_new_discharge_river.m*
% - find y for given gamma and chi  with dominant river discharge
%
% * *findzero_new_discharge_tide.m*
% - find y for given gamma and chi where tide is dominant
%
% * *f_new_2012.m*
% - analyticl solution for tidal dynamics proposed by Cai et al. (2012)
%
% * *f_toffolon_2011.m*
% - analyticl solution for tidal dynamics proposed by Toffolon and Savenije (2011)
%
% * *newtonm.m*
% - Newton-Raphson solution of the Jacobian
%

%% See Also
% The <matlab:cst_open_manual manual>, which provides further details of setup and 
% configuration of the model.