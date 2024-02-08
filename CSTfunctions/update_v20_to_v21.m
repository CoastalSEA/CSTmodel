function update_v20_to_v21(obj)
%
%-------header-------------------------------------------------------------
% NAME
%   update_v20_to_v21.m 
% PURPOSE
%   update saved models from v2.0 to v2.1.
% USAGE
%   update_v20_to_v21(obj)
% INPUTS
%   obj - instance of model
% RESULTS
%   saved model updated from v2.0 to v2.1.
% NOTES
%   Called in muiModelUI.loadModel when old and new version numbers do not
%   match.
% To use from command line, open ASMITA using:
% >>cs=CSTmodel;     and then call
% >>update_v20_to_v21(cs)
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2024 
%--------------------------------------------------------------------------
%

    %modify CST run parameters
    obj.Inputs.CSTrunparams.PropertyLabels = {'Time increment (hr)'...
                                            'Distance increment (m)',...
                                            'Use observed form, (0/1)',...
                                            'Output all properties, (0/1)'};

    obj.Inputs.CSTrunparams.isfull = false;
end