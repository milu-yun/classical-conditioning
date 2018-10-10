function varargout = ClassicalConditioning_PnRw(varargin)
%CLASSICALCONDITIONING_PNRW M-file for ClassicalConditioning_PnRw.fig
%for 4 cue reversal
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ClassicalConditioning_PnRw_OpeningFcn, ...
                   'gui_OutputFcn',  @ClassicalConditioning_PnRw_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before ClassicalConditioning_PnRw is made visible.
function ClassicalConditioning_PnRw_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Set timer
handles.timer = timer(...
    'ExecutionMode', 'fixedSpacing', ...
    'BusyMode', 'drop', ...
    'Period', 0.1, ...
    'TimerFcn', {@ArduinoDataReader_PnRw,hObject});

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
    'XLim',[0.5 nCue+0.5],'XTick',1:4,'XTickLabel',{'A','B','C','D'});
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
function varargout = ClassicalConditioning_PnRw_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;


function startButton_Callback(hObject, eventdata, handles)
% Get Trial Information
set(handles.startButton, 'Enable', 'off');
cueSelecTemp = get(handles.cueSelec,'Value');
nCue = 2;
switch cueSelecTemp
    case 1 % AB
        cueSelect = 20;
    case 2 % AC
        cueSelect = 21;
    case 3 % AD
        cueSelect = 22;
    case 4 % BC
        cueSelect = 24;
    case 5 % BD
        cueSelect = 25;
    case 6 % CD
        cueSelect = 28;
    case 7 % ABCD
        cueSelect = 40;
        nCue = 4;
end

rewardProbTemp = cellstr(get(handles.rewardProb, 'String'));
rewardProb = str2double(rewardProbTemp{get(handles.rewardProb,'Value')});
rewardProb = repmat(rewardProb,1,nCue);

nTrialTemp = cellstr(get(handles.nTrial,'String'));
nTrial = str2double(nTrialTemp{get(handles.nTrial,'Value')});

rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount, 'Value')});

delayDurationTmp = get(handles.delayDuration,'Value');
if delayDurationTmp==4
    delayDuration = 2;
else
    delayDuration = delayDurationTmp;
end
ITI = get(handles.ITI,'Value');
modType = get(handles.modType, 'Value');
reversal = get(handles.reversal,'Value');
outcomeIdentity = get(handles.outcomeIdentity,'Value');
reversalTimes = get(handles.reversalTimes,'Value');

% Reset figure
cla(handles.aRaster);
hold(handles.aRaster,'on');
handles.bar.s0 = bar(handles.aRaster,0.25,1000,'BarWidth',0.5,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.bar.s1 = bar(handles.aRaster,1,1000,'BarWidth',1,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.bar.s2 = bar(handles.aRaster,1.5+delayDuration/2,1000,'BarWidth',delayDuration,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.bar.s3 = bar(handles.aRaster,1.5+delayDuration+1.25,1000,'BarWidth',2.5,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
plot(handles.aRaster,[0.5 0.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5 1.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5+delayDuration 1.5+delayDuration],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
set(handles.aRaster,'TickDir','out','FontSize',8, ...
    'XLim',[0 5+delayDuration+ITI],'XTIck',[0 0.5 1.5 1.5+delayDuration 5+delayDuration+ITI],...
    'YLim',[0 10],'YTick',0:10,'YTickLabel',{0,[],[],[],[],[],[],[],[],[],10});
xlabel(handles.aRaster,'Time (s)');
ylabel(handles.aRaster,'Trial');

set(handles.aBar,'XLim',[0.5 4+0.5]);

% Reset variables
set(handles.iTrial, 'String', '0');
set(handles.jTrial, 'String', '0');
set(handles.nReward, 'String', '0');
set(handles.cue0, 'String', '0');
set(handles.cue0, 'BackgroundColor', 'w');
set(handles.cue1, 'String', '0');
set(handles.cue1, 'BackgroundColor', 'w');
set(handles.cue2, 'String', '0');
set(handles.cue2, 'BackgroundColor', 'w');
set(handles.cue3, 'String', '0');
set(handles.cue3, 'BackgroundColor', 'w');
set(handles.reward0, 'String', '0');
set(handles.reward0, 'BackgroundColor', 'w');
set(handles.reward1, 'String', '0');
set(handles.reward1, 'BackgroundColor', 'w');
set(handles.reward2, 'String', '0');
set(handles.reward2, 'BackgroundColor', 'w');
set(handles.reward3, 'String', '0');
set(handles.reward3, 'BackgroundColor', 'w');
set(handles.omit0, 'String', '0');
set(handles.omit0, 'BackgroundColor', 'w');
set(handles.omit1, 'String', '0');
set(handles.omit1, 'BackgroundColor', 'w');
set(handles.omit2, 'String', '0');
set(handles.omit2, 'BackgroundColor', 'w');
set(handles.omit3, 'String', '0');
set(handles.omit3, 'BackgroundColor', 'w');

% Data variables
handles.data.stateTime = zeros(nTrial, 5);
handles.data.cue = zeros(nTrial, 1);
handles.data.reward = zeros(nTrial, 1);
handles.data.lickNum = zeros(nTrial, 1);
handles.data.lickTime = [];
handles.data.outcomeContingency = zeros(nTrial, 4);

% Start reading serialf
fprintf(handles.arduino, '%s', ['t', num2str(nTrial)],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['r', num2str(rewardAmount)],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['i', num2str(ITI)],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['c', num2str(cueSelect)],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['v', num2str([reversal-1, reversalTimes])],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['p', num2str(rewardProb)],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['d', num2str(delayDurationTmp)],'sync');
pause(0.2);
fprintf(handles.arduino, '%s', ['o', num2str(outcomeIdentity-1)],'sync');
pause(0.2);


set(handles.mouseName, 'Enable', 'off');
set(handles.nTrial, 'Enable', 'off');
set(handles.ITI, 'Enable', 'off');
set(handles.rewardAmount, 'Enable', 'off');
set(handles.modType, 'Enable', 'off');

set(handles.stopButton, 'Enable', 'on');
set(handles.valve5, 'Enable', 'off');
set(handles.valve10, 'Enable', 'off');
set(handles.valve1000, 'Enable', 'off');
set(handles.cueSelec, 'Enable', 'off');
set(handles.airpuff, 'Enable', 'off');
set(handles.delayDuration, 'Enable', 'off');
set(handles.rewardProb, 'Enable', 'off');
set(handles.reversal, 'Enable', 'off');
set(handles.reversalTimes, 'Enable', 'off');
set(handles.outcomeIdentity, 'Enable', 'off');
set(handles.modBlock,'Enable','off');

fileDir = 'D:\Data\Classical_conditioning\';
handles.fileName = [fileDir get(handles.mouseName,'String'), '_', num2str(clock, '%4d%02d%02d_%02d%02d%02.0f')];


pause(2);
tic;
start(handles.timer);

fprintf(handles.arduino, '%s', ['s', num2str(modType-1)],'sync');

guidata(hObject,handles);


function stopButton_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'e');

function nTrial_Callback(hObject, eventdata, handles)
nTrialTemp = cellstr(get(hObject,'String'));
nTrial = str2double(nTrialTemp{get(hObject,'Value')});
ITITemp = cellstr(get(handles.ITI,'String'));
ITI = str2double(ITITemp{get(handles.ITI,'Value')});
delayDurationTemp = cellstr(get(handles.delayDuration,'String'));
delayDuration = str2double(delayDurationTemp{get(handles.delayDuration,'Value')});
set(handles.eDuration,'String',num2str(nTrial*(delayDuration+ITI+4)/60,3));

rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount,'Value')});
rewardProbTemp = cellstr(get(handles.rewardProb,'String'));
rewardProb = str2double(rewardProbTemp{get(handles.rewardProb,'Value')});
set(handles.eReward,'String',num2str(nTrial*rewardAmount*rewardProb/100,4));

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
rewardProbTemp = cellstr(get(handles.rewardProb,'String'));
rewardProb = str2double(rewardProbTemp{get(handles.rewardProb,'Value')});
set(handles.eReward,'String',num2str(nTrial*rewardAmount*rewardProb/100,4));

function rewardAmount_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function reverse_Callback(hObject, eventdata, handles)

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
delayDurationTemp{4} = '2';
% if strcmp(delayDurationTemp,'random')
%     delayDurationTemp = 2;
% end
delayDuration = str2double(delayDurationTemp{get(handles.delayDuration,'Value')});
set(handles.eDuration,'String',num2str(nTrial*(delayDuration+ITI+4)/60,3));

function delayDuration_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function outcomeIdentity_Callback(hObject, eventdata, handles)

function outcomeIdentity_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rewardProb_Callback(hObject, eventdata, handles)
nTrialTemp = cellstr(get(handles.nTrial,'String'));
nTrial = str2double(nTrialTemp{get(handles.nTrial,'Value')});
rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount,'Value')});
rewardProbTemp = cellstr(get(hObject,'String'));
rewardProb = str2double(rewardProbTemp{get(hObject,'Value')});
set(handles.eReward,'String',num2str(nTrial*rewardAmount*rewardProb/100,4));

function rewardProb_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function modType_Callback(hObject, eventdata, handles)

function modType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function airpuff_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'a');

function reset_Callback(hObject, eventdata, handles)
set(handles.aReward,'String',num2str(0,4));

function reversal_Callback(hObject, eventdata, handles)



function reversal_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cueSelec_Callback(hObject, eventdata, handles)

function cueSelec_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in modBlock.
function modBlock_Callback(hObject, eventdata, handles)
% hObject    handle to modBlock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns modBlock contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modBlock


% --- Executes during object creation, after setting all properties.
function modBlock_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modBlock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in reversalTimes.
function reversalTimes_Callback(hObject, eventdata, handles)
% hObject    handle to reversalTimes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns reversalTimes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from reversalTimes


% --- Executes during object creation, after setting all properties.
function reversalTimes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reversalTimes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
