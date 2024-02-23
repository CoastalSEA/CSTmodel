function cst_x_plot(obj,ax)
%
%-------header-------------------------------------------------------------
% NAME
%   cst_x_plot.m
% PURPOSE
%   plot along channel variations on a tab or figure
% USAGE
%   cst_x_plot(obj,ax)
% INPUTS
%   obj - class handle for CSTrunmodel or CSTdataimport
%   ax - axes handle for Figure or Tab
% OUTPUTS
%   along-channel graphic showing water levels and velocities
% NOTES 
%   used in CSTmodel as tabPlot for CSTrunmodel and CSTdataimport
% SEE ALSO
%   cst_xt_plot.m
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2024
%-------------------------------------------------------------------------
%
    dst = getHydroData(obj);
    x = dst.Dimensions.X; 
    z = dst.MeanTideLevel;  %mean tide level
    a = dst.TidalElevAmp;   %tidal amplitude
	U = dst.TidalVelAmp;    %tidal velocity amplitude
	v = dst.RiverVel;       %river velocity 
	d = dst.HydDepth;       %hydraulic depth
    %gerenate plot
    yyaxis left
    plot(x,z,'-r','DisplayName','MTL'); %plot time v elevation
    hold on
    plot(x,(z+a),'-.b','DisplayName','HWL')%plot high water level
    plot(x,(z-a),'-.b','DisplayName','LWL')%plot low water level
	plot(x,(z-d),'-k','DisplayName','Hydraulic depth')%hydraulic depth below mean tide level
    ylabel('Elevation (mOD)'); 
	yyaxis right
	plot(x,U,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity')%plot tidal velocity
	plot(x,v,'--','Color',mcolor('green'),'DisplayName','River velocity') %plot river velocity
    hold off
    xlabel('Distance from mouth (m)'); 
    ylabel('Velocity (m/s)'); 
	legend('Location','best');			
    title ('Along channel variation');
    subtitle(sprintf('Case: %s',dst.Description));
    ax.Color = [0.96,0.96,0.96];  %needs to be set after plo
end
%%
function dst = getHydroData(obj)
    %extract data from source depending on class type
    if isa(obj,'CSTrunmodel')
        dst = obj.Data.AlongChannelHydro;
    elseif isa(obj,'CSTdataimport')
        Hmtl = obj.Data.FormData.Hmtl;
        dst1 = obj.Data.AlongChannelHydro;
        dst = addvars(dst1,Hmtl,'NewVariableNames','HydDepth');
    else
        warndlg('Class not recognised')
    end
end
