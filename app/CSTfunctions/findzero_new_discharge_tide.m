function [y,exitflag,iter] = findzero_new_discharge_tide(gamma,chi,rs,phi,zeta,x0)
%
%-------function help------------------------------------------------------
% NAME
%   findzero_new_discharge_river.m
% PURPOSE
%   find y for given gamma and chi where tide is dominan
% USAGE
%   [y,exitflag,iter] = findzero_new_discharge_river(gamma,chi,rs,phi,zeta,x0)
% INPUTS
%   gamma - estuary shape number
%   chi   - friction number  
%   rs - storage ratio
%   phi - ratio of discharge to csa x velocity
%   zeta - dimensionless amplitude
%   x0 - inital guess of mu, delta, lambda
% OUTPUTS
%   y - [3x1] array containing mu, delta, lambda
%   exitflag - flag to inidicate state at end of call to fsolve
%   iter - number of iterations
% SEE ALSO
%   used in cst_model.m
%
% Author: HuaYang Cai, tu Delft
% iht modified to use fsolve
%--------------------------------------------------------------------------
%
    ga=acos(-phi);
    if(phi==0)
        L0=0;L1=16/(3*pi);
    elseif(phi>1)
        L0=-2-4*phi^2;
        L1=4*phi;
    else
        L0=(2+cos(2*ga))*(2-4*ga/pi)+6*sin(2*ga)/pi;
        L1=6*sin(ga)/pi+2*sin(3*ga)/(3*pi)+(4-8*ga/pi)*cos(ga);
    end
    %use fsolve to find solution
    options = optimoptions('fsolve','MaxIterations',1000,'FunctionTolerance',1e-6,...
                   'Display','off');
    [y,~,exitflag,output] = fsolve(@myfun,x0,options); 
    iter = output.iterations;
    %nested functions------------------------------------------------------
	function F = myfun(x)
        % set of nonlinear equations for 
        F(1,1) = (gamma-x(2))^2-1/x(1)^2+x(3)^2;
        F(2,1) = gamma-x(2)-(1-x(3)^2)/x(2);
        F(3,1) = x(2)-x(1)^2*(gamma*(1-sqrt(1+zeta)*phi/(x(1)*x(3))+phi/(x(1)*x(3)))-...
            chi*(2*phi^2/3+16*x(1)*x(3)*phi*zeta/9+...
            2*x(1)^2*x(3)^2/3+L1*x(1)*x(3)/6-L0*zeta/9))/(x(1)^2*...
            ((1-sqrt(1+zeta)*phi/(x(1)*x(3))+phi/(x(1)*x(3)))-rs*phi*zeta/(x(1)*x(3)))+1);
    end
end
