function varargout = great_demo_gui(varargin)
% GREAT_DEMO_GUI MATLAB code for great_demo_gui.fig
%      GREAT_DEMO_GUI, by itself, creates a new GREAT_DEMO_GUI or raises the existing
%      singleton*.
%
%      H = GREAT_DEMO_GUI returns the handle to a new GREAT_DEMO_GUI or the handle to
%      the existing singleton*.
%
%      GREAT_DEMO_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GREAT_DEMO_GUI.M with the given input arguments.
%
%      GREAT_DEMO_GUI('Property','Value',...) creates a new GREAT_DEMO_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before great_demo_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to great_demo_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help great_demo_gui

% Last Modified by GUIDE v2.5 13-Jun-2013 15:28:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @great_demo_gui_OpeningFcn, ...
    'gui_OutputFcn',  @great_demo_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before great_demo_gui is made visible.
function great_demo_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to great_demo_gui (see VARARGIN)

% Choose default command line output for great_demo_gui
handles.output = hObject;
% number of time periods
N=str2double(get(handles.nb_periods,'String'));;
% time period length
% initial holding
X0=str2double(get(handles.initial_holding,'String'));

title(handles.axes,'Liquidation strategy','fontweight','b');
xlabel(handles.axes,'Trading periods','fontweight','b');
ylabel(handles.axes,'Stock amount','fontweight','b');

grid(handles.axes,'on');
set(handles.axes,'XLim',[1,N+1]);
set(handles.axes,'YLim',[0,X0]);
set(handles.axes,'XTick',1:N+1);
set(handles.axes,'YTick',0:X0./10:X0);
set(handles.axes,'XTickLabel',mat2cell(0:N,1,ones(N+1,1)));
set(handles.axes,'YTickLabel',mat2cell(0:X0./10:X0,1,ones(length(0:X0./10:X0),1)));
% Update handles structure

guidata(hObject, handles);

% UIWAIT makes great_demo_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = great_demo_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%set(hObject,'Position',[10 10 1000 750])
movegui(hObject,'center');

% --- Executes on button press in launch_analysis.
function launch_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to launch_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
T=str2double(get(handles.maturity,'String'));
% number of time periods
N=str2double(get(handles.nb_periods,'String'));;
% time period length
tau=T./N;
% daily volume 5 million shares $/share
gamma=str2double(get(handles.gamma,'String'));
% impact at 1 percent of market ($/share)/(share/day)
eta=str2double(get(handles.eta,'String'));
% bid ask spread $/share
epsilon=str2double(get(handles.epsilon,'String'));
% volatility of 30% annual
sigma=str2double(get(handles.sigma,'String'));
% initial holding
X0=str2double(get(handles.initial_holding,'String'));

%% Market impact modeling from high frequency data
permanent_impact=@(x)linear_permanent_impact(gamma,x);
temporary_impact=@(x)simple_temporary_impact(epsilon,eta,tau,x);

%% Minimal expected shortfall : minimizing the litigation risk
contents = cellstr(get(handles.console_output,'String'));
contents = {contents{:},'Computing the minimum expected shortfall'};
set(handles.console_output,'String',contents);
set(handles.console_output,'Value',length(contents));
drawnow;
obj =@(x) expected_shortfall(tau,permanent_impact,temporary_impact,x);
Aeq = [zeros(1,N+1);zeros(1,N+1)];
Aeq(1,1)=1;
Aeq(2,end)=1;
beq(1)=X0;
beq(2)=0;
x0 = zeros(N+1,1);
x0(1)=X0;
lb  = zeros(1,N+1);
ub = X0*ones(1, N+1);
%x=fmincon(obj,x0,[],[],Aeq,beq,lb,ub);
options = optimset('Algorithm','interior-point');
x=fmincon(obj,x0,[],[],Aeq,beq,lb,ub,[],options);

%% Expected shortfall when we sell steadily over time
% associated variance
max_trading_variance=shortfall_variance(sigma,tau,x);
min_exp_sh=expected_shortfall(tau,permanent_impact,temporary_impact,x);
handles.max_trading_variance = max_trading_variance;
handles.min_exp_sh = min_exp_sh;
contents = cellstr(get(handles.console_output,'String'));
contents = {contents{:},'Liquidation strategy minimizing volatility risk :'};
contents = {contents{:},num2str(x)};
contents = {contents{:},'Minimum expected shortfall'};
contents = {contents{:},num2str(min_exp_sh)};
set(handles.console_output,'String',contents);
set(handles.console_output,'Value',length(contents));
drawnow;

%% Minimum trading variance : minimizing the volatility risk
contents = cellstr(get(handles.console_output,'String'));
contents = {contents{:},'Computing the maximum expected shortfall'};
set(handles.console_output,'String',contents);
set(handles.console_output,'Value',length(contents));
drawnow;
obj =@(x) shortfall_variance(sigma, tau, x);
Aeq = [zeros(1,N+1);zeros(1,N+1)];
Aeq(1,1)=1;
Aeq(2,end)=1;
beq(1)=X0;
beq(2)=0;
x0 = zeros(N+1,1);
x0(1)=X0;
lb  = zeros(1,N+1);
ub = X0*ones(1, N+1);
%x=fmincon(obj,x0,[],[],Aeq,beq,lb,ub);
options = optimset('Algorithm','interior-point');
x=fmincon(obj,x0,[],[],Aeq,beq,lb,ub,[],options);
% Minimal expected shortfall
% trading everything at once

%% Expected shortfall when we sell everything at onc
min_trading_variance=shortfall_variance(sigma, tau, x);
max_exp_sh=expected_shortfall(tau,permanent_impact,temporary_impact,x);
handles.min_trading_variance = min_trading_variance;
handles.max_exp_sh = max_exp_sh;
contents = cellstr(get(handles.console_output,'String'));
contents = {contents{:},'Liquidation strategy maximizing volatility risk :'};
contents = {contents{:},num2str(x)};
contents = {contents{:},'Maximum expected shortfall'};
contents = {contents{:},num2str(max_exp_sh)};
set(handles.console_output,'String',contents);
set(handles.console_output,'Value',length(contents));
drawnow;
%% Building the efficient frontier
handles.numStrategies = 30;
targetedVarArray = linspace(min_trading_variance,max_trading_variance,handles.numStrategies);
liquidation_strategies = zeros(N+1,handles.numStrategies); % preallocating memory
for i=1:handles.numStrategies
    targeted_variance=targetedVarArray(i);
    contents = cellstr(get(handles.console_output,'String'));
    contents = {contents{:},['Liquidation strategy for a targeted volatility risk :' num2str(targeted_variance)]};
    contents = {contents{:},'Maximum expected shortfall'};
    contents = {contents{:},num2str(max_exp_sh)};
    set(handles.console_output,'String',contents);
    set(handles.console_output,'Value',length(contents));
    drawnow;
    obj =@(x) expected_shortfall(tau,permanent_impact,temporary_impact,x);
    nonlincon=@(x) constrained_variance(sigma,tau,targeted_variance,x);
    Aeq = [zeros(1,N+1);zeros(1,N+1)];
    Aeq(1,1)=1;
    Aeq(2,end)=1;
    beq(1)=X0;
    beq(2)=0;
    x0 = zeros(N+1,1);
    x0(1)=X0;
    options = optimset('Algorithm','interior-point');
    x=fmincon(obj,x0,[],[],Aeq,beq,[],[],nonlincon,options);
    % Minimal expected shortfall
    % constant trading over period
    liquidation_strategies(:,i)=x;
end
handles.liquidation_strategies = liquidation_strategies;
risk_mix = get(handles.turnover,'Value') ;
handles.strategy_to_draw = round(risk_mix*handles.numStrategies);
handles.liquidation_line = plot(handles.axes,handles.liquidation_strategies(:,handles.strategy_to_draw),...
    '--bs','LineWidth',2,'markersize',7);
grid(handles.axes,'on');
set(handles.axes,'XLim',[1,N+1]);
set(handles.axes,'YLim',[0,X0]);
set(handles.axes,'XTick',1:N+1);
set(handles.axes,'YTick',0:X0./10:X0);
set(handles.axes,'XTickLabel',mat2cell(0:N,1,ones(N+1,1)));
set(handles.axes,'YTickLabel',mat2cell(0:X0./10:X0,1,ones(length(0:X0./10:X0),1)));
title(handles.axes,'Liquidation strategy','fontweight','b');
xlabel(handles.axes,'Trading periods','fontweight','b');
ylabel(handles.axes,'Stock amount','fontweight','b');

%% Plotting a separate figure
figure;
surf(repmat((0:N)',1,handles.numStrategies),repmat(targetedVarArray,N+1,1),liquidation_strategies)
title('Liquidation strategy''s Efficient Frontier');
xlabel('Trading periods','fontweight','b');
ylabel('Volatility risk','fontweight','b');
zlabel('Stock amount','fontweight','b');

guidata(handles.output, handles);

% --- Executes on button press in backtesting.

function histo_start_Callback(hObject, eventdata, handles)
% hObject    handle to histo_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of histo_start as text
%        str2double(get(hObject,'String')) returns contents of histo_start as a double


% --- Executes during object creation, after setting all properties.
function histo_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histo_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nb_periods_Callback(hObject, eventdata, handles)
% hObject    handle to nb_periods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nb_periods as text
%        str2double(get(hObject,'String')) returns contents of nb_periods as a double


% --- Executes during object creation, after setting all properties.
function nb_periods_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nb_periods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function backtest_start_Callback(hObject, eventdata, handles)
% hObject    handle to backtest_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of backtest_start as text
%        str2double(get(hObject,'String')) returns contents of backtest_start as a double


% --- Executes during object creation, after setting all properties.
function backtest_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backtest_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eta_Callback(hObject, eventdata, handles)
% hObject    handle to eta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eta as text
%        str2double(get(hObject,'String')) returns contents of eta as a double


% --- Executes during object creation, after setting all properties.
function eta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function turnover_Callback(hObject, eventdata, handles)
% hObject    handle to turnover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
T=str2double(get(handles.maturity,'String'));
% number of time periods
N=str2double(get(handles.nb_periods,'String'));;
% time period length
tau=T./N;
% daily volume 5 million shares $/share
gamma=str2double(get(handles.gamma,'String'));
% impact at 1 percent of market ($/share)/(share/day)
eta=str2double(get(handles.eta,'String'));
% bid ask spread $/share
epsilon=str2double(get(handles.epsilon,'String'));
% volatility of 30% annual
sigma=str2double(get(handles.sigma,'String'));
% initial holding
X0=str2double(get(handles.initial_holding,'String'));
risk_mix = get(handles.turnover,'Value') ;
handles.strategy_to_draw = max(round(risk_mix*handles.numStrategies),1);

set(handles.liquidation_line,'YData',handles.liquidation_strategies(:,handles.strategy_to_draw));
grid(handles.axes,'on');
set(handles.axes,'XLim',[1,N+1]);
set(handles.axes,'YLim',[0,X0]);
set(handles.axes,'XTick',1:N+1);
set(handles.axes,'YTick',0:X0./10:X0);
set(handles.axes,'XTickLabel',mat2cell(0:N,1,ones(N+1,1)));
set(handles.axes,'YTickLabel',mat2cell(0:X0./10:X0,1,ones(length(0:X0./10:X0),1)));
title(handles.axes,'Liquidation strategy','fontweight','b');
xlabel(handles.axes,'Trading periods','fontweight','b');
ylabel(handles.axes,'Stock amount','fontweight','b');
guidata(handles.output, handles);

% --- Executes during object creation, after setting all properties.
function turnover_CreateFcn(hObject, eventdata, handles)
% hObject    handle to turnover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




function turnover_box_Callback(hObject, eventdata, handles)
% hObject    handle to turnover_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of turnover_box as text
%        str2double(get(hObject,'String')) returns contents of turnover_box as a double


% --- Executes during object creation, after setting all properties.
function turnover_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to turnover_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cost_box_Callback(hObject, eventdata, handles)
% hObject    handle to cost_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cost_box as text
%        str2double(get(hObject,'String')) returns contents of cost_box as a double


% --- Executes during object creation, after setting all properties.
function cost_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cost_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PuStrategy.
function PuStrategy_Callback(hObject, eventdata, handles)
% hObject    handle to PuStrategy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PuStrategy contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PuStrategy


% --- Executes during object creation, after setting all properties.
function PuStrategy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PuStrategy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in console_output.
function console_output_Callback(hObject, eventdata, handles)
% hObject    handle to console_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns console_output contents as cell array
%        contents{get(hObject,'Value')} returns selected item from console_output


% --- Executes during object creation, after setting all properties.
function console_output_CreateFcn(hObject, eventdata, handles)
% hObject    handle to console_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end






function EdRebalancing_Callback(hObject, eventdata, handles)
% hObject    handle to EdRebalancing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdRebalancing as text
%        str2double(get(hObject,'String')) returns contents of EdRebalancing as a double




function maturity_Callback(hObject, eventdata, handles)
% hObject    handle to maturity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maturity as text
%        str2double(get(hObject,'String')) returns contents of maturity as a double


% --- Executes during object creation, after setting all properties.
function maturity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maturity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initial_holding_Callback(hObject, eventdata, handles)
% hObject    handle to initial_holding (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initial_holding as text
%        str2double(get(hObject,'String')) returns contents of initial_holding as a double


% --- Executes during object creation, after setting all properties.
function initial_holding_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initial_holding (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function gamma_Callback(hObject, eventdata, handles)
% hObject    handle to gamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gamma as text
%        str2double(get(hObject,'String')) returns contents of gamma as a double


% --- Executes during object creation, after setting all properties.
function gamma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epsilon_Callback(hObject, eventdata, handles)
% hObject    handle to epsilon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epsilon as text
%        str2double(get(hObject,'String')) returns contents of epsilon as a double


% --- Executes during object creation, after setting all properties.
function epsilon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epsilon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initial_price_Callback(hObject, eventdata, handles)
% hObject    handle to initial_price (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initial_price as text
%        str2double(get(hObject,'String')) returns contents of initial_price as a double


% --- Executes during object creation, after setting all properties.
function initial_price_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initial_price (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sigma_Callback(hObject, eventdata, handles)
% hObject    handle to sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sigma as text
%        str2double(get(hObject,'String')) returns contents of sigma as a double


% --- Executes during object creation, after setting all properties.
function sigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
