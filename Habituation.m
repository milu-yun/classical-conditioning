function varargout = Habituation(varargin)
% HABITUATION MATLAB code for Habituation.fig
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Habituation_OpeningFcn, ...
                   'gui_OutputFcn',  @Habituation_OutputFcn, ...
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


function Habituation_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Set timer
handles.timer = timer(...
    'ExecutionMode', 'fixedSpacing', ...
    'BusyMode', 'drop', ...
    'Period', 0.1, ...
    'TimerFcn', {@ArduinoDataReader_hab,hObject});

% Set serial
currentPort = {'COM3'};
if isempty(currentPort)
    set(handles.connectionText,'String','No available serial ports!');
    set(handles.connectionText,'BackgroundColor','r');
else
    a = instrfindall;
    if ~isempty(a)
        fclose(a);
        delete(a);
    end
    handles.arduino = serial(currentPort{1}, 'Baudrate', 115200, 'Timeout', 10);
    fopen(handles.arduino);
    
    set(handles.connectionText,'String',['Connected to ',currentPort{1}]);
    set(handles.connectionText,'BackgroundColor','g');
    set(handles.stopButton, 'Enable', 'off');
    set(handles.startButton, 'Enable', 'on');
end

% Graph
nCue = 4;
set(handles.aBar,'TickDir','out','FontSize',8, ...
    'XLim',[0.5 nCue+0.5],'XTick',1:4,'XTickLabel',{'A','B','C','D'}, ...
    'YLim',[0 1], 'YTick',[0 1]);
xlabel(handles.aBar,'Cue');
ylabel(handles.aBar,'Licking number');

hold(handles.aRaster,'on');
plot(handles.aRaster,[0.5 0.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5 1.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[2.5 2.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
set(handles.aRaster,'TickDir','out','FontSize',8, ...
    'XLim',[0 8],'XTIck',[0 0.5 1.5 2.5 8],...
    'YLim',[0 10],'YTick',0:10,'YTickLabel',{0,[],[],[],[],[],[],[],[],[],10});
xlabel(handles.aRaster,'Time (s)');
ylabel(handles.aRaster,'Trial');

% Cam
% handles.cam = webcam;
% preview(handles.cam);

guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = Habituation_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function startButton_Callback(hObject, eventdata, handles)
% Get Trial Information
cueSelectTemp = get(handles.cueSelect, 'Value');
StartCue = 0;
nCue = 1;
switch cueSelectTemp
    case 1
        cueSelect = 10;
    case 2
        cueSelect = 11;
        StartCue = 1;
    case 3
        cueSelect = 12;
        StartCue = 2;
    case 4
        cueSelect = 13;
        StartCue = 3;
end

rewardProb1 = get(handles.prob1, 'String');
rewardProb = rewardProb1;

% rewardProbTemp = cellstr(get(handles.rewardProb, 'String'));
% rewardProb = rewardProbTemp{get(handles.rewardProb,'Value')};

nTrialTemp = cellstr(get(handles.nTrial,'String'));
nTrial = str2double(nTrialTemp{get(handles.nTrial,'Value')});

rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount, 'Value')});

delayDuration = get(handles.delayDuration,'Value');
ITI = get(handles.ITI,'Value');
%outcomeIdentity = get(handles.outcomeIdentity,'Value');

% Reset figure
cla(handles.aRaster);
hold(handles.aRaster,'on');
handles.Bar.s0 = bar(handles.aRaster,0.25,1000,'BarWidth',0.5,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.Bar.s1 = bar(handles.aRaster,1,1000,'BarWidth',1,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.Bar.s2 = bar(handles.aRaster,1.5+delayDuration/2,1000,'BarWidth',delayDuration,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.Bar.s3 = bar(handles.aRaster,1.5+delayDuration+1.25,1000,'BarWidth',2.5,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
plot(handles.aRaster,[0.5 0.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5 1.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5+delayDuration 1.5+delayDuration],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
set(handles.aRaster,'TickDir','out','FontSize',8, ...
    'XLim',[0 5+delayDuration+ITI],'XTIck',[0 0.5 1.5 1.5+delayDuration 5+delayDuration+ITI],...
    'YLim',[0 10],'YTick',0:10,'YTickLabel',{0,[],[],[],[],[],[],[],[],[],10});
xlabel(handles.aRaster,'Time (s)');
ylabel(handles.aRaster,'Trial');

set(handles.aBar,'XLim',[0.5+StartCue StartCue+nCue+0.5]);

% Reset variables
set(handles.iTrial, 'String', '0');
set(handles.nReward, 'String', '0');

% Data variables
handles.data.stateTime = zeros(nTrial, 5);
handles.data.cue = zeros(nTrial, 1);
handles.data.reward = zeros(nTrial, 1);
handles.data.lickNum = zeros(nTrial, 1);
handles.data.lickTime = [];

% Start reading serial
fprintf(handles.arduino, '%s', ['t', num2str(nTrial)]);
pause(0.25);
fprintf(handles.arduino, '%s', ['r', num2str(rewardAmount)]);
pause(0.25);
fprintf(handles.arduino, '%s', ['i', num2str(ITI)]);
pause(0.25);
fprintf(handles.arduino, '%s', ['c', num2str(cueSelect)]);
pause(0.25);
fprintf(handles.arduino, '%s', ['p', rewardProb]);
pause(0.25);
fprintf(handles.arduino, '%s', ['d', num2str(delayDuration)]);
pause(0.25);

set(handles.mouseName, 'Enable', 'off');
set(handles.nTrial, 'Enable', 'off');
set(handles.ITI, 'Enable', 'off');
set(handles.rewardAmount, 'Enable', 'off');
set(handles.startButton, 'Enable', 'off');
set(handles.stopButton, 'Enable', 'on');
set(handles.valve5, 'Enable', 'off');
set(handles.valve10, 'Enable', 'off');
set(handles.valve1000, 'Enable', 'off');
set(handles.cueSelect, 'Enable', 'off');
set(handles.airpuff, 'Enable', 'off');
set(handles.delayDuration, 'Enable', 'off');
set(handles.prob1, 'Enable', 'off');

fileDir = 'D:\Data\Classical_conditioning\';
handles.fileName = [fileDir get(handles.mouseName,'String'), '_', num2str(clock, '%4d%02d%02d_%02d%02d%02.0f'), '_hab'];

pause(2);
tic;
start(handles.timer);
fprintf(handles.arduino, '%s', ['s', 0]);

guidata(hObject,handles);


function stopButton_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'e');

% Trial type
%   1: Cue A (p=100)
%   2: Cue B (p=50/50)
%   3: Cue C (p=33/33/33)
%   4: Cue D (p=33/33/33)
% nTrial
%   1: 200 trial, 2: 320, 3: 400, 4: 480, 5: 600
% Reward amount
%   1: 3 ul, 2: 4 ul, 3: 5 ul, 4: 6 ul, 5: 7 ul, 6: 8 ul, 7: 9 ul, 8: 10 ul
% Reward probability
%   1: 100, 2: 90, 3: 80, 4: 75, 5: 50, 6: 25, 7:20, 8:10, 9:0

function nTrial_Callback(hObject, eventdata, handles)
%200 320 400 480 600
nTrialTemp = cellstr(get(hObject,'String'));
nTrial = str2double(nTrialTemp{get(hObject,'Value')});
ITITemp = cellstr(get(handles.ITI,'String'));
ITI = str2double(ITITemp{get(handles.ITI,'Value')});
delayDurationTemp = cellstr(get(handles.delayDuration,'String'));
delayDuration = str2double(delayDurationTemp{get(handles.delayDuration,'Value')});
set(handles.eDuration,'String',num2str(nTrial*(delayDuration+ITI+4)/60,3));
rewardProbTemp = cellstr(get(handles.prob1, 'String'));
rewardProb = str2double(rewardProbTemp).*0.01;
rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount,'Value')});
set(handles.eReward,'String',num2str(nTrial*rewardAmount*rewardProb,4));


function nTrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function iTrial_Callback(hObject, eventdata, handles)


function iTrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function message_Callback(hObject, eventdata, handles)
str = get(handles.message,'String');
fprintf(handles.arduino, '%s', str);

function message_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function mouseName_Callback(hObject, eventdata, handles)

function mouseName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function mainFigure_CloseRequestFcn(hObject, eventdata, handles)
t = timerfindall;
if ~isempty(t)
    stop(t);
    delete(t);
end

a = instrfindall;
if ~isempty(a)
    fclose(a);
    delete(a);
end

try
    closePreview(handles.cam);
end

delete(hObject);

function ITI_Callback(hObject, eventdata, handles)
nTrialTemp = cellstr(get(handles.nTrial,'String'));
nTrial = str2double(nTrialTemp{get(handles.nTrial,'Value')});
ITITemp = cellstr(get(hObject,'String'));
ITI = str2double(ITITemp{get(hObject,'Value')});
delayDurationTemp = cellstr(get(handles.delayDuration,'String'));
delayDuration = str2double(delayDurationTemp{get(handles.delayDuration,'Value')});
set(handles.eDuration,'String',num2str(nTrial*(delayDuration+ITI+4)/60,3));

function ITI_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rewardAmount_Callback(hObject, eventdata, handles)
nTrialTemp = cellstr(get(handles.nTrial,'String'));
nTrial = str2double(nTrialTemp{get(handles.nTrial,'Value')});
rewardAmountTemp = cellstr(get(hObject,'String'));
rewardAmount = str2double(rewardAmountTemp{get(hObject,'Value')});
rewardProbTemp = cellstr(get(handles.prob1, 'String'));
rewardProb = str2double(rewardProbTemp).*0.01;
set(handles.eReward,'String',num2str(nTrial*rewardAmount*rewardProb,4));


function rewardAmount_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu3_Callback(hObject, eventdata, handles)

function popupmenu3_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function reverse_Callback(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function valve5_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'w77');
aReward = str2double(get(handles.aReward,'String'));
set(handles.aReward,'String',num2str(aReward+5,4));

function valve10_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'w116');
aReward = str2double(get(handles.aReward,'String'));
set(handles.aReward,'String',num2str(aReward+10,4));

function valve1000_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'w1000');


function delayDuration_Callback(hObject, eventdata, handles)
nTrialTemp = cellstr(get(handles.nTrial,'String'));
nTrial = str2double(nTrialTemp{get(handles.nTrial,'Value')});
ITITemp = cellstr(get(handles.ITI,'String'));
ITI = str2double(ITITemp{get(handles.ITI,'Value')});
delayDurationTemp = cellstr(get(handles.delayDuration,'String'));
delayDuration = str2double(delayDurationTemp{get(handles.delayDuration,'Value')});
set(handles.eDuration,'String',num2str(nTrial*(delayDuration+ITI+4)/60,3));

function delayDuration_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cueSelect_Callback(hObject, eventdata, handles)


function cueSelect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rewardProb_Callback(hObject, eventdata, handles)

function rewardProb_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function modType_Callback(hObject, eventdata, handles)

function modType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in airpuff.
function airpuff_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'a');


% --- Executes on button press in reset.
function reset_Callback(hObject, eventdata, handles)
set(handles.aReward,'String',num2str(0,4));
% hObject    handle to reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function aBar_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate aBar


% --- Executes on mouse press over axes background.
function aBar_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to aBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function prob1_Callback(hObject, eventdata, handles)
% hObject    handle to prob1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prob1 as text
%        str2double(get(hObject,'String')) returns contents of prob1 as a double


% --- Executes during object creation, after setting all properties.
function prob1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prob1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function prob2_Callback(hObject, eventdata, handles)
% hObject    handle to prob3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prob3 as text
%        str2double(get(hObject,'String')) returns contents of prob3 as a double


% --- Executes during object creation, after setting all properties.
function prob2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prob3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function prob3_Callback(hObject, eventdata, handles)
% hObject    handle to prob3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prob3 as text
%        str2double(get(hObject,'String')) returns contents of prob3 as a double


% --- Executes during object creation, after setting all properties.
function prob3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prob3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on selection change in Reversal.
function Reversal_Callback(hObject, eventdata, handles)
% hObject    handle to Reversal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Reversal contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Reversal


% --- Executes during object creation, after setting all properties.
function Reversal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Reversal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in reversalTime.
function reversalTime_Callback(hObject, eventdata, handles)
% hObject    handle to reversalTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns reversalTime contents as cell array
%        contents{get(hObject,'Value')} returns selected item from reversalTime


% --- Executes during object creation, after setting all properties.
function reversalTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reversalTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over cueSelect.
function cueSelect_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to cueSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on cueSelect and none of its controls.
function cueSelect_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to cueSelect (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function eReward_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eReward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function prob1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to prob1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function aRaster_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aRaster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate aRaster


% --- Executes on mouse press over axes background.
function aRaster_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to aRaster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in Punishment.
function Punishment_Callback(hObject, eventdata, handles)
% hObject    handle to Punishment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Punishment contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Punishment


% --- Executes during object creation, after setting all properties.
function Punishment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Punishment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
