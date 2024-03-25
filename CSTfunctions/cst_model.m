function [resX,xdim,resXT,time] = cst_model(inp,rnp,est)
%
%------ function help------------------------------------------------------
% NAME
%   CST_model.m
% PURPOSE
%   calculate the mean tide level and tidal amplitude along an estuary
%   only works for a single channel (not a network)
% USAGE
%    [resX,xdim,resXT,time] = cst_model(inp,rnp,est)
% INPUTS
%   inp  - handle to input data in CSTparameters class instance
%   rnp  - handle to run parameters in CSTrunparams class instance
%   est  - handle to estuary form properties in CSTformprops class instance  
% OUTPUTS
%   resX - along channel results in cell array as follows
%       mean water suface elevation along estuary (zwx+zw0)
%       elevation amplitude along estuary (ax)
%       tidal velocity amplitude along estuary (Ux)        
%       river flow velocity along estuary (urx)
%       hydraulic depth at mtl (h_Qf)
%   xdim - along channel distances 
%   resXT - results for variables that are a function of x and t
%       tidal elevation over a tidal cycle (ht)
%       tidal velocity over tidal cycle (utt)
%       river velocity scaled for tidal elevation (urt)
%       Stokes drift velocity as a function of x and t (ust)
%   time - model time in 
% NOTES
%   Cai, H., H. H. G. Savenije, and M. Toffolon, 2012, 
%   A new analytical framework for assessing the effect of sea-level rise and dredging on tidal damping in estuaries, 
%   Journal of Geophysical Research, 117, C09023, doi:10.1029/2012JC008000.
% NOTE
%   Default rnp.DistInt set to 5000. Reducing distance increases 
%   resolution but also run time and sensitivity of solution
% SEE ALSO
%   f_new_2012 - analytical solution for mu,delta_new,lambda,epsilon
%   f_toffolon_2011 - analytical solution for mu,delta_new,lambda,epsilon
%   findzero_new_discharge_tide
%   findzero_new_discharge_river
%       which call: 
%       newtonm - newton-raphson solution
% AUTHOR
% code provided by HuaYang Cai for main computation functions.
% modified for use in ModelUI by Ian Townend
%--------------------------------------------------------------------------
%
    time = {}; xdim = {}; resXT = {}; resX = {};
    ok = matlab.addons.isAddonEnabled('Optimization Toolbox'); %requires v2017b
    if ok<1
        warndlg('Matlab ''Optimization Toolbox'' required to run the CSTmodel')
        return; 
    end
    g = 9.81;                 %acceleration due to gravity (m/s2)

    %extract data input model variables
    Le = inp.EstuaryLength;   %estuary length(m) aka length of model domain
    Bo = inp.MouthWidth;      %width at mouth (m)
    Lb = inp.WidthELength;    %width convergence length (m)
    Ao = inp.MouthCSA;        %area at mouth (m^2)
    LA = inp.AreaELength;     %area convergence length (m)       
    Br = inp.RiverWidth;      %upstream river width (m) 
    Ar = inp.RiverCSA;        %upstream river cross-sectional area (m^2)
    xsw = inp.xTideRiver;     %distance from mouth to estuary/river switch
    kM = inp.Manning;         %Manning friction coefficient [mouth switch head]
    Rs = inp.StorageRatio;    %storage width ratio [mouth switch head] 
    a = inp.TidalAmplitude;   %tidal amplitude (m)
    T = inp.TidalPeriod*3600; %tidal period (hr) 
    Qr = inp.RiverDischarge;  %river discharge (m^3/s) +ve downstream
    zw0 = inp.MTLatMouth;     %MTL at mouth (allows slr to be added)
    %
    dt = rnp.TimeInt*3600;    %time increment in analytical model
    dx = rnp.DistInt;         %distance increment along estuary

    %initialise space and time dimensions and x-t output variables
    xint = ceil(Le/dx);   %ensure x is an exact number of intervals of delX
    x = 0:dx:(xint*dx);
    tint = ceil(T/dt);    %ensure t is an exact number of intervals of delT
    t = 0:dt:(tint*dt);
    ht = zeros(length(x),length(t)); 
    utt = ht;
    xi = diag(x)*ones(size(ht)); 
    ti = ones(size(ht))*diag(t);
    Qf = ones(size(x))*Qr;
    w = 2*pi()/T;         %wave frequency (1/s)
    
    %initialise estuary form properties
    if rnp.useObs && ~isempty(est)
        dst = est.AlongChannelForm;                     %table of observed/loaded form data
        if any(strcmp(dst.VariableNames,'Hmtl')) && ... %not defined in file - loaded as NaN
                                (sum(dst.Hmtl)>0 || all(isnan(dst.Hmtl))) 
            Wmtl = dst.Amtl./dst.Hmtl;                  %user defined
        else
            Wmtl = dst.Wlw+(dst.Whw-dst.Wlw)/2.57;      %assume F&A ideal profile
        end
        Ximp = dst.Dimensions.X;
        A = fitChannelVar(Ximp,dst.Amtl,x,Ao,Ar);
        B = fitChannelVar(Ximp,Wmtl,x,Bo,Br); %width at mean tide level
        rs = fitChannelVar(Ximp,dst.Whw./dst.Wlw,x,dst.Whw(1)./dst.Wlw(1),1);%storage ratio
        if all(isnan(dst.N))                  %not defined in file - loaded as NaN
            Ks = interpChannelVar(kM,xsw,Le,x);
            if isempty(Ks), return; end
        else
            Ks = fitChannelVar(Ximp,dst.N,x,dst.N(1),dst.N(end)); %Manning coefficient
        end
    else
        % compute default area, width and depth values
        A = Ar+(Ao-Ar)*exp(-x/LA); 
        B = Br+(Bo-Br)*exp(-x/Lb);
        rs = interpChannelVar(Rs,xsw,Le,x);
        Ks = interpChannelVar(kM,xsw,Le,x);
        if isempty(rs) || isempty(Ks), return; end
    end
    h0 = A./B;
    h = h0'; Ax = A;
    %allocate space for variables
    Xi = zeros(length(x),1);
    eta = Xi; f = Xi; chi = Xi; mu = Xi; delta = Xi; lambda = Xi; 
    epsilon = Xi; Eta_Dx = Xi; v = Xi; c = Xi;
    eta_d = Xi; zeta = Xi; alpha = Xi; uf_v = Xi; L0 = Xi; L1 = Xi; v_Qf = Xi;
    phi = Xi; Eta_Dxf = Xi; c_Qf = Xi; Fs1 = Xi; Fs = Xi; Fl = Xi; f_av =Xi;
    h_Qf = Xi; zwx = Xi; c0_Qf = Xi; gamma_Qf = Xi; A_Qf = Xi; vdis_Qf = Xi;
%--------------------------------------------------------------------------
%% main computation algorithm based on Main_test.m provided by Cai
%--------------------------------------------------------------------------
    c0 = sqrt(g*h0./rs); %the classical wave celerity
    gamma=c0.*((Bo-Br)*exp(-x/Lb))./(Lb*w*(Br+(Bo-Br)*exp(-x/Lb)));
    vdis = Qf./A;
    eta0=a;             %tidal amplitude at the estuary mouth
    %
    c0 = c0';
    %initialise conditions at the estuary mouth
    % gamma_0=gamma;
    eta(1)=eta0;
    zeta(1)=eta(1)/h(1);                   %the tidal amplitude-to-depth ratio
    f(1)=g/(Ks(1)^2*h(1)^(1/3))/(1-(1.33*zeta(1))^2);
    chi(1)=rs(1)*f(1)*c0(1)*zeta(1)/(w*h(1));
    %
    [mu(1),delta(1),lambda(1),epsilon(1)]=f_new_2012(gamma(1),chi(1)); 
    %
    Eta_Dx(1)=delta(1)*eta(1)*w/c0(1);     %the rate of tidal damping
    v(1)=eta(1)*c0(1)*rs(1)*mu(1)/h(1);    %the real scale of velocity
    c(1)=c0(1)/lambda(1);
    %
    for i=1:length(x)-1
           eta(i+1)=eta(i)+Eta_Dx(i)*dx; %Integration of the damping number
           zeta(i+1)=eta(i+1)/h(i+1); % the tidal amplitude-to-depth ratio
           f(i+1)=g/(Ks(i+1)^2*h(i+1)^(1/3))/(1-(1.33*zeta(i+1))^2);
           chi(i+1)=rs(i+1)*f(i+1)*c0(i+1)*zeta(i+1)/(w*h(i+1));
           [mu(i+1),delta(i+1),lambda(i+1),epsilon(i+1)]=f_new_2012(gamma(i+1),chi(i+1));     
           Eta_Dx(i+1)=delta(i+1)*eta(i+1)*w/c0(i+1); % the rate of tidal damping
           v(i+1)=eta(i+1)*c0(i+1)*rs(i+1)*mu(i+1)/h(i+1); % the real scale of velocity
           c(i+1)=c0(i+1)/lambda(i+1);
    end
    %
    %influence of river discharge on tidal damping
    mu_old=mu;
    lambda_old=lambda;
    delta_old=delta;
    % epsilon_old=epsilon;
    %
    mu_Qf=mu;
    lambda_Qf=lambda;
    delta_Qf=delta;
    epsilon_Qf=epsilon;
    sum_error=1;
    kk=0;
    
w_message=['CST model calculations in progress. Error=' num2str(sum_error)];
hwait = waitbar(0,w_message,'Name','cst_model');
maxiter = 50;
while (sum_error>0.01 && kk<maxiter)
    kk=kk+1;
    eta_d(1)=eta0;
    zeta(1)=eta_d(1)/h(1); %the dimensionless amplitude
    %
    f(1)=(g/(Ks(1)^2*h(1)^(1/3)))/(1-(1.33*zeta(1))^2); % the dimensionless friction factor
    Xi(1)=(rs(1)*f(1)*c0(1)*eta_d(1))/(w*h(1)^2); % the friction number
    %********************modified solution*******************************
    alpha(1)=Qf(1)/(A(1)*v(1));
    x0=[mu_Qf(1), delta_Qf(1), lambda_Qf(1)]';
    uf_v(1)=Qf(1)/(A(1)*v(1));
    if(uf_v(1)==0)
        L0(1)=0;L1(1)=16/(3*pi);
    elseif(uf_v(1)<=1)
        ga=acos(-uf_v(1));
        L0(1)=(2+cos(2*ga))*(2-4*ga/pi)+6*sin(2*ga)/pi;
        L1(1)=6*sin(ga)/pi+2*sin(3*ga)/(3*pi)+(4-8*ga/pi)*cos(ga);
    else
        L0(1)=-2-4*uf_v(1)^2;
        L1(1)=4*uf_v(1);
    end
    if(alpha(1)<=(mu_Qf(1)*lambda_Qf(1)))
        [y,~]=findzero_new_discharge_tide(gamma(1), Xi(1), rs(1),alpha(1),zeta(1),x0);
    else
        [y,~]=findzero_new_discharge_river(gamma(1), Xi(1), rs(1),alpha(1),zeta(1),x0);
    end
    mu_Qf(1)=y(1);
    delta_Qf(1)=y(2);
    lambda_Qf(1)=y(3);
    epsilon_Qf(1)=atan(y(3)/(gamma(1)-y(2)));
    v_Qf(1)=eta_d(1)*c0(1)*rs(1)*mu_Qf(1)/h(1); % the real scale of velocity
    phi(1)=vdis(1)/(v_Qf(1)*sin(epsilon_Qf(1))); % the ratio between river and tide
    Eta_Dxf(1)=delta_Qf(1)*eta_d(1)*w/c0(1);
    c_Qf(1)=c0(1)/lambda_Qf(1);
    if(v_Qf(1)*sin(epsilon_Qf(1))>vdis(1))
        Fs1(1)=1/3*(v_Qf(1)*sin(epsilon_Qf(1))-vdis(1))^2*(1/(Ks(1)^2*(h(1)+eta_d(1))^(4/3)));
    else
        Fs1(1)=-1/3*(v_Qf(1)*sin(epsilon_Qf(1))-vdis(1))^2*(1/(Ks(1)^2*(h(1)+eta_d(1))^(4/3)));
    end
    Fs(1)=Fs1(1)-1/3*(-v_Qf(1)*sin(epsilon_Qf(1))-vdis(1))^2*(1/(Ks(1)^2*(h(1)-eta_d(1))^(4/3)));
    Fl(1)=1/6*(L0(1)*v_Qf(1)^2/4+L1(1)*v_Qf(1)*v_Qf(1)*sin(epsilon_Qf(1))/2)*(1/(Ks(1)^2*(h(1)+eta_d(1))^(4/3)));
    Fl(1)=Fl(1)+1/6*(L0(1)*v_Qf(1)^2/4-L1(1)*v_Qf(1)*v_Qf(1)*sin(epsilon_Qf(1))/2)*(1/(Ks(1)^2*(h(1)-eta_d(1))^(4/3)));
    f_av(1)=Fs(1)+Fl(1);
    h_Qf(1)=h0(1);
%     zws(1)=0;
    c0_Qf(1)=sqrt(g*h_Qf(1)/rs(1));
    gamma_Qf(1)=c0_Qf(1)*(Bo-Br)*exp(-x(1)/Lb)/(Lb*w*(Br+(Bo-Br)*exp(-x(1)/Lb)));
    A_Qf(1)=B(1)*h_Qf(1);
    vdis_Qf(1)=Qf(1)/A_Qf(1);
    %****************start to loop*********************************************
    for i=1:length(x)-1
        eta_d(i+1)=eta_d(i)+Eta_Dxf(i)*dx; %Integration of the damping number
        zeta(i+1)=eta_d(i+1)/h(i+1); %the dimensionless amplitude
        %*********************************
        f(i+1)=(g/(Ks(i+1)^2*h(i+1)^(1/3)))/(1-(1.33*zeta(i+1))^2); % the dimensionless friction factor
        Xi(i+1)=(rs(i+1)*f(i+1)*c0(i+1)*eta_d(i+1))/(w*h(i+1)^2); % the friction number
        alpha(i+1)=Qf(i+1)/(A(i+1)*v(i+1));
        x0=[mu_Qf(i+1), delta_Qf(i+1), lambda_Qf(i+1)]';
        uf_v(i+1)=Qf(i+1)/(A(i+1)*v(i+1));
        if(uf_v(i+1)==0)
            L0(i+1)=0;L1(i+1)=16/(3*pi);
        elseif(uf_v(i+1)<=1)
            ga=acos(-uf_v(i+1));
            L0(i+1)=(2+cos(2*ga))*(2-4*ga/pi)+6*sin(2*ga)/pi;
            L1(i+1)=6*sin(ga)/pi+2*sin(3*ga)/(3*pi)+(4-8*ga/pi)*cos(ga);
        else
            L0(i+1)=-2-4*uf_v(i+1)^2;
            L1(i+1)=4*uf_v(i+1);
        end
        if(alpha(i+1)<=(mu_Qf(i+1)*lambda_Qf(i+1)))
            [y,~]=findzero_new_discharge_tide(gamma(i+1), Xi(i+1), rs(i+1),alpha(i+1),zeta(i+1),x0);
        else
            [y,~]=findzero_new_discharge_river(gamma(i+1), Xi(i+1), rs(i+1),alpha(i+1),zeta(i+1),x0);
        end
        mu_Qf(i+1)=y(1);
        delta_Qf(i+1)=y(2);
        lambda_Qf(i+1)=y(3);
        epsilon_Qf(i+1)=atan(y(3)/(gamma(i+1)-y(2)));
        v_Qf(i+1)=eta_d(i+1)*c0(i+1)*rs(i+1)*mu_Qf(i+1)/h(i+1); % the real scale of velocity
        phi(i+1)=vdis(i+1)/(v_Qf(i+1)*sin(epsilon_Qf(i+1))); % the ratio between river and tide
        Eta_Dxf(i+1)=delta_Qf(i+1)*eta_d(i+1)*w/c0(i+1);
        c_Qf(i+1)=c0(i+1)/lambda_Qf(i+1);
        %*************************************************************************
        if((v_Qf(i+1)*sin(epsilon_Qf(i+1)))>=vdis(i+1))
            Fs1(i+1)=2/3*((v_Qf(i+1)*sin(epsilon_Qf(i+1))-vdis(i+1))^2*(1/(Ks(i+1)^2*(h(i+1)+eta_d(i+1))^(4/3))));
        else
            Fs1(i+1)=-2/3*((v_Qf(i+1)*sin(epsilon_Qf(i+1))-vdis(i+1))^2*(1/(Ks(i+1)^2*(h(i+1)+eta_d(i+1))^(4/3))));
        end
        Fs(i+1)=Fs1(i+1)-2/3*((v_Qf(i+1)*sin(epsilon_Qf(i+1))+vdis(i+1))^2*(1/(Ks(i+1)^2*(h(i+1)-eta_d(i+1))^(4/3))));
        Fl(i+1)=1/3*((L0(i+1)*v_Qf(i+1)^2/4+L1(i+1)*v_Qf(i+1)*v_Qf(i+1)*sin(epsilon_Qf(i+1))/2)*(1/(Ks(i+1)^2*(h(i+1)+eta_d(i+1))^(4/3))));
        Fl(i+1)=Fl(i+1)+1/3*((L0(i+1)*v_Qf(i+1)^2/4-L1(i+1)*v_Qf(i+1)*v_Qf(i+1)*sin(epsilon_Qf(i+1))/2)*(1/(Ks(i+1)^2*(h(i+1)-eta_d(i+1))^(4/3))));
        f_av(i+1)=1/2*(Fs(i+1)+Fl(i+1));
        h_Qf(i+1)=-sum(f_av(1:i).*dx)+h0(i+1);
        zwx(i+1)=-sum(f_av(1:i).*dx);
        c0_Qf(i+1)=sqrt(g*h_Qf(i+1)/rs(i+1));
        gamma_Qf(i+1)=c0_Qf(i+1)*(Bo-Br)*exp(-x(i+1)/Lb)/(Lb*w*(Br+(Bo-Br)*exp(-x(i+1)/Lb)));
        A_Qf(i+1)=B(i+1)*h_Qf(i+1);
        vdis_Qf(i+1)=Qf(i+1)/A_Qf(i+1);
    end
    gamma_z=c0_Qf./w.*gradient(h_Qf,dx)./h_Qf;
    %output error to command window if required (mainly for debugging)
    sum_error=sum(abs(lambda_old-lambda_Qf)+abs(mu_old-mu_Qf)+abs(delta_old-delta_Qf));
    lambda_old=lambda_Qf;
    mu_old=mu_Qf;
    delta_old=delta_Qf;
    v=sqrt(v_Qf./v).*v_Qf;
    h=sqrt(h_Qf./h).*h_Qf;
    c0=sqrt(c0_Qf./c0).*c0_Qf;
    gamma=gamma_Qf-gamma_z;
    A=A_Qf;
    vdis=vdis_Qf;
    if(sum_error<0.01)
%         kk2=kk; %number of iteration to satisfy tolerance
        %disp(['Number of iteration to satisfy tolerance ',num2str(kk2)])
        break
    end
    w_message=['CST model calculations in progress. Error=' num2str(sum_error, '% 7.3f')];
    waitbar(kk/50,hwait,w_message)
end

close(hwait)
if kk==maxiter
   fprintf('Number of iterations exceeds %d. No solution found\n',maxiter)
   return;
end
%--------------------------------------------------------------------------
%% assign output
%--------------------------------------------------------------------------
    ax = eta_d;
    Ux = v_Qf;
    kx = 2*pi()./(c*T);
    eA = epsilon_Qf;
    % %              Not Currently Used in CST or ChannelForm models

    ht(:,:) = diag(ax)*cos(w*ti-diag(kx)*xi);
    utt(:,:) = -diag(Ux)*sin(w*ti-diag(kx)*xi-diag(eA)*ones(size(ht)));
    % intertidal slope based on storage width ratio
    Bint = 2*B.*(rs-1)./(rs+1);  %assumes 2 shores (see check in Book 7)
    msx = Bint./ax'/4;           %Bint=2I and msx=I/(2a)=Bint/(4a)

    % river flow velocity
    urx = -vdis_Qf';             %river flow velocity along estuary

    I = ones(size(ht));
    At = diag(A')*I+ht.*(diag(B)*I+diag(msx)*ht); %area over tidal cycle
    urt = diag(urx.*A')*I./At;   %river velocity scaled for tidal elevation
    ust = utt.^2./(diag(c)*I);   %Stokes drift velocity as a function of x and t
    usx = Ux.^2/2./c0;           %estimate of the tidal_av Stoke's drift velocity

    ut0 = utt;
    ust0 = ust;
    diff = 10;
    while any(diff>0.0001)
        ust = utt.^2./(diag(c)*I);
        utt = ut0-ust;
        diff = abs(ust0-ust);
        ust0 = ust;
    end

    %Results in format for ModelUI (function of X only)
    xdim{1} = x;
    time{1} = t;
    % 
    resX{1} = zwx'+zw0;   %mean water suface elevation along estuary
    resX{2} = ax';        %elevation amplitude along estuary
    resX{3} = Ux';        %tidal velocity amplitude along estuary            
    resX{4} = urx;        %river flow velocity along estuary
    resX{5} = h_Qf';      %hydraulic depth at mtl (m)   
    %
    resXT{1} = ht';       %tidal elevation over a tidal cycle
    resXT{2} = utt';      %tidal velocity over tidal cycle
    resXT{3} = urt';      %river velocity scaled for tidal elevation
    resXT{4} = ust';      %Stokes drift velocity as a function of x and t

    if rnp.isfull
        %variables in x
        resX{6} = eA';    %phase angle between elevation and velocity       
        resX{7} = Ax;     %cross-sectional area at mtl (m^2)
        resX{8} = B;      %width at mtl (m)
        resX{9} = msx;    %intertidal slope (1:m)
        resX{10} = A';    %effective hydrualic CSA (this is A_Qf above)
        resX{11} = usx';  %estimate of Stokes drift over tidal cycle 
    end
end
%%
function outVar = interpChannelVar(inVar,xsw,Le,x)
    %interpolate the variation of along channel properties based on the
    %type of input provided
    nVar = length(inVar); 
    nxsw = length(xsw);    
    if nVar==nxsw+2   %number of intervals correctly defined
        outVar = interp1([0 xsw Le],inVar,x,'linear');
    elseif nVar>1 && nVar~=length(x)
        warndlg('Incorrect definition of Manning coefficient')
        outVar = [];
        return;
    elseif nVar==1    %single value specified
        outVar = ones(size(x))*inVar;
    else             %values for all x specified
        outVar = inVar;
    end       
end
%%
function newVar = fitChannelVar(xin,Var,x,Vmouth,Vhead)
    %interpolate the observed data after checking that data spans channel
    if min(xin)>0
        Var = [Vmouth,Var];
        xin = [0;xin];
    end

    if max(xin)<x(end)
        Var = [Var,Vhead];
        xin = [xin;x(end)];
    end
    
    newVar = interp1(xin,Var,x,'pchip');

    newVar = smoothdata(newVar);
end
    
    