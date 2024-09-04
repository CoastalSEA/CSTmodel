function cst_x_plot(obj,ax,range)
%
%-------header-------------------------------------------------------------
% NAME
%   cst_x_plot.m
% PURPOSE
%   plot along channel variations on a tab or figure
% USAGE
%   cst_x_plot(obj,ax,range)
% INPUTS
%   obj - class handle for CSTrunmodel or CSTdataimport
%   ax - axes handle for Figure or Tab
%   range - lower and upper range of x-axis
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
    dsthyd = obj.Data.AlongChannelHydro;
    dstform = obj.Data.AlongChannelForm;

    x = dsthyd.Dimensions.X; 
    z = dsthyd.MeanTideLevel;  %mean tide level
    a = dsthyd.TidalElevAmp;   %tidal amplitude
    r = dsthyd.LWHWratio;      %LW/HW ratio
	U = dsthyd.TidalVelAmp;    %tidal velocity amplitude
	v = dsthyd.RiverVel;       %river velocity 
	d = dstform.Hmtl;          %hydraulic depth

    if nargin>2
        idxmin = find(x<=range{1},1,'last');  
        idxmax = find(x>=range{2},1,'first');
        x = x(idxmin:idxmax);
        z = z(idxmin:idxmax);
        a = a(idxmin:idxmax);
        r = r(idxmin:idxmax);
        U = U(idxmin:idxmax);
        v = v(idxmin:idxmax);
        d= d(idxmin:idxmax);
    end
    
    hwl = 2*a./(1+r);          %adjust amplitude for asymmetry in LW/HW
    lwl = r.*hwl;

    %gerenate plot
    yyaxis left
    plot(x,z,'-r','DisplayName','Mean tide level');        %plot time v elevation
    hold on
    plot(x,(z+hwl),'-.b','DisplayName','High water level') %plot high water level
    plot(x,(z-lwl),'-.b','DisplayName','Low water level')  %plot low water level
	plot(x,(z-d),'-k','DisplayName','Hyd. depth to mtl')   %hydraulic depth below mean tide level
    ylabel('Elevation (mOD)'); 
	yyaxis right
	plot(x,U,'--','Color',mcolor('orange'),'DisplayName','Tidal velocity')%plot tidal velocity
	plot(x,v,'--','Color',mcolor('green'),'DisplayName','River velocity') %plot river velocity
    hold off
    xlabel('Distance from mouth (m)'); 
    ylabel('Velocity (m/s)'); 
	legend('Location','best');			
    title ('Along channel variation');
    subtitle(sprintf('Case: %s',dsthyd.Description));
    ax.Color = [0.96,0.96,0.96];  %needs to be set after plo
end
