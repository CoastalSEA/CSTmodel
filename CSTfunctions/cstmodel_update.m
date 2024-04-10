function cstmodel_update(obj,oldV,newV)
%
%-------header-------------------------------------------------------------
% NAME
%   cstmodel_update.m 
% PURPOSE
%   update saved models to newer versions of CSTmodel
% USAGE
%   cstmodel_update(oldV,newV) 
% INPUTS
%   obj - instance of model
%   oldV - old version number as a character string
%   newV - new version number as a character string
% RESULTS
%   saved model updated to new version. If this is called from CSTmodel this
%   will be the version that is being run at the time.
% NOTES
%   Called in muiModelUI.loadModel when old and new version numbers do not
%   match.
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2024 
%--------------------------------------------------------------------------
%
    if strcmp(oldV,'2.0') && (strcmp(newV,'2.1') || strcmp(newV,'2.2') )
        update_v20_to_v21(obj);   
    else
        warndlg(sprintf('No update for version %s to version %s', oldV,newV))
    end
end

