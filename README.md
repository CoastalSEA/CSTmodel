# CSTmodel
Model to compute the mean tide level, high and low water levels, tidal 
velocity amplitude and river velocity along the length of a convergent 
estuary 

## Licence
The code is provided as Open Source code (issued under a BSD 3-clause License).

## Requirements
CSTmodel is written in Matlab(TM) and requires v2016b, or later. In addition, CSTmodel requires the _dstoolbox_ and the _muitoolbox_.

## Background
The model computes the mean tide level, high and low water levels, tidal velocity amplitude and river velocity along the length of a 
convergent estuary using the analytical model of Cai, Savenije and Toffolon (hence the CST model) as described in (Savenije, 2005; Cai, 2014).

## CSTmodel classes
* *CSTmodel* - defines the behaviour of the main UI.
* *CSTparameters* - defines the model input parameters.
* *CSTrunparams* - defines the model run time parameters.
* *CSTformprops* - load estuary form properties from file and display on the Form tab.
* *CSTrunmodel* - run the model and save the results.
* *CSTdataimport* - import a data set.

## CSTmodel functions
For details of model functions used see the online help or CSTmodel Manual.

## Manual
The CSTmodel manual in the app/doc folder provides further details of setup and configuration of the model. The files for the example use case can be found in
the app/example folder. 

## See Also
The repositories for _dstoolbox_, _muitoolbox_ and _muiAppLIb_.