function ArduinoDataReader(hObject,eventdata, hFigure)
persistent state iTrial cue jTrial reversal aboveThreshold jReversal outcomeIdentity...
    initialIdentity nCue identityType cueType modBlock probList nOmit cueN reversalTimes nTrial thresholdReversal

handles = guidata(hFigure);

if isempty(state); state = 9; end
if state==9
    iTrial=1; jTrial=0; aboveThreshold=0; jReversal=0; nCue = zeros(1,4);probList = zeros(1,4);
    cueN = 2; initialIdentity = NaN; cueType = zeros(1,4); nOmit = zeros(1,4);thresholdReversal = NaN;
    reversalTimes = 0; nTrial = 200;
end

try
    while handles.arduino.BytesAvailable > 0
        str = fscanf(handles.arduino,'%s');
        set(handles.eventText,'String',str);
        str = strsplit(str);
        nStr = length(str);
        
        for iStr = 1:nStr
            if isstrprop(str{iStr}(1),'digit')
                s = sscanf(str{iStr},'%lu%c%d');
                time = s(1);
                event = char(s(2));
                eventData = s(3);
                
                switch event
                    case 'b' % state 0: baseline
                        state = 0;
                        iTrial = eventData;
                        handles.data.stateTime(iTrial,1) = time;
                        
                        if iTrial<10
                            yRange = 10;
                        else
                            yRange = iTrial;
                        end
                        set(handles.aRaster,'YLim',[yRange-10 yRange], ...
                            'YTick',(yRange-10):yRange,...
                            'YTickLabel',{(yRange-10),[],[],[],[],[],[],[],[],[],yRange});
                        set(handles.bar.s3,'Visible','off');
                        set(handles.bar.s0,'Visible','on');
                        set(handles.iTrial,'String',num2str(iTrial));
                        set(handles.jTrial,'String',num2str(jTrial));
                        set(handles.jReversal,'String',num2str(jReversal));
                        set(handles.cue0,'BackgroundColor','w');
                        set(handles.cue1,'BackgroundColor','w');
                        set(handles.cue2,'BackgroundColor','w');
                        set(handles.cue3,'BackgroundColor','w');
                        set(handles.reward0,'BackgroundColor','w');
                        set(handles.reward1,'BackgroundColor','w');
                        set(handles.reward2,'BackgroundColor','w');
                        set(handles.reward3,'BackgroundColor','w');
                        set(handles.omit0,'BackgroundColor','w');
                        set(handles.omit1,'BackgroundColor','w');
                        set(handles.omit2,'BackgroundColor','w');
                        set(handles.omit3,'BackgroundColor','w');
                        
                        for iO = 1:4
                            outcomeText = probList(iO);
                            outcomeColor = 'c';
                            set(handles.(['outcome',num2str(iO-1)]),'String',outcomeText);
                            set(handles.(['outcome',num2str(iO-1)]),'BackgroundColor',outcomeColor);
                            handles.data.problist(iTrial,iO) = probList(iO);
                        end
                        
                        % Plot iti end time
                        if iTrial > 1
                            endTime = (time - handles.data.stateTime(iTrial-1,1))/1000000;
                            plot(handles.aRaster,[endTime endTime],[iTrial-2 iTrial-1],'LineWidth',1,'Color',[0.8 0 0]);
                        end
                        
                    case 'c' % state 1: cue and delay
                        state = 1;
                        cue = eventData;
                        
                        handles.data.stateTime(iTrial,2) = time;
                        handles.data.cue(iTrial) = eventData;
                        
                        set(handles.bar.s0,'Visible','off');
                        set(handles.bar.s1,'Visible','on');
                        
                        nCue(cue+1) = nCue(cue+1) + 1;
                        set(handles.(['cue',num2str(cue)]),'String',num2str(nCue(cue+1)));
                        set(handles.(['cue',num2str(cue)]),'BackgroundColor','y');
                        
                    case 'n' % Combination of used cues
                        cueChoice = eventData;
                        switch cueChoice
                            case 20; cueType = [1 2]; % AB
                            case 21; cueType = [1 3]; % AC
                            case 22; cueType = [1 4]; % AD
                            case 24; cueType = [2 3]; % BC
                            case 25; cueType = [2 4]; % BD
                            case 28; cueType = [3 4]; % CD
                        end
                        
                    case 'p'
                        probability = eventData;
                        probtemp = num2str(probability);
                        iProb = str2num(probtemp(1));
                        probList(iProb) = str2double(probtemp(2:end));
                        handles.data.problist(iTrial,:) = probList;
                        
                    case 'f'
                        reversalTimes = eventData;
                        
                    case 't'
                        nTrial = eventData;
                        
                    case 'v'
                        reversal = eventData;
                        %threshold_mod1 = 100;
                        %threshold_mod2 = round(nTrial./(1+reversalTimes));
                        if reversal ~=0
                            if isnan(thresholdReversal)
                                threshold1=randi([30 50],1); threshold2 = round(nTrial./(1+reversalTimes));
                                thresholdReversal = [threshold1 threshold2]; 
                            end
                            reversalCase = ((reversal ==1) && (jTrial >= thresholdReversal(1))) && aboveThreshold >= 30 || ((reversal ==2) && (jTrial>=thresholdReversal(2)));
                            if reversalCase
                                usedProb = probList(cueType);
                                [maxProb, maxIndex] = max(usedProb);
                                [minProb, minIndex] = min(usedProb);
                                usedProb(maxIndex) = minProb;
                                usedProb(minIndex) = maxProb;
                                fprintf(handles.arduino, '%s',['p',num2str(usedProb)]);
                                jTrial = 0;
                                aboveThreshold = 0;
                                jReversal = jReversal+1;
                                thresholdReversal = nan;
                                set(handles.jReversal,'string',num2str(jReversal))
                            elseif reversal ==2
                                jTrial = jTrial+1;
                                set(handles.jTrial,'string', num2str(jTrial))
                            end
                        end
                        
                    case 'd' % state 1: delay
                        state = 2;
                        
                        handles.data.stateTime(iTrial,3) = time;
                        set(handles.bar.s1,'Visible','off');
                        set(handles.bar.s2,'Visible','on');
                        
                    case 'r' % state 2: reward
                        state = 3;
                        reward = eventData;
                        handles.data.stateTime(iTrial, 4) = time;
                        handles.data.reward(iTrial) = reward;
                        
                        set(handles.bar.s2,'Visible','off');
                        set(handles.bar.s3,'Visible','on');
                        
                        
                        if reward == 1
                            nReward = str2double(get(handles.nReward,'String'));
                            set(handles.nReward,'String',num2str(nReward+1));
                            rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
                            rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount,'Value')});
                            aReward = str2double(get(handles.aReward,'String'));
                            set(handles.aReward,'String',num2str(aReward+rewardAmount));
                            nRewardCue = str2double(get(handles.(['reward',num2str(cue)]),'String'));
                            set(handles.(['reward',num2str(cue)]),'String',num2str(nRewardCue+1));
                            
                            % Plot valve output
                            valveTime = (time - handles.data.stateTime(iTrial,1))/1000000;
                            plot(handles.aRaster,[valveTime valveTime],[iTrial-1 iTrial],'LineWidth',2,'Color',[0 1 1]);
                        end
                        
                    case 'i' % state 4: iti
                        if state == 9
                            state = 4;
                            continue;
                        end
                        state = 4;
                        omit = eventData;
                        
                        handles.data.stateTime(iTrial, 5) = time;
                        
                        %                         if omit==0
                        %                             nOmit(cue+1) = nOmit(cue+1) + 1;
                        %                             set(handles.(['omit',num2str(cue)]),'String',num2str(nOmit(cue+1)));
                        %                             set(handles.(['omit',num2str(cue)]),'BackgroundColor','m');
                        %                         end
                        
                        
                        % Plot lick number histogram
                        if iTrial<20
                            lickNum = handles.data.lickNum(1:iTrial);
                            cueData = handles.data.cue(1:iTrial);
                        else
                            lickNum = handles.data.lickNum(iTrial-19:iTrial);
                            cueData = handles.data.cue(iTrial-19:iTrial);
                        end
                        lickMean = zeros(1,4);
                        lickSem = zeros(1,4);
                        
                        barColor = {[0 0 0.8],[0.8 0 0],[0 0.8 0],[0 0.5 0.5]};
                        cla(handles.aBar);
                        hold(handles.aBar,'on');
                        for iCue = 1:4
                            %if isempty(cueData==(iCue-1)); continue; end
                            lickMean(iCue) = mean(lickNum(cueData==(iCue-1)));
                            lickSem(iCue) = std(lickNum(cueData==(iCue-1)))/sqrt(sum(cueData==(iCue-1)));
                            bar(handles.aBar,iCue,lickMean(iCue),'LineStyle','none','FaceColor',barColor{iCue},'BarWidth',0.5);
                        end
                        yRange = ceil(max(lickMean+lickSem).*1.1);
                        if yRange==0; yRange = 1; end
                        h = errorbar(handles.aBar,1:4,lickMean,lickSem,'Color','k','LineWidth',1,'LineStyle','none');
                        set(handles.aBar,'TickDir','out','FontSize',8, ...
                            'XLim',[0.5 4+0.5],'XTick',1:4,'XTickLabel',{'A','B','C','D'}, ...
                            'YLim',[0 yRange],'YTick',[0 yRange]);
                        try
                            % ttest
                            [httest,pttest] = ttest2(lickNum(cueData==(cueType(1)-1)),lickNum(cueData==cueType(2)-1));
                            [Cmax, Imax] = max(probList(cueType));
                            [Cmin, Imin] = min(probList(cueType));
                            dtI = mean(lickNum(cueData==cueType(Imax)-1))>mean(lickNum(cueData==cueType(Imin)-1)); %distinguish
                            set(handles.pANOVA,'String',num2str(pttest,'%.3f'));
                            if pttest <= 0.05 && iTrial>=20 && dtI
                                set(handles.pANOVA,'BackgroundColor','y');
                                aboveThreshold = aboveThreshold + 1;
                                if reversal ==1
                                    jTrial = jTrial+1;
                                end
                            else
                                set(handles.pANOVA,'BackgroundColor','w');
                            end
                            set(handles.jTrial,'string', num2str(jTrial))
                        catch
                        end
                        hold(handles.aBar,'off');
                        
                    case 'l'
                        handles.data.lickTime = [handles.data.lickTime; time iTrial state eventData];
                        if ~isempty(handles.data.stateTime(iTrial,1)) && handles.data.stateTime(iTrial,1)~=0
                            lickTime = (time - handles.data.stateTime(iTrial,1))/1000000;
                        else
                            lickTime = (time - 5000000)/1000000;
                        end
                        
                        if state == 2
                            handles.data.lickNum(iTrial) = handles.data.lickNum(iTrial) + 1;
                        end
                        
                        plot(handles.aRaster,[lickTime lickTime],[iTrial-1 iTrial],'LineWidth',1,'Color','k');
                        
                        
                    case 'e' % state 9: end trial
                        state = 9;
                        stop(handles.timer);
                        
                        nTrial = iTrial;
                        nReward = str2double(get(handles.nReward,'String'));
                        stateTime = handles.data.stateTime(1:nTrial,:);
                        odorCue = handles.data.cue(1:nTrial);
                        waterReward = handles.data.reward(1:nTrial);
                        lickNum = handles.data.lickNum(1:nTrial);
                        lickTime = handles.data.lickTime;
                        rwProb = handles.data.problist(1:nTrial,:);
                        
                        save(handles.fileName,'nTrial','nReward','stateTime',...
                            'odorCue','waterReward','lickNum','lickTime','rwProb');
                        
                        set(handles.stopButton, 'Enable', 'off');
                        set(handles.mouseName, 'Enable', 'on');
                        set(handles.nTrial, 'Enable', 'on');
                        set(handles.ITI, 'Enable', 'on');
                        set(handles.rewardAmount, 'Enable', 'on');
                        set(handles.startButton, 'Enable', 'on');
                        set(handles.valve5, 'Enable', 'on');
                        set(handles.valve10, 'Enable', 'on');
                        set(handles.valve1000, 'Enable', 'on');
                        set(handles.cueSelec, 'Enable', 'on');
                        set(handles.airpuff, 'Enable', 'on');
                        set(handles.delayDuration, 'Enable', 'on');
                        set(handles.prob1, 'Enable', 'on');
                        set(handles.prob2, 'Enable', 'on');
                        set(handles.modType, 'Enable', 'on');
                        set(handles.Reversal, 'Enable', 'on');
                        set(handles.reversalTimes, 'Enable', 'on');
                        fclose(handles.arduino);
                        pause(0.25);
                        fopen(handles.arduino);
                end
            end
        end
    end
    elapsedTime = toc;
    minute = floor(elapsedTime/60);
    second = mod(elapsedTime,60);
    set(handles.duration,'Str',[num2str(minute,'%d'),':',num2str(second,'%03.1f')]);
    guidata(hFigure,handles);
catch err
    disp(err.message);
end