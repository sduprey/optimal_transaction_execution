function temp_impact=simple_temporary_impact(epsilon,eta, tau, average_trading_rate)
temp_impact=epsilon.*tau.*sign(average_trading_rate)+eta.*average_trading_rate;
end

