function ArduinoDataReader(hObject,eventdata, hFigure)
persistent state iTrial cue jTrial reversal aboveThreshold jReversal outcomeIdentity thresholdReversal...
    initialIdentity secondIdentity nCue identityType modBlock identityList nOmit cueN reversalTimes nTrial

handles = guidata(hFigure);

if isempty(state); state = 9; end
if state==9
    iTrial=1; jTrial=0; aboveThreshold=[]; jReversal=0; nCue = zeros(1,4);...
        cueN = 0; initialIdentity = NaN; secondIdentity = NaN; nOmit = zeros(1,4); reversalTimes = 0;...
        nTrial = 200; thresholdReversal = NaN; identityList = {'1122';'1221';'1212';'2112';'2121';'2211'};...
        modBlockTmp = get(handles.modBlock,'Value');
    if modBlockTmp==1
        modBlock = randi(2,1);
    else
        modBlock = modBlockTmp-1;
    end
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
                            if strcmp(outcomeIdentity(iO),'1')
                                outcomeText = 'Rw';
                                outcomeColor = 'c';
                            elseif strcmp(outcomeIdentity(iO),'2')
                                outcomeText = 'Pn';
                                outcomeColor = 'r';
                            end
                            set(handles.(['outcome',num2str(iO-1)]),'String',outcomeText);
                            set(handles.(['outcome',num2str(iO-1)]),'BackgroundColor',outcomeColor);
                            handles.data.outcomeContingency(iTrial,iO) = str2double(outcomeIdentity(iO));
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
                        
                    case 'n'% The number of used cues
                        cueN = fix(eventData/10);
                        
                    case 'o'
                        identityType = eventData; % arduino rule
                        outcomeIdentity = identityList{identityType+1};
                        if isnan(initialIdentity)
                            initialIdentity = identityType;
                        end
                        for iO = 1:4
                            if strcmp(outcomeIdentity(iO),'1')
                                outcomeText = 'Rw';
                                outcomeColor = 'c';
                            elseif strcmp(outcomeIdentity(iO),'2')
                                outcomeText = 'Pn';
                                outcomeColor = 'r';
                            end
                            set(handles.(['outcome',num2str(iO-1)]),'String',outcomeText);
                            set(handles.(['outcome',num2str(iO-1)]),'BackgroundColor',outcomeColor);
                            handles.data.outcomeContingency(iTrial,iO) = str2double(outcomeIdentity(iO));
                        end
                        
                    case 'f'
                        reversalTimes = eventData;
                        
                    case 't'
                        nTrial = eventData;
                        
                    case 'v'
                        reversal = eventData;
                        if isnan(thresholdReversal)
                            threshold1=randi([140 160],1); threshold2 = round(nTrial./(1+reversalTimes));
                            thresholdReversal = [threshold1 threshold2];
                        end
                        handles.data.reversal(iTrial) = reversal;
                        if reversal ~=0
                            trialTemp = max(iTrial-100, 1);
                            diffCheck = sum(aboveThreshold(trialTemp:iTrial-1));
                            reversalCase = ((reversal ==1) && (diffCheck >= 75) && (jTrial >= thresholdReversal(1))) ||...
                                ((reversal ==2) && (jTrial>=threshold_mod2)); 
                            reversalCase = reversalCase * cueN;
                            switch reversalCase
                                case 2
                                    identity_tmp = identityList{identityType+1};
                                    identity_tmp = regexprep(identity_tmp,'1','3');
                                    identity_tmp = regexprep(identity_tmp,'2','1');
                                    identity_tmp = regexprep(identity_tmp,'3','2');
                                    [~,identityType] = ismember(identity_tmp,identityList);
                                    identityType = identityType-1;
                                    fprintf(handles.arduino, '%s',['o',num2str(identityType)]);
                                    outcomeIdentity = identityList{identityType+1};
                                    jTrial = 0;
                                    %aboveThreshold = 0;
                                    jReversal = jReversal+1;
                                    thresholdReversal = nan;
                                case 4
                                    if rem(jReversal,2)==0 && isnan(secondIdentity)
                                        identity_tmp = identityList;
                                        rwCue_change = randsample(strfind(identity_tmp,'1'),1);
                                        pnCue_change = randsample(strfind(identity_tmp,'2'),1);
                                        identity_tmp(rwCue_change) = '2';
                                        identity_tmp(pnCue_change) = '1';
                                        [~,identityType] = ismember(identity_tmp,identityList);
                                        identityType = identityType-1;
                                        secondIdentity = identityType;
                                        fprintf(handles.arduino, '%s',['o',num2str(identityType)]);
                                    elseif rem(jReversal,2)==0 && ~isnan(secondIdentity)
                                        identityType = secondIdentity;
                                        fprintf(handles.arduino, '%s',['o',num2str(identityType)]);
                                    elseif rem(jReversal,2)==1
                                        identityType = initialIdentity;
                                        fprintf(handles.arduino, '%s',['o',num2str(identityType)]);
                                    end
                                    outcomeIdentity = identityList{identityType+1};
                                    jTrial = 0;
                                    %aboveThreshold = 0;
                                    jReversal = jReversal+1;
                                    thresholdReversal = nan;
                                case 0
                                    if ((reversal ==1) && (diffCheck >=1)) || (reversal ==2)
                                        jTrial = jTrial+1;
                                    end
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
                        
                        set(handles.bar.s2,'Visible','off');
                        set(handles.bar.s3,'Visible','on');
                        handles.data.stateTime(iTrial, 4) = time;
                        handles.data.reward(iTrial) = eventData;
                        
                        if reward == 1
                            if strcmp(outcomeIdentity(cue+1),'1')
                                nReward = str2double(get(handles.nReward,'String'));
                                set(handles.nReward,'String',num2str(nReward+1));
                                rewardAmountTemp = cellstr(get(handles.rewardAmount,'String'));
                                rewardAmount = str2double(rewardAmountTemp{get(handles.rewardAmount,'Value')});
                                aReward = str2double(get(handles.aReward,'String'));
                                set(handles.aReward,'String',num2str(aReward+rewardAmount,4));
                                nRewardCue = str2double(get(handles.(['reward',num2str(cue)]),'String'));
                                set(handles.(['reward',num2str(cue)]),'String',num2str(nRewardCue+1));
                                set(handles.(['reward',num2str(cue)]),'BackgroundColor','c');
                            elseif strcmp(outcomeIdentity(cue+1),'2')
                                set(handles.(['reward',num2str(cue)]),'BackgroundColor','r');
                                nRewardCue = str2double(get(handles.(['reward',num2str(cue)]),'String'));
                                set(handles.(['reward',num2str(cue)]),'String',num2str(nRewardCue+1));
                            end
                            
                            % Plot valve output
                            valveTime = (time - handles.data.stateTime(iTrial,1))/1000000;
                            if strcmp(outcomeIdentity(cue+1),'1')
                                plot(handles.aRaster,[valveTime valveTime],[iTrial-1 iTrial],'LineWidth',2,'Color',[0 1 1]);
                            elseif strcmp(outcomeIdentity(cue+1),'2')
                                plot(handles.aRaster,[valveTime valveTime],[iTrial-1 iTrial],'LineWidth',2,'Color',[1 0 0]);
                            end
                        end
                        
                    case 'i' % state 4: iti
                        if state == 9
                            state = 4;
                            continue;
                        end
                        state = 4;
                        omit = eventData;
                        
                        handles.data.stateTime(iTrial, 5) = time;
                        
                        if omit==0
                            nOmit(cue+1) = nOmit(cue+1) + 1;
                            set(handles.(['omit',num2str(cue)]),'String',num2str(nOmit(cue+1)));
                            set(handles.(['omit',num2str(cue)]),'BackgroundColor','m');
                        end
                        
                        
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
                        anovaTemp = 0;
                        try
                            % ANOVA
                            [pANOVA,~,stats] = anova1(lickNum,cueData,'off');
                            [c, ~, ~, gnames] = multcompare(stats,'display','off');
                            rwCue = strfind(outcomeIdentity,'1');
                            outInd = nCue(rwCue)==0;
                            rwCue(outInd) = [];
                            pnCue = strfind(outcomeIdentity,'2');
                            outInd = nCue(pnCue)==0;
                            pnCue(outInd) = [];
                            
                            gnames = cellfun(@str2double,gnames)+1;
                            rwCue = find(ismember(gnames,rwCue));
                            pnCue = find(ismember(gnames,pnCue));
                            
                            set(handles.pANOVA,'String',num2str(pANOVA,'%.3f'));
                            if pANOVA <= 0.05 && iTrial>=20 && sum(nCue~=0)==cueN
                                set(handles.pANOVA,'BackgroundColor','y');
                                
                                target1 = ismember(c(:,1),rwCue)&ismember(c(:,2),pnCue);
                                target2 = ismember(c(:,1),pnCue)&ismember(c(:,2),rwCue);
                                sig1 = c(target1,6)<0.05 & c(target1,4)>0;
                                sig2 = c(target2,6)<0.05 & c(target2,4)<0;
                                if sum(sig1)+sum(sig2) == sum(target1|target2) && sum(sig1)+sum(sig2)>0
                                    anovaTemp = 1;
                                end
                                
                            else
                                set(handles.pANOVA,'BackgroundColor','w');
                            end
                            c(c(:,6)>0.05,:) = [];
                            nC = size(c,1);
                            for iC = 1:nC
                                plot(handles.aBar,[str2double(gnames{c(iC,1)})+1 str2double(gnames{c(iC,2)})+1],yRange*(1-0.02*iC)*[1 1], ...
                                    'LineWidth', 1,'Color','r');
                            end
                        catch
                        end
                        aboveThreshold = [aboveThreshold anovaTemp];
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
                        outcomeContingency = handles.data.outcomeContingency(1:nTrial,:);
                        
                        save(handles.fileName,'nTrial','nReward','stateTime',...
                            'odorCue','waterReward','lickNum','lickTime','outcomeContingency');
                        
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
                        set(handles.rewardProb, 'Enable', 'on');
                        set(handles.modType, 'Enable', 'on');
                        set(handles.modBlock, 'Enable', 'on');
                        set(handles.reversal, 'Enable', 'on');
                        set(handles.reversalTimes, 'Enable', 'on');
                        set(handles.outcomeIdentity, 'Enable', 'on');
                        
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