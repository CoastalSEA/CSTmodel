function [x,iter,err_mess]=newtonm(x0,f,J)
N=300;
epsilon=1e-10;
maxval=1000.0;
xx=x0;
fx=feval(f,xx);
fx0=norm(fx);
err_mess=0;
rho=0.5;
sigma=0.0001;
while(N>0)
    JJ=feval(J,xx);
    %NB: the 'all'input variable was added in 2018
    if any(isnan(JJ),'all') || any(isinf(JJ),'all')
        error('Newton-Jacobian matrix contains Inf or NaN');
    end
    if abs(det(JJ))<epsilon || isinf(cond(JJ))
        error('Newton-Jacobian is singular-try new x0');
    end
    dx=JJ\(-fx);
    alpha=1;
    for kk=1:100
        alpha = rho*alpha; % damping parameter is adjusted
        dx=alpha*dx;
        xn=xx+dx;
        fx=feval(f,xn);
        fxn=norm(fx);
        if fxn<fx0+sigma*alpha*feval(f,xx).*dx, break; end
    end
    if abs(feval(f,xn))<epsilon | norm(dx)< 1e-10 %#ok<OR2>
        x=xn;
        iter=300-N;
       return;
    end
    fx0=fxn;
    if abs(feval(f,xx))>maxval
        iter=300-N;
        disp(['iterations = ',num2str(iter)]);
        error('Solution diverges');
        abort;
    end
    N=N-1;
    xx=xn;
end
err_mess=1;
x=xn;
iter=300;
%error('No Convergence after 300 iterations.');
%abort;
