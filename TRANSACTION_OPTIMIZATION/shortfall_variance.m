function sh_var=shortfall_variance(sigma, tau, x)
sh_var=sigma^2.*tau.* sum(x(2:end).*x(2:end));
end

