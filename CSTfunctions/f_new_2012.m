function [mu,delta,lambda,epsilon]=f_new_2012(gamma,chi)
%Analyticl solution for tidal dynamics proposed by Cai et al. (2012)
%*************************Reference*******************************
%Cai, H., H. H. G. Savenije, and M. Toffolon, 2012, 
%A new analytical framework for assessing the effect of sea-level rise and dredging on tidal damping in estuaries, 
%Journal of Geophysical Research, 117, C09023, doi:10.1029/2012JC008000.
%*****************************************************************
% USAGE
%       [mu,delta_new,lambda,epsilon]= f_new_2012(gamma,chi)
% 
% INPUTS
% gamma - estuary shape number
% chi   - friction number
%
% RESULTS
% mu      - velocity number
% delta   - damping number
% lambda  - celerity number
% epsilon - phase lag between HW and HWS (or LW and LWS)
% 
% AUTHOR
% Huayang Cai (h.cai@tudelft.nl)
% iht modified to use fsolve
%************************************************************

    %Make a starting guess at the solution
    [mu_tof,delta_tof,lambda_tof,~]=f_toffolon_2011(gamma,chi); %linear solution
    x0=[mu_tof delta_tof lambda_tof];
    x0=x0';
    %solve equations for mu,delta,lambda using fsolve
    [y,~,~] = Newton_new_2012(gamma,chi,x0); 
    mu=y(1);
    delta=y(2);
    lambda=y(3);
    epsilon=atan(lambda/(gamma-delta));
    if (chi==0 && gamma>=2)
        mu=(gamma-sqrt(gamma^2-4))/2;
        lambda=0;
        delta=mu;
        epsilon=0; 
    end
end
%%
function [y,exitflag,iter] = Newton_new_2012(gamma, chi, x0)
    %Function to find solution for y using fsolve
    options = optimoptions('fsolve','MaxIterations',1000,'FunctionTolerance',1e-6,...
                   'Display','off');
    [y,~,exitflag,output] = fsolve(@myfun,x0,options); 
    iter = output.iterations;
    %Nested functions-----------------------------------------------
	function F = myfun(x)
        % set of nonlinear equations for mu, delta, lambda 
        F(1,1) = (gamma-x(2))^2-1/x(1)^2+x(3)^2;
        F(2,1) = gamma-x(2)-(1-x(3)^2)/x(2);
        F(3,1) = x(2)-gamma/2+4*chi*x(1)/(9*pi*x(3))+chi*x(1)^2/3;
    end
end
