function [y,iter] = findzero_new_discharge_river(gamma, chi, rs,phi,zeta,x0)
%
%-------function help------------------------------------------------------
% NAME
%   findzero_new_discharge_river.m
% PURPOSE
%   find y for given gamma and chi with dominant river discharge
% USAGE
%   [y,iter] = findzero_new_discharge_river(gamma, chi, rs,phi,zeta,x0)
% INPUTS
%   gamma - estuary shape number
%   chi   - friction number
%   rs - 
%   phi - 
%   zeta - 
%   x0 - 
% OUTPUTS
%   y - 
%   iter - number of iterations
% SEE ALSO
%   used in cst_model.m
%
% Author: HuaYang Cai, tu Delft
%--------------------------------------------------------------------------
%
    %find mu and delta for given gamma and chi with dominant river discharge
    ga=acos(-phi);
    if(phi==0)
        L0=0;L1=16/(3*pi);
        % p0=0;p2=0;p1=16/15;p3=32/15;
    elseif(phi<=1)
        L0=(2+cos(2*ga))*(2-4*ga/pi)+6*sin(2*ga)/pi;
            L1=6*sin(ga)/pi+2*sin(3*ga)/(3*pi)+(4-8*ga/pi)*cos(ga);
        % p0=-7*sin(2*ga)/120+sin(6*ga)/24-sin(8*ga)/60;
        % p1=7*sin(ga)/6-7*sin(3*ga)/30-7*sin(5*ga)/30+sin(7*ga)/10;
        % p2=pi-2*ga+sin(2*ga)/3+19*sin(4*ga)/30-sin(6*ga)/5;
        % p3=4*sin(ga)/3-2*sin(3*ga)/3+2*sin(5*ga)/15;
    else
        L0=-2-4*phi^2;
        L1=4*phi;
    	% p0=0;p1=0;p3=0;p2=-pi;
    end
    %Jacobian function for nonlinear equations
    % maxiter=1000;tol=1e-8;d_c=1;ierr=1;it=0;maxit=10;
    % while ierr>0 && it<=maxit
    %     it=it+1;
    % [y,iter,ierr] = Newton(@myfun,@Jac,x0,maxiter,tol,d_c);
    % if(ierr==1)d_c=d_c/2;end
    % end
    %[y,iter,~]=newtonm(x0,@myfun,@Jac);
    options = optimoptions('fsolve','MaxIterations',1000,'FunctionTolerance',1e-6,...
                   'Display','off');
    y=fsolve(@myfun,x0,options); iter = 1;
%nested functions------------------------------------------------------
	function F = myfun(x)
        % set of nonlinear equations
        F(1,1) = (gamma-x(2))^2-1/x(1)^2+x(3)^2;
        F(2,1) = gamma-x(2)-(1-x(3)^2)/x(2);
        F(3,1) = x(2)-x(1)^2*(gamma*(1-sqrt(1+zeta)*phi/(x(1)*x(3))+phi/(x(1)*x(3)))-...
            chi*(8*phi^2*zeta/9+4*x(1)*x(3)*phi/3+...
            8*x(1)^2*x(3)^2*zeta/9+L1*x(1)*x(3)/6-L0*zeta/9))/(x(1)^2*...
            ((1-sqrt(1+zeta)*phi/(x(1)*x(3))+phi/(x(1)*x(3)))-rs*phi*zeta/(x(1)*x(3)))+1);
    end
    %
    function J=Jac(x)
        %Jacobian function for nonlinear equations
        J(1,1)=2/x(1)^3;
        J(1,2)=-2*gamma+2*x(2);
        J(1,3)=2*x(3);
        J(2,1)=0;
        J(2,2)=-1+(1-x(3)^2)/x(2)^2;
        J(2,3)=2*x(3)/x(2);
        J(3,1)=x(3)/(18*(-x(1)^2*x(3)+x(1)*sqrt(1+zeta)*phi-x(1)*phi+x(1)*rs*phi*zeta-x(3))^2)*...
            (-0.18e2 * gamma * phi - 0.36e2 * gamma * x(1) * x(3)...
            + 0.3e1 * chi * x(1) ^ 4 * x(3) ^ 2 * L1 + 0.9e1 * chi * x(1) ^ 2 * x(3) ^ 2 * L1...
            + 0.24e2 * x(1) ^ 4 * phi * chi * x(3) ^ 2 + 0.6e1 * x(1) ^ 3 * phi * chi * x(3) * L1...
            + 0.72e2 * chi * x(1) ^ 2 * x(3) ^ 2 * phi + 0.48e2 * x(1) ^ 3 * phi ^ 2 * chi * x(3)...
            - 0.6e1 * x(1) ^ 3 * phi * chi * x(3) * L1 * sqrt((1 + zeta)) + 0.2e1 * x(1) ^ 2 * phi * chi * L0 * zeta * sqrt((1 + zeta))...
            + 0.2e1 * x(1) ^ 2 * phi * chi * L0 * (zeta ^ 2) * rs - 0.48e2 * x(1) ^ 3 * phi ^ 2 * chi * x(3) * rs * zeta...
            - 0.48e2 * x(1) ^ 4 * phi * chi * x(3) ^ 2 * (zeta ^ 2) * rs...
            - 0.48e2 * x(1) ^ 4 * phi * chi * x(3) ^ 2 * zeta * sqrt((1 + zeta))...
            - 0.6e1 * x(1) ^ 3 * chi * x(3) * L1 * rs * phi * zeta + 0.18e2 * gamma * sqrt((1 + zeta)) * phi...
            + 0.18e2 * x(1) ^ 2 * phi * gamma * rs * zeta - 0.2e1 * x(1) ^ 2 * phi * chi * L0 * zeta...
            + 0.48e2 * x(1) ^ 4 * phi * chi * x(3) ^ 2 * zeta + 0.16e2 * x(1) ^ 2 * phi ^ 3 * chi * zeta...
            + 0.64e2 * chi * x(1) ^ 3 * x(3) ^ 3 * zeta + 0.32e2 * chi * x(1) ^ 5 * x(3) ^ 3 * zeta...
            - 0.16e2 * x(1) ^ 2 * phi ^ 3 * chi * (zeta ^ 2) * rs - 0.4e1 * chi * x(1) * x(3) * L0 * zeta...
            + 0.32e2 * chi * x(1) * x(3) * phi ^ 2 * zeta - 0.16e2 * x(1) ^ 2 * phi ^ 3 * chi * zeta * sqrt((1 + zeta))...
            - 0.48e2 * x(1) ^ 3 * phi ^ 2 * chi * x(3) * sqrt((1 + zeta)));
        J(3,2)=1;
        J(3,3)=x(1)/(18*(-x(1)^2*x(3)+x(1)*sqrt(1+zeta)*phi-x(1)*phi+x(1)*rs*phi*zeta-x(3))^2)*...
            (-(2 * x(1) ^ 2 * phi * chi * L0 * zeta) + 0.18e2 * (x(1) ^ 2) * phi * gamma * rs * zeta...
            - 0.16e2 * (x(1) ^ 2) * (phi ^ 3) * chi * zeta * sqrt((1 + zeta)) - 0.16e2 * (x(1) ^ 2) * (phi ^ 3) * chi * (zeta ^ 2) * rs...
            - 0.48e2 * (x(1) ^ 3) * (phi ^ 2) * chi * x(3) * rs * zeta - 0.48e2 * (x(1) ^ 4) * phi * chi * x(3) ^ 2 * zeta * sqrt((1 + zeta))...
            - 0.48e2 * (x(1) ^ 4) * phi * chi * x(3) ^ 2 * (zeta ^ 2) * rs - 0.6e1 * (x(1) ^ 3) * phi * chi * x(3) * L1 * sqrt((1 + zeta))...
            - 0.6e1 * L1 * chi * (x(1) ^ 3) * x(3) * rs * phi * zeta + 0.2e1 * (x(1) ^ 2) * phi * chi * L0 * zeta * sqrt((1 + zeta))...
            + 0.2e1 * (x(1) ^ 2) * phi * chi * L0 * (zeta ^ 2) * rs + (16 * x(1) ^ 2 * phi ^ 3 * chi * zeta)...
            - 0.48e2 * (x(1) ^ 3) * (phi ^ 2) * chi * x(3) * sqrt((1 + zeta)) + 0.48e2 * (x(1) ^ 4) * phi * chi * x(3) ^ 2 * zeta...
            + 0.6e1 * (x(1) ^ 3) * phi * chi * x(3) * L1 + 0.18e2 * gamma * phi + 0.48e2 * (x(1) ^ 3) * (phi ^ 2) * chi * x(3)...
            - 0.18e2 * gamma * sqrt((1 + zeta)) * phi...
            + 0.24e2 * (x(1) ^ 4) * phi * chi * x(3) ^ 2 + 0.24e2 * chi * (x(1) ^ 2) * x(3) ^ 2 * phi...
            + 0.32e2 * chi * (x(1) ^ 5) * x(3) ^ 3 * zeta + 0.32e2 * chi * (x(1) ^ 3) * x(3) ^ 3 * zeta...
            + 0.3e1 * chi * (x(1) ^ 4) * x(3) ^ 2 * L1 + 0.3e1 * chi * (x(1) ^ 2) * x(3) ^ 2 * L1);
    end
end
