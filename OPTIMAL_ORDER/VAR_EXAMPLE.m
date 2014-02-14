
%% Load the data and apply transformations:
load Data_USEconmodel
DEF = log(Dataset.CPIAUCSL);
GDP = log(Dataset.GDP);
rGDP = diff(GDP - DEF); % Real GDP is GDP - deflation
TB3 = 0.01*Dataset.TB3MS;
dDEF = 4*diff(DEF); % Scaling
rTB3 = TB3(2:end) - dDEF; % Real interest is deflated
Y = [rGDP,rTB3];

%% Fit a VAR(4) model specification:
Spec = vgxset('n',2,'nAR',4,'Constant',true);
impSpec = vgxvarx(Spec,Y(5:end,:),[],Y(1:4,:));
impSpec = vgxset(impSpec,'Series',...
  {'Transformed real GDP','Transformed real 3-mo T-bill rate'});

%% Predict the evolution of the time series:
FDates = datenum({'30-Jun-2009'; '30-Sep-2009'; '31-Dec-2009';
'31-Mar-2010'; '30-Jun-2010'; '30-Sep-2010'; '31-Dec-2010';
'31-Mar-2011'; '30-Jun-2011'; '30-Sep-2011'; '31-Dec-2011';
'31-Mar-2012'; '30-Jun-2012'; '30-Sep-2012'; '31-Dec-2012';
'31-Mar-2013'; '30-Jun-2013'; '30-Sep-2013'; '31-Dec-2013';
'31-Mar-2014'; '30-Jun-2014' });
FT = numel(FDates);
[Forecast,ForecastCov] = vgxpred(impSpec,FT,[],...
    Y(end-3:end,:));
%% Plot the forecast:
vgxplot(impSpec,Y(end-10:end,:),Forecast,ForecastCov);

%% Data loading
load Data_USEconModel
GDP = Dataset.GDP;
M1 = Dataset.M1SL;
TB3 = Dataset.TB3MS;
Y = [GDP,M1,TB3];

%% Data visualization
subplot(3,1,1)
plot(dates,Y(:,1),'r');
title('GDP')
datetick('x'), grid('on')
hold('on')
subplot(3,1,2);
plot(dates,Y(:,2),'b');
title('M1')
datetick('x'), grid('on')
subplot(3,1,3);
plot(dates, Y(:,3), 'k')
title('3-mo T-bill')
datetick('x'), grid('on')
hold('off')

%% Plotting differenced data
Y = [diff(log(Y(:,1:2))), Y(2:end,3)]; % Transformed data
X = dates(2:end);

subplot(3,1,1)
plot(X,Y(:,1),'r');
title('GDP')
datetick('x'),grid('on')
hold('on')
subplot(3,1,2);
plot(X,Y(:,2),'b');
title('M1')
datetick('x'),grid('on')
subplot(3,1,3);
plot(X, Y(:,3),'k'),
title('3-mo T-bill')
datetick('x'),grid('on')
hold('off')

Y(:,1:2) = 100*Y(:,1:2);
figure
plot(X,Y(:,1),'r');hold('on')
plot(X,Y(:,2),'b'); datetick('x'), grid('on')
plot(X,Y(:,3),'k');
legend('GDP','M1','3-mo T-bill'); hold('off')

%% Differencing the data
load Data_USEconModel
GDP = Dataset.GDP;
M1 = Dataset.M1SL;
TB3 = Dataset.TB3MS;

dGDP = 100*diff(log(GDP(49:end)));
dM1 = 100*diff(log(M1(49:end)));
dT3 = diff(TB3(49:end));
Y = [dGDP dM1 dT3];

dt = logical(eye(3));
VAR2diag = vgxset('ARsolve',repmat({dt},2,1),...
    'asolve',true(3,1),'Series',{'GDP','M1','3-mo T-bill'});
VAR2full = vgxset(VAR2diag,'ARsolve',[]);
VAR4diag = vgxset(VAR2diag,'nAR',4,'ARsolve',repmat({dt},4,1));
VAR4full = vgxset(VAR2full,'nAR',4);

Ypre = Y(1:4,:);
T = ceil(.9*size(Y,1));
Yest = Y(5:T,:);
YF = Y((T+1):end,:);
TF = size(YF,1);

[EstSpec1,EstStdErrors1,LLF1,W1] = ...
    vgxvarx(VAR2diag,Yest,[],Ypre,'CovarType','Diagonal');
[EstSpec2,EstStdErrors2,LLF2,W2] = ...
    vgxvarx(VAR2full,Yest,[],Ypre);
[EstSpec3,EstStdErrors3,LLF3,W3] = ...
    vgxvarx(VAR4diag,Yest,[],Ypre,'CovarType','Diagonal');
[EstSpec4,EstStdErrors4,LLF4,W4] = ...
    vgxvarx(VAR4full,Yest,[],Ypre);

[isStable1,isInvertible1] = vgxqual(EstSpec1);
[isStable2,isInvertible2] = vgxqual(EstSpec2);
[isStable3,isInvertible3] = vgxqual(EstSpec3);
[isStable4,isInvertible4] = vgxqual(EstSpec4);
[isStable1,isStable2,isStable3,isStable4]

[n1,n1p] = vgxcount(EstSpec1);
[n2,n2p] = vgxcount(EstSpec2);
[n3,n3p] = vgxcount(EstSpec3);
[n4,n4p] = vgxcount(EstSpec4);

reject1 = lratiotest(LLF2,LLF1,n2p - n1p)

reject3 = lratiotest(LLF4,LLF3,n4p - n3p)

reject4 = lratiotest(LLF4,LLF2,n4p - n2p)

AIC = aicbic([LLF1 LLF2 LLF3 LLF4],[n1p n2p n3p n4p])
[FY1,FYCov1] = vgxpred(EstSpec1,TF,[],Yest);
[FY2,FYCov2] = vgxpred(EstSpec2,TF,[],Yest);
[FY3,FYCov3] = vgxpred(EstSpec3,TF,[],Yest);
[FY4,FYCov4] = vgxpred(EstSpec4,TF,[],Yest);

vgxplot(EstSpec2,Yest,FY2,FYCov2)

error1 = YF - FY1;
error2 = YF - FY2;
error3 = YF - FY3;
error4 = YF - FY4;

SSerror1 = error1(:)' * error1(:);
SSerror2 = error2(:)' * error2(:);
SSerror3 = error3(:)' * error3(:);
SSerror4 = error4(:)' * error4(:);
figure
bar([SSerror1 SSerror2 SSerror3 SSerror4],.5)
ylabel('Sum of squared errors')
set(gca,'XTickLabel',...
    {'AR2 diag' 'AR2 full' 'AR4 diag' 'AR4 full'})
title('Sum of Squared Forecast Errors')

vgxdisp(EstSpec2)


[ypred,ycov] = vgxpred(EstSpec2,10,[],YF);

yfirst = [GDP,M1,TB3]; % the original data
yfirst = yfirst(49:end,:); % NaN values removed
dates = dates(49:end);
endpt = yfirst(end,:); % the last time in the series
endpt(1:2) = log(endpt(1:2)); % convert to log for cumsum
ypred(:,1:2) = ypred(:,1:2)/100; % was multiplied by 100
ypred = [endpt; ypred]; % add final data point to beginning
ypred(:,1:3) = cumsum(ypred(:,1:3)); % reason for adding endpt
ypred(:,1:2) = exp(ypred(:,1:2)); % undoing the logarithm
lastime = dates(end);
timess = lastime:91:lastime+910; % extending the times

subplot(3,1,1)
plot(timess,ypred(:,1),':r')
hold on
plot(dates,yfirst(:,1),'k'),datetick('x'), grid('on')
title('GDP')
subplot(3,1,2);
plot(timess,ypred(:,2),':r')
hold on
plot(dates,yfirst(:,2),'k'),datetick('x'), grid('on')
title('M1')
subplot(3,1,3);
plot(timess,ypred(:,3),':r')
hold on
plot(dates,yfirst(:,3),'k'),datetick('x'), grid('on')
title('3-mo T-bill')

ylast = yfirst(170:end,:);
timeslast = dates(170:end);

subplot(3,1,1)
plot(timess,ypred(:,1),'--r')
hold on
plot(timeslast,ylast(:,1),'k'),datetick('x'), grid('on')
title('GDP')
subplot(3,1,2);
plot(timess,ypred(:,2),'--r')
hold on
plot(timeslast,ylast(:,2),'k'),datetick('x'), grid('on')
title('M1')
subplot(3,1,3);
plot(timess,ypred(:,3),'--r')
hold on
plot(timeslast,ylast(:,3),'k'),datetick('x'), grid('on')
title('3-mo T-bill')

ysim = vgxsim(EstSpec2,10,[],YF,[],2000);
yfirst = [GDP,M1,TB3]; % the original data
endpt = yfirst(end,:); % the last time in the series
endpt(1:2) = log(endpt(1:2)); % convert to log for cumsum
ysim(:,1:2,:) = ysim(:,1:2,:)/100; % undo the *100
ysim = [repmat(endpt,[1,1,2000]);ysim]; % insert endpt first
ysim(:,1:3,:) = cumsum(ysim(:,1:3,:)); % undo diff
ysim(:,1:2,:) = exp(ysim(:,1:2,:)); % undo log

ymean = mean(ysim,3);
ystd = std(ysim,0,3);
subplot(3,1,1)
plot(timess,ymean(:,1),'k'),datetick('x'), grid('on')
hold on
plot(timess,ymean(:,1)+ystd(:,1),'--r')
plot(timess,ymean(:,1)-ystd(:,1),'--r')
title('GDP')
subplot(3,1,2);
plot(timess,ymean(:,2),'k'),datetick('x'), grid('on')
hold on
plot(timess,ymean(:,2)+ystd(:,2),'--r')
plot(timess,ymean(:,2)-ystd(:,2),'--r')
title('M1')
subplot(3,1,3);
plot(timess,ymean(:,3),'k'),datetick('x'), grid('on')
hold on
plot(timess,ymean(:,3)+ystd(:,3),'--r')
plot(timess,ymean(:,3)-ystd(:,3),'--r')
title('3-mo T-bill')