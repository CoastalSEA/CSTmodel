%% Menu Options
% Summary of the options available for each drop down menu.

%% File
% * *New*: clears any existing model (prompting to save if not already saved) and a popup dialog box prompts for Project name and Date (default is current date). 
% * *Open*: existing Asmita models are saved as *.mat files. User selects a model from dialog box.
% * *Save*: save a file that has already been saved.
% * *Save as*: save a file with a new or different name.
% * *Exit*: exit the program. The close window button has the same effect.

%% Tools
% * *Refresh*: updates Cases tab.
% * *Clear all > Project*: deletes the current project, including all Setup data and all Cases.
% * *Clear all > Figures*: deletes all results plot figures (useful if a large number of plots have been produced).
% * *Clear all > Cases*: deletes all Cases listed on the Cases tab but does not affect the model setup.

%% Project
% * *Project Info*: edit the Project name and Date
% * *Cases > Edit Description*: user selects a Case to edit the Case description.
% * *Cases > Edit Data Set*: initialises the Edit Data UI for editing data sets.
% * *Cases > Save*: user selects a data set to be saved from a list box of Cases and the is then prompted to name the file. The data are written to an Excel spreadsheet. 
% * *Cases > Delete*: user selects Case(s) to be deleted from a list box of Cases and results are then deleted (model setup is not changed).
% * *Cases > Reload*: user selects a Case to reload as the current parameter settings.
% * *Cases > View settings*: user selects a Case to display a table listing the parameters used for the selected Case. 
% * *Export/Import > Export*: user selects a Case class instance to export as a mat file.
% * *Export/Import > Import*: user selects an exported Case class instance (mat file) to be loaded.
%%
% *NB*: to export the data from a Case for use in another application 
% (eg text file, Excel, etc), use the *Project>Cases>Edit Data Set* option 
% to make a selection and then use the ‘Copy to Clipboard’ button to paste 
% the selection to the clipboard.

%% Setup
% * *Model Parameters*: dialogue to define model input parameters.
% * *Run Parameters*: dialogue to define model run time parameters.
% * *Estuary Properties*: dailogue to load estuary form properties from a
% file.
%%
% <html>
% <table border=1>
% <ul><u>Estuary Properties file format</u>: 1 line for header and 5
% columns of data as follows:<br>
% x - Distance from mouth,<br>
% Amtl - Area at mean tide level,<br>
% Whw - Width at high water,<br>
% Wlw - Width at low water,<br>
% Manning_N - Mannings N (optional)</ul> 
% </table></html>

%%
% * *Import Data*: dialogue to import observed or model data from a file. 
% Option to load data of _Along-channel Properties_ and variations of
% _Elevation_ and _Velocity_ over a tidal cycle.
%%
% <html>
% <table border=1>
% <ul><u>Along-channel Properties file format</u>: 1 line for header and 5
% columns of data as follows:<br>
% x - Distance from mouth,<br>
% Amtl - Area at mean tide level,<br>
% Whw - Width at high water,<br>
% Wlw - Width at low water,<br>
% Manning_N - Mannings N (optional)</ul> 
% </table>
% <table border=1>
% <ul><u>Elevation and Velocity file format</u>: 
% 1 line for header, 1 column for time 
% and N columns for elevation or velocity at each time interval, where
% N is the number of distances included in the along channel properties file.
% Elevations are water levels to a local datum and velocites are total
% velocities.</ul></table></html>

%%
% * *User Data*: option for user to define own data import

%%
% * *Model Constants*: a number of constants are used in the model. Generally, the default values are appropriate but these can be adjusted and saved with the project if required.

%% Run
% * *Run Model*: runs model, prompts for a Case description, which is added to the listing on the Cases tab.
% * *Derive Output*: initialises the Derive Output UI to select and define manipulations of the data or call external functions and load the result as new data set.

%% Analysis
% * *Plots*: initialises the Plot UI to select variables and produce various types of plot. The user selects the Case, Dataset and Variable to used, along with the Plot type and any Scaling to be applied from a series of drop down lists, 
% * *Statistics*: initialise the Statistics UI to select data and run a range of standard statistical methods.

%% Help
% * *Help>Documentation*: access the online documentation for CSTmodel.
% * *Help>Manual*: access the manual pdf file.

%% See Also
% The <matlab:cst_open_manual manual> provides further details of setup and 
% configuration of the model.