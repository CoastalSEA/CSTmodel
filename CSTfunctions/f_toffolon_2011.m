function [mu,delta,lambda,epsilon]=f_toffolon_2011(gamma,chi)
%Analyticl solution for tidal dynamics proposed by Toffolon and Savenije (2011)
%*************************Reference*******************************
%Toffolon, M., and H. H. G. Savenije (2011), 
%Revisiting linearized one-dimensional tidal propagation, 
%J Geophys Res-Oceans, 116, doi:10.1029/2010JC006616.
%*****************************************************************
% USAGE
%       [mu,delta_new,lambda,epsilon]= f_toffolon_2011(gamma,chi)
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
% iht changed for loop to a while loop 31/7/20
%************************************************************
    kappa=8/(3*pi);
    Gamma=1-gamma.^2/4;
    Omega=sqrt(Gamma.^2+chi.^2);
    K=sqrt((Omega-Gamma)/2);
    mu=1./sqrt(1+gamma.*K+2*K.^2);
    chi0=chi;
    diff = 1;
    while diff>0.001
        mu0 = mu;
        chi=chi0*kappa.*mu;
        Omega=sqrt(Gamma.^2+chi.^2);
        K=sqrt((Omega-Gamma)/2);
        mu=1./sqrt(1+gamma.*K+2*K.^2);   
        diff = abs(mu-mu0);
    end
    delta=gamma/2-K;
    epsilon=atan(chi./(gamma.*K+2*K.^2));
    lambda=sqrt(K.^2+Gamma);
    %frictionless wave
    mu_f=ones(size(gamma));
    delta_f=gamma./2;
    lambda_f=sqrt(1-(gamma./2).^2);
    epsilon_f=acos(gamma./2);
    %check possibile infinite values for chi-->0
    pp=isnan(epsilon);
    mu(pp)=mu_f(pp);
    delta(pp)=delta_f(pp);
    lambda(pp)=lambda_f(pp);
    epsilon(pp)=epsilon_f(pp);
end
