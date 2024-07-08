%% Choose sessions to include
close all; clearvars; clc

fps = 240; % frame rate
cohortPath = 'Z:\Filippo\Animals\Cohort12_33-38';
% Choose sessions to merge together
try
    load('Z:\Filippo\Animals\animalData.mat')
    load(fullfile(cohortPath,'allFiles.mat'),'FileInfo')
catch
end

stagePrompt = {'Choose individual sessions',...
    'Stage 1','Stage 2','Stage 3','Stage 4','Stage 5','Stage 6',...
    'Stage 7','Stage 8','Stage 9'};
stagePick = listdlg('PromptString',{'Which sessions do you want to analyze?';'Possible to refine stage sessions afterwards.'}, ...
    'ListString',stagePrompt,...
    'ListSize',[300 200],'InitialValue',1,'SelectionMode','single');

if stagePick==1
    fileSelection = cellfun(@(x) fullfile(fileparts(x),'videos'), {FileInfo.folder}, 'UniformOutput', false)';
    answer = listdlg('ListString',fileSelection,...
        'PromptString','Choose sessions to plot.',...
        'ListSize',[600 350]);
    fileSelection = fileSelection(answer,:);
else
    stageNum = str2double(regexp(stagePrompt{stagePick},'\d*','match','once'));

    all_sesNames = cell(1,6);
    all_dprimes = cell(1,6);
    for i = 1:6
        idx = find(animalData.cohort(12).animal(i).stage_sessionCount==stageNum);
        ses = animalData.cohort(12).animal(i).session_names(idx);
        dvals = animalData.cohort(12).animal(i).dvalues_sessions(idx);
        all_dprimes{i} = dvals;
        all_sesNames{i} = ses;
    end
    % If a certain stage is not represented for an animal, omit this individual
    all_sesNames = all_sesNames(~cellfun(@isempty,all_sesNames));

    prompt = {'d'' -Inf to -1.65', 'd'' -1.65 to -0.5',...
        'd'' -0.5 to 0.5','d'' 0.5 to 1.65',...
        'd'' 1.65 to Inf','First two sessions',...
        'Last two sessions','All sessions of that stage'};
    performancePick = listdlg('PromptString',{'Which sessions from that stage do you want to analyze?';'Possible to refine stage sessions afterwards.'}, ...
        'ListString',prompt,...
        'ListSize',[300 200],'InitialValue',5,'SelectionMode','single');

    if ismember(performancePick,(1:5))
        all_dprimes = vertcat(all_dprimes{:});
        all_sesNames = vertcat(all_sesNames{:});
        [~,~,group] = histcounts(all_dprimes,'BinEdges',[-Inf,-1.65,-0.5,0.5,1.65,Inf]);
        fileSelection = fullfile(fileparts(fileparts(all_sesNames(group==performancePick))),'videos');
    elseif performancePick==6
        all_sesNames = cellfun(@(x) x(1:2),all_sesNames,'UniformOutput',false);
        all_sesNames = vertcat(all_sesNames{:});
        fileSelection = fullfile(fileparts(fileparts(all_sesNames)),'videos');
    elseif performancePick==7
        all_sesNames = cellfun(@(x) x(end-1:end),all_sesNames,'UniformOutput',false);
        all_sesNames = vertcat(all_sesNames{:});
        fileSelection = fullfile(fileparts(fileparts(all_sesNames)),'videos');
    elseif performancePick==8
        all_sesNames = vertcat(all_sesNames{:});
        fileSelection = fullfile(fileparts(fileparts(all_sesNames)),'videos');
    end
end

% Session description for saving variables later on
if exist('stageNum','var')
    if contains(prompt{performancePick},'two')
        suffix = lower(strrep(prompt{performancePick},' two ','2'));
    elseif contains(prompt{performancePick},'All')
        suffix = 'allSessions';
    else
        suffix = regexp(prompt{performancePick},'[-+]?(\d+\.?\d*|\.\d+)|[-+]?Inf','match');
        suffix = ['dprime',cell2mat(join(suffix,'_'))];
    end
    definput = sprintf('stage%i-%s',stageNum,suffix);
    sessionDescription = inputdlg('Enter a session description for saving the files:','Output Folder',[1 100],{definput});
else
    sessionDescription = inputdlg('Enter a session description for saving the files:','Output Folder',[1 100]);
end


prompt = {'d'' -0.5 to 0.5 vs. d'' 1.65 to Inf',...
    'First two sessions vs. d'' 1.65 to Inf',...
    'First four sessions vs. d'' 1.65 to Inf',...
    'First two sessions vs. last two sessions',...
    'First four sessions vs. last four sessions',...
    'Pick sessions yourself'};
comparePick = listdlg('PromptString','How do you want to define naive and expert sessions?', ...
    'ListString',prompt,...
    'ListSize',[300 200],'InitialValue',1,'SelectionMode','single');

if comparePick~=6
    if stagePick==1
        prompt = {'Stage 1','Stage 2','Stage 3','Stage 4','Stage 5','Stage 6',...
            'Stage 7','Stage 8','Stage 9'};
        stagePick = listdlg('PromptString',{'Since you chose individual sessions you have';'to define which stage you are analyzing.'}, ...
            'ListString',prompt,...
            'ListSize',[300 200],'InitialValue',1,'SelectionMode','single');
        stageNum = str2double(regexp(prompt{stagePick},'\d*','match','once'));
    else
        stageNum = str2double(regexp(stagePrompt{stagePick},'\d*','match','once'));
    end

    all_sesNames = cell(1,6);
    all_dprimes = cell(1,6);
    for i = 1:6
        idx = find(animalData.cohort(12).animal(i).stage_sessionCount==stageNum);
        ses = animalData.cohort(12).animal(i).session_names(idx);
        dvals = animalData.cohort(12).animal(i).dvalues_sessions(idx);
        all_dprimes{i} = dvals;
        all_sesNames{i} = ses;
    end
    % If a certain stage is not represented for an animal, omit this individual
    all_sesNames = all_sesNames(~cellfun(@isempty,all_sesNames));
    all_dprimes = vertcat(all_dprimes{:});
    [~,~,group] = histcounts(all_dprimes,'BinEdges',[-Inf,-1.65,-0.5,0.5,1.65,Inf]);
    switch comparePick
        case 1 % d' -0.5 to 0.5 vs. d' 1.65 to Inf
            all_sesNames = vertcat(all_sesNames{:});
            naiveSessions = fullfile(fileparts(fileparts(all_sesNames(group==3))),'videos');
            expertSessions = fullfile(fileparts(fileparts(all_sesNames(group==5))),'videos');
        case 2 % First two sessions vs. d' 1.65 to Inf
            naiveSessions = cellfun(@(x) x(1:2),all_sesNames,'UniformOutput',false);
            naiveSessions = vertcat(naiveSessions{:});
            naiveSessions = fullfile(fileparts(fileparts(naiveSessions)),'videos');

            all_sesNames = vertcat(all_sesNames{:});
            expertSessions = fullfile(fileparts(fileparts(all_sesNames(group==5))),'videos');
        case 3 % First four sessions vs. d' 1.65 to Inf
            naiveSessions = cellfun(@(x) x(1:4),all_sesNames,'UniformOutput',false);
            naiveSessions = vertcat(naiveSessions{:});
            naiveSessions = fullfile(fileparts(fileparts(naiveSessions)),'videos');

            all_sesNames = vertcat(all_sesNames{:});
            expertSessions = fullfile(fileparts(fileparts(all_sesNames(group==5))),'videos');
        case 4 % First two sessions vs. last two sessions
            naiveSessions = cellfun(@(x) x(1:2),all_sesNames,'UniformOutput',false);
            naiveSessions = vertcat(naiveSessions{:});
            naiveSessions = fullfile(fileparts(fileparts(naiveSessions)),'videos');

            expertSessions = cellfun(@(x) x(end-1:end),all_sesNames,'UniformOutput',false);
            expertSessions = vertcat(expertSessions{:});
            expertSessions = fullfile(fileparts(fileparts(expertSessions)),'videos');
        case 5 % First four sessions vs. last four sessions
            naiveSessions = cellfun(@(x) x(1:4),all_sesNames,'UniformOutput',false);
            naiveSessions = vertcat(naiveSessions{:});
            naiveSessions = fullfile(fileparts(fileparts(naiveSessions)),'videos');

            expertSessions = cellfun(@(x) x(end-3:end),all_sesNames,'UniformOutput',false);
            expertSessions = vertcat(expertSessions{:});
            expertSessions = fullfile(fileparts(fileparts(expertSessions)),'videos');
    end
else
    allFiles = cellfun(@(x) fullfile(fileparts(x),'videos'), {FileInfo.folder}, 'UniformOutput', false)';
    answer = listdlg('ListString',allFiles,...
        'PromptString','Choose naive sessions.',...
        'ListSize',[600 350]);
    naiveSessions = allFiles(answer,:);

    answer = listdlg('ListString',allFiles,...
        'PromptString','Choose expert sessions.',...
        'ListSize',[600 350]);
    expertSessions = allFiles(answer,:);
end

%% Whisker angles two conditions (pre vs. post touch-onset)
% Lick variable must be double, as there exist some NaN values
WhiskAngleTable = table('Size',[1,6],...
    'VariableTypes',{'string','double','double','cell','cell','cell'},...
    'VariableNames',{'VideoPath','Go_NoGo_Neutral','Lick','PreTouch','PostTouch','ContactLeft'});

answer = questdlg('Would you like to analyze all frames, or only a subset of them?', ...
    'Frame analysis', ...
    'Yes, all frames','Frames untill retraction of the mouse', 'Choose subset','Yes, all frames');

allframes = false;
retractframes = false;
if isequal(answer,'Yes, all frames')
    allframes = true;
elseif isequal(answer,'Frames untill retraction of the mouse')
    retractframes = true;
else
    answer = inputdlg({'Frames before whisker touch (fps = 240):','Frames after whisker touch (fps = 240):'},'No of frames', ...
        [1 45; 1 45],{'50','100'});
    frames_pre = str2double(answer{1});
    frames_post = str2double(answer{2});
end

idx = 1;
for ses = 1:height(fileSelection)
    % Load HispeedTrials.mat files
    load(fullfile(fileSelection{ses}, 'HispeedTrials.mat'),'HispeedTrials')

    for trial = 1:height(HispeedTrials)
        firstTouch_ms = min([HispeedTrials.ContactLeft{trial,1},HispeedTrials.ContactRight{trial,1}]);
        if isempty(firstTouch_ms)
            firstTouch_idx = NaN;
        else
            firstTouch_idx = find(HispeedTrials.Timestamps{trial,1}==firstTouch_ms,1);
        end
        event_idx = HispeedTrials.Event_Index(trial);
        turningPoint = HispeedTrials.TurningPoint{trial};

        % Convert touch event times into logical array for each frame
        touchLogical = ismember(HispeedTrials.Timestamps{trial,1},HispeedTrials.ContactLeft{trial}) | ...
            ismember(HispeedTrials.Timestamps{trial,1},HispeedTrials.ContactRight{trial});

        % Save one pre-touch matrix with dimensions n x 50 (for 50 frames)
        if allframes || retractframes
            if isnan(firstTouch_idx)
                pre = single(nan);
            else
                pre = mean(HispeedTrials.WhiskerAngle{trial,1}(1:firstTouch_idx-1,:),2,'omitnan')';
            end
        else
            if isnan(firstTouch_idx)
                pre = single(nan(1,frames_pre));
            elseif firstTouch_idx <= frames_pre
                pre = [nan(1,((frames_pre+1)-firstTouch_idx)),mean(HispeedTrials.WhiskerAngle{trial,1}(1:firstTouch_idx-1,:),2,'omitnan')'];
            else
                pre = mean(HispeedTrials.WhiskerAngle{trial,1}(firstTouch_idx-frames_pre:firstTouch_idx-1,:),2,'omitnan')';
            end
        end

        % Save one post-touch matrix with dimensions n x 50 (for 50 frames)
        if allframes
            if isnan(event_idx) || isnan(firstTouch_idx)
                post = single(nan);
                touchLogical_timeWind = [false(1,numel(pre)),false(1,numel(post))];
            else
                post = mean(HispeedTrials.WhiskerAngle{trial,1}(firstTouch_idx:event_idx,:),2,'omitnan')';
                touchLogical_timeWind = [false(1,numel(pre)),touchLogical(firstTouch_idx:event_idx,:)'];
            end
        elseif retractframes
            if isnan(event_idx) || isnan(firstTouch_idx)
                post = single(nan);
                touchLogical_timeWind = [false(1,numel(pre)),false(1,numel(post))];
            elseif HispeedTrials.Lick(trial)==0 && ~isempty(turningPoint)
                post = mean(HispeedTrials.WhiskerAngle{trial,1}(firstTouch_idx:turningPoint(1),:),2,'omitnan')';
                touchLogical_timeWind = [false(1,numel(pre)),touchLogical(firstTouch_idx:turningPoint(1),:)'];                
            else
                post = mean(HispeedTrials.WhiskerAngle{trial,1}(firstTouch_idx:event_idx,:),2,'omitnan')';
                touchLogical_timeWind = [false(1,numel(pre)),touchLogical(firstTouch_idx:event_idx,:)'];
            end            
        else
            if isnan(firstTouch_idx)
                post = single(nan(1,frames_post));
                touchLogical_timeWind = [false(1,frames_pre),false(1,frames_post)];
            elseif numel(HispeedTrials.Timestamps{trial,1})-firstTouch_idx < (frames_post-1)
                post = [mean(HispeedTrials.WhiskerAngle{trial,1}(firstTouch_idx:numel(HispeedTrials.Timestamps{trial,1}),:),2,'omitnan')',...
                    nan(1,(frames_post-1)-(numel(HispeedTrials.Timestamps{trial,1})-firstTouch_idx))];
                touchLogical_timeWind = [false(1,frames_pre),touchLogical(firstTouch_idx:numel(HispeedTrials.Timestamps{trial,1}),:)',...
                    false(1,(frames_post-1)-(numel(HispeedTrials.Timestamps{trial,1})-firstTouch_idx))];
            else
                post = mean(HispeedTrials.WhiskerAngle{trial,1}(firstTouch_idx:firstTouch_idx+(frames_post-1),:),2,'omitnan')';
                touchLogical_timeWind = [false(1,frames_pre),touchLogical(firstTouch_idx:firstTouch_idx+(frames_post-1),:)'];
            end
        end

        % In a double variable save the trial type
        % In a logical variable save the lick result
        % Subtract from 180° in order to reverse orientation in plots later
        WhiskAngleTable(idx,:) = table(HispeedTrials.VideoPath(trial),HispeedTrials.Go_NoGo_Neutral(trial),HispeedTrials.Lick(trial),{180-pre},{180-post},{touchLogical_timeWind});
        idx = idx+1;
    end
end

% Add NaN values to adjust arrays to same length
if allframes || retractframes
    maxPre = max(cellfun(@numel, WhiskAngleTable.PreTouch));
    maxPost = max(cellfun(@numel, WhiskAngleTable.PostTouch));
    % For plotting
    xvals_pre = seconds(linspace(-maxPre/fps,-1/fps,maxPre));
    xvals_post = seconds(linspace(0,maxPost/fps,maxPost));
    % xvals = [maxPre, maxPost]; % For plotting
    
    for i = 1:height(WhiskAngleTable)
        WhiskAngleTable.ContactLeft{i} = [false(1,maxPre - numel(WhiskAngleTable.PreTouch{i})),...
            WhiskAngleTable.ContactLeft{i},false(1,maxPost - numel(WhiskAngleTable.PostTouch{i}))];
        WhiskAngleTable.PreTouch{i} = [nan(1,maxPre - numel(WhiskAngleTable.PreTouch{i})),WhiskAngleTable.PreTouch{i}];
        WhiskAngleTable.PostTouch{i} = [WhiskAngleTable.PostTouch{i},nan(1,maxPost - numel(WhiskAngleTable.PostTouch{i}))];
    end
else
    % xvals = [frames_pre, frames_post]; % For plotting
    xvals_pre = seconds(linspace(-frames_pre/fps,-1/fps,frames_pre));
    xvals_post = seconds(linspace(0,frames_post/fps,frames_post));
end


% DEFINE CONDITIONS TO COMPARE
cond1_label = 'go trials';
cond1_trial_type = 1; % For all trial types set to [1,2,3]
cond1_lick_type = [0,1]; % For all lick types set to [0,1]

cond2_label = 'nogo trials';
cond2_trial_type = 2; % For all trial types set to [1,2,3]
cond2_lick_type = [0,1]; % For all lick types set to [0,1]

% Only go successes and no-go failures
cond1_pre_concat = vertcat(WhiskAngleTable.PreTouch{ismember(WhiskAngleTable.Go_NoGo_Neutral,cond1_trial_type) & ismember(WhiskAngleTable.Lick,cond1_lick_type)});
cond2_pre_concat = vertcat(WhiskAngleTable.PreTouch{ismember(WhiskAngleTable.Go_NoGo_Neutral,cond2_trial_type) & ismember(WhiskAngleTable.Lick,cond2_lick_type)});

% Use median, as occasionally there are some Inf or very large values
cond1_pre_median = median(cond1_pre_concat,1,'omitnan');
cond2_pre_median = median(cond2_pre_concat,1,'omitnan');

cond1_post_concat = vertcat(WhiskAngleTable.PostTouch{ismember(WhiskAngleTable.Go_NoGo_Neutral,cond1_trial_type) & ismember(WhiskAngleTable.Lick,cond1_lick_type)});
cond2_post_concat = vertcat(WhiskAngleTable.PostTouch{ismember(WhiskAngleTable.Go_NoGo_Neutral,cond2_trial_type) & ismember(WhiskAngleTable.Lick,cond2_lick_type)});

% Use median, as occasionally there are some Inf or very large values
cond1_post_median = median(cond1_post_concat,1,'omitnan');
cond2_post_median = median(cond2_post_concat,1,'omitnan');

% Plot results
figure, hold on
plot(xvals_pre,cond1_pre_median,'-','Color',"#0072BD")
plot(xvals_post,cond1_post_median,'--','Color',"#0072BD")
plot(xvals_pre,cond2_pre_median,'-','Color',"#D95319")
plot(xvals_post,cond2_post_median,'--','Color',"#D95319")
legend({[cond1_label,'_{pre}'],[cond1_label,'_{post}'],[cond2_label,'_{pre}'],[cond2_label,'_{post}']})

title(sprintf('Whisker angles - %s vs. %s', cond1_label,cond2_label))
ylabel('Whisker angle [deg]')
xlabel('Time')

% Save the WhiskAngleTable.mat variable
destfold = fullfile(cohortPath,'Analysis-Figures\Behavioral-Metrics\Variables');
if exist(destfold,"dir") == 0
    mkdir(destfold)
end

%% Number of whisking cycles before and after touch-onset
% Get the number of whisking cycles before and after touch-onset
% Generate Table with timestamps of protraction points (locs with
% findpeaks), both for the time window before and after whisker touch.
% Also save the average whisking frequency.

% Bandpass filter (here 5 - 40 Hz)
bpFilter = [5 40];

% runTrials = randperm(height(WhiskAngleTable),20); % pick 20 random trials
plotTrials = find([WhiskAngleTable.Lick]==0 & [WhiskAngleTable.Go_NoGo_Neutral]==2)'; % pick only no-go successes
randNumOfTrials = min([20,numel(plotTrials)]);
plotTrials = plotTrials(randperm(numel(plotTrials),randNumOfTrials));

newColumns = [table(nan(height(WhiskAngleTable), 1), 'VariableNames', {'meanFq'}), ...
              cell2table(cell(height(WhiskAngleTable), 1), 'VariableNames', {'cyclesPre'}), ...
              cell2table(cell(height(WhiskAngleTable), 1), 'VariableNames', {'cyclesPost'})];
WhiskerCycles = [WhiskAngleTable(:, 1:3),newColumns];

fprintf('\nCalculating whisker angles and band-pass filter them...\n')
count = 1;
for i = 1:height(WhiskAngleTable)
    switch WhiskAngleTable.Go_NoGo_Neutral(i)
        case 1
            trialDescript = 'go';
        case 2
            trialDescript = 'no-go';
        case 3
            trialDescript = 'neutral';
    end
    if WhiskAngleTable.Lick(i)==1
        trialDescript = [trialDescript, ' lick']; %#ok<AGROW>
    else
        trialDescript = [trialDescript, ' no-lick']; %#ok<AGROW>
    end
    
    xvals_plot = (-numel(WhiskAngleTable.PreTouch{1}):numel(WhiskAngleTable.PostTouch{1})-1)./fps;

    if ismember(i,plotTrials)
        figure
        sgtitle(sprintf('Trial #%i - %s',i,trialDescript))
        subplot(2,1,1)
        hold on
        yvals = [WhiskAngleTable.PreTouch{i},WhiskAngleTable.PostTouch{i}];
        plot(xvals_plot,yvals)

        % Get bars for whisker touch events
        barBegins = strfind(WhiskAngleTable.ContactLeft{i}, [0 1]);
        if WhiskAngleTable.ContactLeft{i}(1)
            barBegins = [1, barBegins+1];
        end
        barEnds = strfind(WhiskAngleTable.ContactLeft{i}, [1 0]);
        if WhiskAngleTable.ContactLeft{i}(end)
            barEnds = [barEnds, numel(WhiskAngleTable.ContactLeft{i})]; %#ok<AGROW>
        end

        % Plot bars above whisker plot
        barHeight = max(yvals)+(max(yvals)-min(yvals))*0.1;
        for barCount = 1:numel(barBegins)
            plot([xvals_plot(barBegins(barCount)),xvals_plot(barEnds(barCount))],...
                [barHeight, barHeight], 'Color','#ff4d4d','LineWidth',3)
        end
        hold off

        title('Raw mean')
        ylabel('Whisker angle [deg]')
        xlabel('Time [sec]')
    end
    
    yvals_plot = [WhiskAngleTable.PreTouch{i},WhiskAngleTable.PostTouch{i}];
    xvals_plot = (-numel(WhiskAngleTable.PreTouch{1}):numel(WhiskAngleTable.PostTouch{1})-1)./fps;

    % Have to remove missing values, otherwise bandpass filtering doesn't work
    contactLogical = WhiskAngleTable.ContactLeft{i}(~isnan(yvals_plot));
    xvals_plot = xvals_plot(~isnan(yvals_plot));
    yvals_plot = yvals_plot(~isnan(yvals_plot));

    TT_plot = array2timetable(yvals_plot','RowTimes',seconds(xvals_plot'));

    if ~isempty(TT_plot) && numel(TT_plot.Var1)>1 % In order to bandpass filter
        % Fill in timestamp gaps (necessary for bandpass filtering)
        TT_plot = retime(TT_plot,'regular','linear','SampleRate',fps);
        [pks,locs,~,prom] = findpeaks(bandpass(TT_plot.Var1,bpFilter,fps),seconds(TT_plot.Time),'MinPeakProminence',5);
        % Removing peaks with prominence greater than 45° (likely noise)
        idx = prom > 45;
        pks(idx) = [];
        locs(idx) = [];

        % Fast fourier transform of the bandpass filtered signal
        signal_fft = fft(bandpass(TT_plot.Var1,bpFilter,fps));
        % Compute the two-sided spectrum
        P2 = abs(signal_fft/length(signal_fft));
        % Compute the single-sided spectrum
        P1 = P2(1:floor(length(signal_fft)/2+1));
        P1(2:end-1) = 2*P1(2:end-1);
        % Define the frequency axis
        f = fps*(0:(length(signal_fft)/2))/length(signal_fft);
        % Calculate the mean frequency
        meanFreq = sum(P1.*f')/sum(P1);

        WhiskerCycles.meanFq(i) = meanFreq;
        WhiskerCycles.cyclesPre{i} = locs(locs<0);
        WhiskerCycles.cyclesPost{i} = locs(locs>=0);

        if ismember(i,plotTrials)
        subplot(2,1,2)
        hold on
        plot(TT_plot.Time, bandpass(TT_plot.Var1,bpFilter,fps))
        plot(locs, pks, 'or');

        % Get bars for whisker touch events
        barBegins = strfind(contactLogical, [0 1]);
        if contactLogical(1)
            barBegins = [1, barBegins+1];
        end
        barEnds = strfind(contactLogical, [1 0]);
        if contactLogical(end)
            barEnds = [barEnds, numel(contactLogical)]; %#ok<AGROW>
        end

        % Plot bars above whisker plot
        barHeight = max(bandpass(TT_plot.Var1,bpFilter,fps))+...
            (max(bandpass(TT_plot.Var1,bpFilter,fps))-min(bandpass(TT_plot.Var1,bpFilter,fps)))*0.1;
        for barCount = 1:numel(barBegins)
            plot([seconds(xvals_plot(barBegins(barCount))),seconds(xvals_plot(barEnds(barCount)))],...
                [barHeight, barHeight], 'Color','#ff4d4d','LineWidth',3)
        end
        hold off

        title(sprintf('Bandpass %i to %i Hz - Mean whisking frequency: %.1f Hz',bpFilter(1),bpFilter(2),meanFreq))
        ylabel('Whisker angle deviation [deg]')
        xlabel('Time [sec]')
        end
    end

    % Indicate the progress for every 10%
    if i == height(WhiskAngleTable)
        fprintf('100%% done\n');
    elseif i >= height(WhiskAngleTable)/10 * count
        fprintf('%.0f%% done\n', 10*count);
        count = count + 1;
    end
end
