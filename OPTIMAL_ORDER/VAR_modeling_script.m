%% Loading preprocessed time series
clear all;close all;clc;
load('preprocessed_time_series.mat');
nb_variables=8;
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
b = reg.coeff(2:nb_variables);
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
B1 = P(:,2:9);
B2 = P(:,10:17);
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
P0 = perms(1:nb_variables);
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
    bi = reg.coeff(2:nb_variables);
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
c0=mles.r7.paramVals.c0;
B=mles.r7.paramVals.B;
A=mles.r7.paramVals.A;
B1=mles.r7.paramVals.B1;
B2=mles.r7.paramVals.B2;
C=A*B';
VEC = {eye(nb_variables) B1 B2};
VAR=vectovar(VEC,C);
a=A*c0;
armodel = vgxset('a',a,'AR',VAR(2:end),'Q',mles.r7.EstCov);
vgxdisp(armodel);

%% Impulse Response Analysis
% An impulse response analysis provides a
% _ceteris paribus_ sensitivity analysis of the dynamics of a system.
% The following plot shows the
% projected dynamic responses of each time series along each column in reaction to a 1 standard
% deviation impulse along each row. The units for each plot are percentage deviations from the
% initial state for each time series.
% Last order book observation :
% [220.640000000000 100 220.510000000000 249 220.650000000000 1290 220.500000000000 71 220.670000000000 170 220.480000000000 700 220.710000000000 1800 220.470000000000 100 220.740000000000 800 220.460000000000 1704 220.750000000000 100 220.450000000000 200 220.760000000000 100 220.440000000000 800 220.790000000000 2300 220.430000000000 2300 220.800000000000 3100 220.420000000000 100 220.810000000000 1700 220.410000000000 3300]
% and the log matching observation Y(end,:)
% [5.39653241404499 5.39594304533248 4.60517018598809 5.51745289646471 7.16239749735572 4.26267987704132 5.13579843705026 6.55108033504340]
% log best ask price : ln(220.64)
% log best bid price : ln(220.51)
% log best ask volume : ln(100)
% log best bid volume : ln(249)
% log second depth ask volume : ln(1290)
% log second depth bid volume : ln(71)
% log third depth ask volume : ln(170)
% log third depth bid volume : ln(700)
% [ln(220.64),ln(220.51),ln(100),ln(249),ln(1290),ln(71),ln(170),ln(700)]
variable_names={'log ask 1',...
    'log bid 1',...
    'log ask 1 vol',...
    'log bid 1 vol',...
    'log ask 2 vol',...
    'log bid 2 vol',...
    'log ask 3 vol',...
    'log bid 3 vol'};
% predicting time (for the next 2000 order event)
Fw=2000;

%% First scenario : normal limit order
% arrival of a buy limit order with price 220.51 (current best bid) and
% size 125 (half the current size 249) to be placed at the market.
% this order will be consolidated at the best bid without changing the prevailing quotes.
% Because the initial depth on the first level is 250, the log depth becomes ln(375) .
% v = [0,0,0,log(375)-log(249),0,0,0,0]';
W0 = zeros(Fw, nb_variables);
WX = zeros(Fw, nb_variables);
WX(1,:)=[0,0,0,(log(375)-log(249)),0,0,0,0]';
YX = 100*(vgxproc(armodel, WX, [], Y) - vgxproc(armodel, W0, [], Y));
for i = 1:nb_variables
    subplot(nb_variables,1,i);
    plot(YX(:,i));
    ylabel(['\bf ' variable_names{i}]);
    if (i==nb_variables)
        xlabel('Business event time ')
    end
    if (i==1)
        title('Normal limit order responses ')
    end
end

%% Second scenario : aggressive limit order
% arrival of a buy limit order with price 220.5321
% and size 150 improving the best bid and changing all depth levels on the bid side of the
% order book
% and size 0.5 to be posted inside of the current spread. Figure 3 shows that it improves
% the best bid by 0.1% and accordingly shifts all depth levels on the bid side.
% The resulting shock vector is given by 
% [ln(220.64),ln(220.51),ln(100),ln(249),ln(1290),ln(71),ln(170),ln(700)]
% v=[0,log(220.5321)-log(220.51),0,(log(125)-log(249)),0,log(249)-log(71),0,log(71)-log(700)]';
W0 = zeros(Fw, nb_variables);
WX = zeros(Fw, nb_variables);
WX(1,:)=[0,log(220.5321)-log(220.51),0,(log(125)-log(249)),0,log(249)-log(71),0,log(71)-log(700)]';
YX_agr = 100*(vgxproc(armodel, WX, [], Y) - vgxproc(armodel, W0, [], Y));
for i = 1:nb_variables
    subplot(nb_variables,1,i);
    plot(YX_agr(:,i));
    ylabel(['\bf ' variable_names{i}]);
    if (i==nb_variables)
        xlabel('Business event time ')
    end
    if (i==1)
        title('Agressive limit order responses ')
    end
end

%% Third scenario : normal market order
% arrival of a buy market order with  size
% 50. This order will be immediately executed against standing limit orders at
% the best ask quote. Because it absorbs liquidity from the book, it shocks the
% corresponding depth levels negatively. The corresponding changes
% of the order book are represented by
% [ln(220.64),ln(220.51),ln(100),ln(249),ln(1290),ln(71),ln(170),ln(700)]
% v = [0,0,(log(50)-log(100)),0,0,0,0,0]';
W0 = zeros(Fw, nb_variables);
WX = zeros(Fw, nb_variables);
WX(1,:)=[0, 0, (log(50)-log(100)), 0, 0,0,0,0]';
YX_mark = 100*(vgxproc(armodel, WX, [], Y) - vgxproc(armodel, W0, [], Y));
for i = 1:nb_variables
    subplot(nb_variables,1,i);
    plot(YX_mark(:,i));
    ylabel(['\bf ' variable_names{i}]);
    if (i==nb_variables)
        xlabel('Business event time ')
    end
    if (i==1)
        title('Normal market order responses ')
    end
end

%% Plotting together the 3 scenarii
% Best ask price
figure
plot(YX(:,1));
hold all
plot(YX_agr(:,1));
plot(YX_mark(:,1));
legend({'Normal limit order','Agressive limit order','Normal market order'})
xlabel('Business event time ');
ylabel('Best log ask');
% Best bid price
figure
plot(YX(:,2));
hold all
plot(YX_agr(:,2));
plot(YX_mark(:,2));
legend({'Normal limit order','Agressive limit order','Normal market order'})
xlabel('Business event time ');
ylabel('Best log bid');