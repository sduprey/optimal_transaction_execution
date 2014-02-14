%% Loading preprocessed time series
clear all;close all;clc;
load('preprocessed_time_series.mat');

%% Engel Granger cointegrating test
% now the turning point : the differenced series is now stationary
% but if there is cointegration between the integrated series, modeling
% it as an ARIMA is a misspecification,
% which brings poor forecasts, value at risk and so on
% Differencing removes the levels information and cointegration
% lies in the model
% So here be cautious and do some more tests to see if the series
% are cointegrated
% first : the Engle-Granger test
% we regress one arbitrarily chosen coordinate against the others
% Y(:,1)=Y(:,2:end)*b+X*a+e
% and we test the residuals for the presence of a unit root
[h,pValue,stat,cValue] = egcitest(Y,'test',{'t1','t2'})
[~,~,~,~,reg] = egcitest(Y,'test','t2');
% Visualizing the cointegrating relation
% We get the cointegrating vector from the Engle-Granger test
c0 = reg.coeff(1);
b = reg.coeff(2:10);
figure;
plot(timestamps/(60.*60),Y*[1;-b]-c0,'LineWidth',2)
title('{\bf Cointegrating Relation : the bid/ask spread !}')
axis tight
grid on

%% VEC coefficient estimation through ordinary least squares
% once the cointegrating relation has been established, we can
% build a Vector Error Correction Model (or a cointegrated VAR model)
q = 2;
[numObs,numDims] = size(Y);
tBase = (q+2):numObs; % Commensurate time base, all lags
T = length(tBase); % Effective sample size
YLags = lagmatrix(Y,0:(q+1)); % Y(t-k) on observed time base
LY = YLags(tBase,(numDims+1):2*numDims);
% Y(t-1) on commensurate time base

% Form multidimensional differences so that
% the kth numDims-wide block of
% columns in DelatYLags contains (1-L)Y(t-k+1):

DeltaYLags = zeros(T,(q+1)*numDims);
for k = 1:(q+1)
    DeltaYLags(:,((k-1)*numDims+1):k*numDims) = ...
        YLags(tBase,((k-1)*numDims+1):k*numDims) ...
        - YLags(tBase,(k*numDims+1):(k+1)*numDims);
end

DY = DeltaYLags(:,1:numDims); % (1-L)Y(t)
DLY = DeltaYLags(:,(numDims+1):end); % [(1-L)Y(t-1),...,(1-L)Y(t-q)]

% Perform the regression:
X = [(LY*[1;-b]-c0),DLY,ones(T,1)];
P = (X\DY)'; % [a,B1,...,Bq,c1]
a = P(:,1);
B1 = P(:,2:11);
B2 = P(:,12:21);
c1 = P(:,end);

% Display model coefficients
a,b,c0,B1,B2,c1

% Residual computation of the ordinary least square computation
% we compute the residuals to estimate the covariance matrix
% for a Monte-Carlo simulation
res = DY-X*P';
EstCov = cov(res);

%% Limitations of Engle Granger tests
% The procedure of the Engle-Granger has a lot of drawbacks
% first of all : we detect just one cointegrating relation
% at a time and this arbitrarily following the chosen variable to
% be regressed for
% The test is then in two phases : an ordinary least-square regression
% and an augmented Dickey-Fueller unit root test
% (the unit root test is not on an observed serie but on an estimated serie,
% and a proper distribution for the test must be used (z and tau statistics)).
% And once the test is done and positive, you still have to estimate the
% VEC model coefficients : a third step
P0 = perms([1 2 3 4 5 6 7 8 9 10]);
[~,idx] = unique(P0(:,1)); % Rows of P0 with unique regressand y1
P = P0(idx,:); % Unique regressions
numPerms = size(P,1);
% Preallocate:
T0 = size(Y,1);
H = zeros(1,numPerms);
PVal = zeros(1,numPerms);
CIR = zeros(T0,numPerms);
% Run all tests:
for i = 1:numPerms
    YPerm = Y(:,P(i,:));
    [h,pValue,~,~,reg] = egcitest(YPerm,'test','t2');
    H(i) = h;
    PVal(i) = pValue;
    c0i = reg.coeff(1);
    bi = reg.coeff(2:10);
    CIR(:,i) = YPerm*[1;-bi]-c0i;
end
% Display the test results:
H,PVal
% Plot the cointegrating relations:
plot(timestamps/(60.*60),CIR,'LineWidth',2)
title('{\bf Multiple Cointegrating Relations}')
legend(strcat({'Cointegrating relation  '}, ...
    num2str((1:numPerms)')),'location','NW');
axis tight
grid on

%% Johansen test
% More a framework than a test
% results for different lags (rows) and different ranks (column)
 % results for VEC(2) parameters estimation
[~,~,~,~,mles] = jcitest(Y,'model','H1*','lags',2);
c0=mles.r9.paramVals.c0;
B=mles.r9.paramVals.B;
A=mles.r9.paramVals.A;
B1=mles.r9.paramVals.B1;
B2=mles.r9.paramVals.B2;
C=A*B';
VEC = {eye(10) B1 B2};
VAR=vectovar(VEC,C);
a=A*c0;
armodel = vgxset('a',a,'AR',VAR(2:end),'Q',mles.r9.EstCov);
vgxdisp(armodel);

%% Predicting
YF = Y(end,:); % starting values
Fw=2000;
Ysim = vgxsim(armodel,20,[],YF);
[Forecast,ForecastCov] = vgxpred(armodel,Fw,[],Y(end-3:end,:));
FYSigma = zeros(size(Forecast));
for t = 1:Fw
	FYSigma(t,:) = sqrt(diag(ForecastCov{t}))';
end
% Plot the forecast:
%vgxplot(armodel,Y(end-500:end,:),Forecast,ForecastCov);

%% Plotting results together
n=10;
Hw = 200000;
% number of historical business events to display                                
% number of forecast business events to display
figure;
for i = 1:n
	subplot(ceil(n/2),2,i,'align');
	plot(1:Hw,Y(end-Hw+1:end,i));
	hold all
	plot(Hw:(Hw+Fw),[Y(end,i); Forecast(:,i)],'b');
	%plot(Hw+1:(Hw+Fw),[Forecast(:,i) - FYSigma(:,i), Forecast(:,i) + FYSigma(:,i)],':r');
	hold off
end

%% Impulse Response Analysis
% An impulse response analysis provides a
% _ceteris paribus_ sensitivity analysis of the dynamics of a system. 
% The following plot shows the
% projected dynamic responses of each time series along each column in reaction to a 1 standard
% deviation impulse along each row. The units for each plot are percentage deviations from the
% initial state for each time series.

% Impulses = YAbbrev;
% Responses = YAbbrev;
W0 = zeros(Fw, n);

ii = 0;
for i = 1:n
	WX = W0;
	WX(1,i) = sqrt(mles.r9.EstCov(i,i));
	YX = 100*(vgxproc(armodel, WX, [], Y) - vgxproc(armodel, W0, [], Y));
	for j = 1:n
		ii = ii + 1;
		subplot(n,n,ii,'align');
		plot(YX(:,j));
		if i == 1
			%title(['\bf ' Responses{j}]);
		end
		if j == 1
			%ylabel(['\bf ' Impulses{i}]);
		end
		if i == n
			set(gca,'xtickmode','auto');
		else
			set(gca,'xtick',[]);
		end
	end
end
