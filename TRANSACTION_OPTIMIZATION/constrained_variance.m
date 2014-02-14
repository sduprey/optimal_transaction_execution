function [c,ceq]=constrained_variance(sigma,tau,targeted_variance,x)
c=shortfall_variance(sigma, tau, x)-targeted_variance;
ceq=[];
end


