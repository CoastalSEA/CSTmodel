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
%
% AUTHOR
% Huayang Cai (h.cai@tudelft.nl)
%
%************************************************************
function [mu,delta,lambda,epsilon]=f_new_2012(gamma,chi)
    %Make a starting guess at the solution
   [mu_tof,delta_tof,lambda_tof,~]=f_toffolon_2011(gamma,chi); %linear solution
   x0=[mu_tof delta_tof lambda_tof];
   x0=x0';

    [y,~] = Newton_new_2012(gamma, chi, x0); %Newton-Raphson method
    mu=y(1);
    delta=y(2);
    lambda=y(3);
    epsilon=atan(y(3)/(gamma-y(2)));
    if(chi==0 && gamma>=2)
        mu=(gamma-sqrt(gamma^2-4))/2;
        lambda=0;
        delta=mu;
        epsilon=0; 
    end
end
%%
function [y,iter] = Newton_new_2012(gamma, chi, x0)
    %Function of Newton-Raphson method
%     maxiter=1000;tol=1e-8;d_c=1;ierr=1;it=0;maxit=10;
%     while ierr>0 && it<=maxit
%         it=it+1;
%         [y,iter,ierr] = Newton(@myfun,@Jac,x0,maxiter,tol,d_c);
%         if(ierr==1)
%             d_c=d_c/2;
%         end
%     end
options = optimoptions('fsolve','MaxIterations',1000,'FunctionTolerance',1e-6,...
                   'Display','off');
    y=fsolve(@myfun,x0,options); iter = 1;
    %Nested functions-----------------------------------------------
	function F = myfun(x)
        % set of nonlinear equations
        F(1,1) = (gamma-x(2))^2-1/x(1)^2+x(3)^2;
        F(2,1) = gamma-x(2)-(1-x(3)^2)/x(2);
        F(3,1) = x(2)-gamma/2+4*chi*x(1)/(9*pi*x(3))+chi*x(1)^2/3;
    end
    %
    function J=Jac(x) %
        %Jacobian function for nonlinear equations
        J(1,1)=2/x(1)^3;
        J(1,2)=-2*gamma+2*x(2);
        J(1,3)=2*x(3);
        J(2,1)=0;
        J(2,2)=-1+(1-x(3)^2)/x(2)^2;
        J(2,3)=2*x(3)/x(2);
        J(3,1)=4*chi/(9*pi*x(3))+2*chi*x(1)/3;
        J(3,2)=1;
        J(3,3)=-4*chi*x(1)/(9*pi*x(3)^2);
    end
end
%%
function [solution,iter,ierr]=Newton(MyFunc,Jacobian,Guess,maxiter,tol,d_c) 
    %Global convergence of damped Newton's method
    x=Guess;
%         error=1000;
    iter=0;
    F= feval(MyFunc,x);
    fnrm=norm(F,inf);
    ierr=0;
    error=max(abs(F));
    while error>tol && iter<=maxiter
        iter=iter+1;
        fnrmo=fnrm;
        error0=error;
        F=feval(MyFunc,x);
        J=feval(Jacobian,x);
        dx=J\(-F);
        x=x+d_c*dx;
        F=feval(MyFunc,x);
        fnrm=norm(F,inf);
        rat=fnrm/fnrmo;
         error=max(abs(F));
         rat2=error/error0;
         if rat >=1 && rat2>=1
            ierr=1;break;
         end
    end
    solution=x;
end


