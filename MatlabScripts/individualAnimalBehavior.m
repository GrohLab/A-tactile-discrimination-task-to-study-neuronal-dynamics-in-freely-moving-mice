%% Gather Data Files

close all
clearvars
clc
cd 'Z:\Filippo\Scripts\MatlabScripts'
addpath 'Z:\Filippo\Scripts\GitHub\matlab-toml\toml'
addpath 'Z:\Filippo\Scripts\Downloaded Scripts'

% Access correct individual
startPath = 'Z:\Filippo\Animals';
try
    load(fullfile(startPath,'animalData.mat'))
    
catch
end

startPath = uigetdir(startPath,'Select an Animal');
if ~startPath
    fprintf(2,'\nNo start path was selected.\n\n')
    return
elseif exist(startPath,'dir')==0
    fprintf(2,'\nYour start path is non existing.')
    fprintf(2,['\nChoose a different ' ...
        'one.\n\n'])
    return
else
    [~,animalName,~] = fileparts(startPath);
%    if isempty(regexp(animalName,'#\d','once')) || regexp(animalName,'#\d') ~= 1
%        fprintf(2,'\nYour start path is not an animal directory.')
%        fprintf(2,'\nChoose a different one.\n\n')
%        return
%    end
end

% Collect all event list csv files
FileInfo = dir(fullfile(startPath,'**\*table.csv'));
Sessions = cell(numel(FileInfo),1);
for i = 1:numel(FileInfo)
    % Include real sessions, but exclude any test sessions etc.
    if contains(FileInfo(i).folder, 'P3.')
        Sessions{i} = fullfile(FileInfo(i).folder,FileInfo(i).name);
    end
end
Sessions = Sessions(cellfun(@(x) ~isempty(x), Sessions));
% Sort the Sessions only according to their stage description
cutted = cellfun(@(x) regexp(x,'.*\P[0-9.]*','match'),Sessions,'UniformOutput',true);
[~,idx] = sortrows(cutted);
Sessions = Sessions(idx);

% Order Sessions according to their stage description (10 after 9)
Sessions = natsort(Sessions);

% Save the relevant variables of each animal in a .mat file ("animalData")
cohort_str = getCohort(startPath);
cohort_num = str2double(regexp(cohort_str,'\d*','match'));

cohort_animals = dir(fullfile(fileparts(startPath),'#*'));
animal_num = find(strcmp({cohort_animals.name},animalName));

Timestamps = cell(1,numel(Sessions));
Events = cell(1,numel(Sessions));
if exist(fullfile(startPath,'sessionInfo.mat'),'file')
    answer = questdlg('Previous Sessions have already been imported. Would you like to include those?', ...
        'Import of previous Sessions', ...
        'Yes','No, Reload all Sessions','Yes');
    switch answer
        case 'Yes'
            load(fullfile(startPath,'sessionInfo.mat'))
            % newSes = setdiff(Sessions_temp,Sessions);
            Timestamps(1:numel(Timestamps_copy)) = Timestamps_copy;
            Events(1:numel(Events_copy)) = Events_copy;
            fprintf('There were %d sessions found. Adding %d more...\n',...
                numel(Sessions_copy),numel(Sessions)-numel(Sessions_copy))
            for i=numel(Sessions_copy)+1:numel(Sessions)
                T = readtable(Sessions{i},'Delimiter',';');
                Timestamps{i} = T.Time;
                Events{i} = T.Description;
                fprintf('Import of session %d\n',i)
            end
            fprintf('\nTotal number of sessions = %d\n\n',numel(Sessions))
        case 'No, Reload all Sessions'
            for i=1:numel(Sessions)
                T = readtable(Sessions{i},'Delimiter',';');
                Timestamps{i} = T.Time;
                Events{i} = T.Description;
                fprintf('Import of session %d\n',i)
            end
            fprintf('\nTotal number of sessions = %d\n\n',numel(Sessions))
        otherwise
            % Return if no answer was picked
            return
    end
else
    for i=1:numel(Sessions)
        T = readtable(Sessions{i},'Delimiter',';');
        Timestamps{i} = T.Time;
        Events{i} = T.Description;
        fprintf('Import of session %d\n',i)
    end
    fprintf('\nTotal number of sessions = %d\n\n',i)
end

% Save Sessions, Events and Timestamps to a mat file for faster reading
sessionFile = fullfile(startPath,'sessionInfo.mat');
Timestamps_copy = Timestamps;
Events_copy = Events;
Sessions_copy = Sessions;
save(sessionFile,'Sessions_copy','Events_copy','Timestamps_copy')
   
% This section should exclude so-called "return events", so lick events
% that were falsely recorded, because the mouse returned to the same lick
% port after having crossed the middle beam.

lick_events = {'Go Success','Go Failure','No-Go Success','No-Go Failure',...
    'Medium Lick','Medium No Lick','Diagonal Lick','Diagonal No Lick',...
    'Neutral Lick','Neutral No Lick'};
Lick_Events = cell(1,numel(Events));
for i = 1:numel(Events)
    idx_2 = false(1,numel(Events));
    X = cellfun(@(c)strncmpi(c,Events{i},8),lick_events,'UniformOutput',false);
    idx = cellfun(@(c)find(c),X,'UniformOutput',false);
    idx = sort(vertcat(idx{1:end}));
    Lick_Events{i} = Events{i}(idx);
    if ismember(cohort_str,["cohort_01","cohort_02","cohort_03"])
        for ii = 2:numel(Lick_Events{i})
            if strcmp(Lick_Events{i}{ii},'Go Failure (LP1)') && ...
                    ismember(Lick_Events{i}{ii-1},{'Go Success (LP1)','Go Failure (LP1)'})
                idx_2(ii) = true;
            elseif strcmp(Lick_Events{i}{ii},'Go Failure (LP2)') && ...
                    ismember(Lick_Events{i}{ii-1},{'Go Success (LP2)','Go Failure (LP2)'})
                idx_2(ii) = true;
            elseif strcmp(Lick_Events{i}{ii},'No-Go Success (LP1)') && ...
                    ismember(Lick_Events{i}{ii-1},{'No-Go Success (LP1)','No-Go Failure (LP1), Noise triggered'})
                idx_2(ii) = true;
            elseif strcmp(Lick_Events{i}{ii},'No-Go Success (LP2)') && ...
                    ismember(Lick_Events{i}{ii-1},{'No-Go Success (LP2)','No-Go Failure (LP2), Noise triggered'})
                idx_2(ii) = true;
            end
        end
        Events{i}(idx(idx_2)) = [];
        Timestamps{i}(idx(idx_2)) = [];
    end
end

% Check if user wants to include all sessions
answer = questdlg('Would you like to include all sessions?', ...
    'Number of Sessions', ...
    'Yes','No','Yes');

switch answer
    case 'Yes'
        user_sessions = 1:numel(Sessions);
        save_flag = true;
    case 'No'
        user_sessions = listdlg('ListString',fileparts(fileparts(Sessions)),...
            'PromptString','Choose sessions to analyze.',...
            'ListSize',[600 350]);
        Timestamps = Timestamps(user_sessions);
        Events = Events(user_sessions);
        Sessions = Sessions(user_sessions);
        save_flag = false;
    otherwise
        % Return if no answer was picked
        return
end

% Defines the ticklabels for following plots
if numel(Sessions) > 100
    labels = cell(1,numel(Sessions));
    for i=10:10:numel(Sessions)
        labels{i} = user_sessions(i);
    end
elseif numel(Sessions) > 50
    labels = cell(1,numel(Sessions));
    for i=5:5:numel(Sessions)
        labels{i} = user_sessions(i);
    end
elseif numel(Sessions) > 25
    labels = cell(1,numel(Sessions));
    for i=2:2:numel(Sessions)
        labels{i} = user_sessions(i);
    end
else
    labels = user_sessions(1):user_sessions(end);
end

% Load the Bodyweight file for later plotting
bwDir = dir(fullfile(startPath,'Bodyweight*.xlsx'));
if ~isempty(bwDir)
    bodyweight = readmatrix(fullfile(startPath,bwDir.name),'Range','C:E');
    idx = ismember(bodyweight(:,1),user_sessions);
    bodyweight = bodyweight(idx,:);
    bodyweight(:,1) = 1:size(bodyweight,1);
end

animalData.cohort(cohort_num).animal(animal_num).Lick_Events = Lick_Events';
animalData.cohort(cohort_num).animal(animal_num).session_names = Sessions;
animalData.cohort(cohort_num).animal(animal_num).bodyweight = bodyweight(:,2:3);
animalData.cohort(cohort_num).animal(animal_num).animalName = animalName;

% Assigns values representing the stages to the sessions
stage_sessionCount = stageCount(Sessions);

% Looks for inconsistencies in the event lists
Sessions_artefacts = ses_artefacts(Sessions,Events,animalName);

%% Count Individual Events

% Define event types in a session
ngf = {'No-Go Failure (LP1)', 'No-Go Failure (LP2)'}; %first lick on no-go trial
ngrl = {'Repeated Lick (LP1), Noise triggered',...
    'Repeated Lick (LP2), Noise triggered',...
    'Repeated Lick (LP1), Timeout',...
    'Repeated Lick (LP2), Timeout'}; %continued lick on go trial, after reward was already triggered

gf = {'Go Failure (LP1)', 'Go Failure (LP2)'}; %no lick at go trial and break of middle beam (M)
grl = {'Repeated Lick (LP1), No Reward','Repeated Lick (LP2), No Reward'};

% ml = {'Medium Lick (LP1)','Medium Lick (LP2)','Neutral Lick (LP1)','Neutral Lick (LP2)'};
% mnl = {'Medium No Lick (LP1)','Medium No Lick (LP2)',...
%     'Neutral No Lick (LP1)','Neutral No Lick (LP2)'};
ml = {'Medium Lick','Neutral Lick','Diagonal Lick'};
mnl = {'Medium No Lick','Neutral No Lick','Diagonal No Lick'};

gs = {'Go Success (LP1)', 'Go Success (LP2)'}; %lick on go trial
ngs = {'No-Go Success (LP1)', 'No-Go Success (LP2)'}; %no lick on no-go trial and break of middle beam (M)

failure_nogo_first = zeros(1,length(Events));
failure_nogo_repeat = zeros(1,length(Events));
failure_go = zeros(1,length(Events));
failure_go_repeat = zeros(1,length(Events));
medium_lick = zeros(1,length(Events));
medium_nolick = zeros(1,length(Events));
success_go = zeros(1,length(Events));
success_nogo = zeros(1,length(Events));
for i=1:length(Events)
    failure_nogo_first(i) = sum(contains(Events{i},ngf));
    failure_nogo_repeat(i) = sum(contains(Events{i},ngrl));
    % For Go Failures this is neccessary, otherwise it is confused with No-Go Failures
    failure_go(i) = sum(strcmp(Events{i},gf{1}))+sum(strcmp(Events{i},gf{2}));
    failure_go_repeat(i) = sum(contains(Events{i},grl));
    
    medium_lick(i) = sum(contains(Events{i},ml));
    medium_nolick(i) = sum(contains(Events{i},mnl));
    
    % For Go Success this is neccessary, otherwise it is confused with No-Go Success
    success_go(i) = sum(strcmp(Events{i},gs{1}))+sum(strcmp(Events{i},gs{2}));
    success_nogo(i) = sum(contains(Events{i},ngs));
end

f = figure(16);
f.Name = 'IndivEvents';
hold on
plot(success_go,'s-','Color','#70db70')
plot(failure_go,'s-','Color','#ff4d4d')
plot(success_nogo,'s-','Color','#248f24')
plot(failure_nogo_first,'s-','Color','#b30000')
plot(medium_lick,'s-','Color','#1a1aff')
plot(medium_nolick,'s-','Color','#1ad1ff')
ylim([0 max(ylim)])

colorplots(0,max(ylim),Sessions)

plot(success_go,'s-','Color','#70db70')
plot(failure_go,'s-','Color','#ff4d4d')
plot(success_nogo,'s-','Color','#248f24')
plot(failure_nogo_first,'s-','Color','#b30000')
plot(medium_lick,'s-','Color','#1a1aff')
plot(medium_nolick,'s-','Color','#1ad1ff')

set(gca,'box','off')
set(gca, 'Layer', 'top')

hold off
xlim([1 inf])
xticks(1:numel(Events))
xticklabels(labels)
legend('Go trial success','Go trial failure','No-Go trial success','No-Go trial failure',...
    'Indifferent state lick','Indifferent state no lick','Location','northwest')
xlabel('Sessions')
ylabel('Counts')
title({animalName;'Number of individual events'})

fprintf('\n%d Go-Successes in stage 1\n',sum(success_go(stage_sessionCount==1)))

%% Individual Events Normalized Percentage

failure_nogo_first_rel = zeros(1,length(Events));
failure_go_rel = zeros(1,length(Events));
medium_lick_rel = zeros(1,length(Events));
medium_nolick_rel = zeros(1,length(Events));
success_go_rel = zeros(1,length(Events));
success_nogo_rel = zeros(1,length(Events));
for i=1:numel(Events)
    failure_nogo_first_rel(i)=failure_nogo_first(i)/(failure_nogo_first(i)+...
        failure_go(i)+success_go(i)+success_nogo(i)+medium_lick(i)+medium_nolick(i))*100;
    failure_go_rel(i)=failure_go(i)/(failure_nogo_first(i)+...
        failure_go(i)+success_go(i)+success_nogo(i)+medium_lick(i)+medium_nolick(i))*100;
    
    medium_lick_rel(i)=medium_lick(i)/(failure_nogo_first(i)+...
        failure_go(i)+success_go(i)+success_nogo(i)+medium_lick(i)+medium_nolick(i))*100;
    medium_nolick_rel(i)=medium_nolick(i)/(failure_nogo_first(i)+...
        failure_go(i)+success_go(i)+success_nogo(i)+medium_lick(i)+medium_nolick(i))*100;
    
    success_go_rel(i)=success_go(i)/(failure_nogo_first(i)+...
        failure_go(i)+success_go(i)+success_nogo(i)+medium_lick(i)+medium_nolick(i))*100;
    success_nogo_rel(i)=success_nogo(i)/(failure_nogo_first(i)+...
        failure_go(i)+success_go(i)+success_nogo(i)+medium_lick(i)+medium_nolick(i))*100;
end

f = figure(15);
f.Name = 'NormIndivEvents';
hold on
plot(success_go_rel,'s-','Color','#70db70')
plot(failure_go_rel,'s-','Color','#ff4d4d')
plot(success_nogo_rel,'s-','Color','#248f24')
plot(failure_nogo_first_rel,'s-','Color','#b30000')
plot(medium_lick_rel,'s-','Color','#1a1aff')
plot(medium_nolick_rel,'s-','Color','#1ad1ff')

colorplots(0,100,Sessions)

plot(success_go_rel,'s-','Color','#70db70')
plot(failure_go_rel,'s-','Color','#ff4d4d')
plot(success_nogo_rel,'s-','Color','#248f24')
plot(failure_nogo_first_rel,'s-','Color','#b30000')
plot(medium_lick_rel,'s-','Color','#1a1aff')
plot(medium_nolick_rel,'s-','Color','#1ad1ff')

set(gca,'box','off')
set(gca, 'Layer', 'top')

hold off
axis([1 inf 0 100])
xticks(1:numel(Events))
xticklabels(labels)
legend('Go trial success','Go trial failure','No-Go trial success','No-Go trial failure',...
    'Indifferent state lick','Indifferent state no lick','Location','northwest')
xlabel('Sessions')
ylabel('Trials normalized [%]')
title({animalName;'Normalized percentage of individual  events'})

%% Bar Graphs of State Presentation

f = figure(14);
f.Name = 'BarIndivEvents';
b = bar((1:numel(user_sessions)),[success_go_rel' failure_go_rel' success_nogo_rel' failure_nogo_first_rel'...
    medium_lick_rel' medium_nolick_rel'],...
    0.5,'stacked');
b(1).FaceColor = '#70db70';
b(2).FaceColor = '#ff4d4d';
b(3).FaceColor = '#248f24';
b(4).FaceColor = '#b30000';
b(5).FaceColor = '#c2c2d6';
b(6).FaceColor = '#8585ad';

set(gca,'box','off')
set(gca, 'Layer', 'top')

axis([0.5 numel(Events)+0.5 0 100])
xticks(1:numel(Events))
xticklabels(labels)
order = get(gca, 'Children');
legend(order(1:end),'Indifferent state no lick','Indifferent state lick',...
    'No-Go trial failure','No-Go trial success','Go trial failure',...
    'Go trial success','Location','southeast')
xlabel('Sessions')
ylabel('Trials normalized [%]')
title({animalName;'Bar graph with proportion of individual events'})

%% Count Success Rate for Go-trials Only (normalized)

% Creates an index, as: b/(b+c)
% Should reflect the learning effect of animals
success_rates_go  = zeros(1,length(Events));
for i = 1:numel(Events)
    success_rates_go(i) = success_go(i)/(success_go(i) + failure_go(i));
end

animalData.cohort(cohort_num).animal(animal_num).gogo_suc = success_rates_go';

% % Linear fit with R squared value
% [p, S] = polyfit(1:length(success_rates_go), success_rates_go, 1);
% R_squared = 1 - (S.normr/norm(success_rates_go - mean(success_rates_go)))^2;
% y1 = polyval(p,1:length(success_rates_go));

f = figure(6);
f.Name = 'SucRateGo';
plot(success_rates_go,'ko:')
hold on
% plot (y1, 'k--')

colorplots(0,1,Sessions)

plot(success_rates_go,'ko:')
% plot (y1, 'k--')

set(gca,'box','off')
set(gca, 'Layer', 'top')

hold off

axis([1 inf 0.0 1.0])
xticks(1:numel(Events))
xticklabels(labels)
% legend('Data',sprintf('Linear Fit (R^2=%.3f)',R_squared), 'Location','northwest')
xlabel('Sessions')
ylabel('Success rate')
title({animalName;'Success rate for Go-trials only'})

%% Count Success Rate for No-Go Trials Only (normalized)

% Creates an index, as: b/(b+c)
% Should reflect the learning effect of animals
success_rates_nogo = zeros(1,numel(Events));
for i = 1:numel(Events)
    success_rates_nogo(i) = success_nogo(i)/(success_nogo(i) + failure_nogo_first(i));
end

animalData.cohort(cohort_num).animal(animal_num).nogo_suc = success_rates_nogo';

% % Linear fit with R squared value
% idx = isnan(success_rates_nogo);
% [p, S] = polyfit(find(~idx),success_rates_nogo(~idx),1);
% R_squared = 1 - (S.normr/norm(success_rates_nogo(~idx) - mean(success_rates_nogo(~idx))))^2;
% y1 = polyval(p,find(~idx));

f = figure(7);
f.Name = 'SucRateNoGo';
hold on
yyaxis left
xlabel('Sessions')
ylabel('Success rate')
ylim([0 1.0])
xlim([1 inf])
p(1) = plot(success_rates_nogo,'ko:');
% plot(find(~idx),  y1, 'k--')

colorplots(0,1,Sessions)

p(1) = plot(success_rates_nogo,'ko:');
% plot(find(~idx),  y1, 'k--')

set(gca,'box','off')
set(gca, 'Layer', 'top')

yyaxis right
ylabel('Body weight [%]')
ylim([80 110])
ax = gca;
ax.YColor = '#ff661a';

p(2) = plot(bodyweight(:,1),bodyweight(:,3),'Color','#ff661a');

if min(bodyweight(:,3))<80 && max(bodyweight(:,3))>110
    ylim([min(bodyweight(:,3)) max(bodyweight(:,3))])
elseif min(bodyweight(:,3))<80
    ylim([min(bodyweight(:,3)) 110])
elseif max(bodyweight(:,3))>110
    ylim([80 max(bodyweight(:,3))])
end

hold off
xticks(1:numel(Events))
xticklabels(labels)
% legend('Data',sprintf('Linear Fit (R^2=%.3f)',R_squared), 'Location','northwest')
legend([p(1) p(2)],'Data', 'Bodyweight', 'Location','northwest')
title({animalName;'Success rate for No-Go-trials only'})

%% Count Overall Success Rate (normalized)

Bevent = 'Failure';
Revent = 'Success'; % rewarded lick events relative event

% Creates an index, as: b/(b+c)
nevents = zeros(1,numel(Events));
for i=1:numel(Events)
    nevents(i)=sum(contains(Events{i},Revent))/...
        (sum(contains(Events{i},Bevent)) + sum(contains(Events{i},Revent)));
end

% d prime values reflect the learningh sensitivity
dprime_values = zeros(1,numel(Sessions));
cvalues = zeros(1,numel(Sessions));
dprime_val = 1.65;
for i=1:numel(Sessions)
    [dprime_values(i), cvalues(i)] = dprime(success_rates_go(i),(1-success_rates_nogo(i)),...
        (success_go(i)+failure_go(i)),(success_nogo(i)+failure_nogo_first(i)));
end
learn_sessions = find(dprime_values>dprime_val); % d' cutoff of 1.65

% % Linear fit with R squared value
% [p, S] = polyfit(1:length(nevents), nevents, 1);
% R_squared = 1 - (S.normr/norm(nevents - mean(nevents)))^2;
% y1 = polyval(p,1:length(nevents));

f = figure(5);
f.Name = 'SucRateTotal';
ax1 = axes('Position',[0.1 0.1 0.7 0.8]);

plot(nevents,'ko:')
hold on
% plot(y1, 'k--') % Linear fit doesn't work over the course of stages

colorplots(0,1,Sessions)

l(1) = plot(nevents,'ko:');
% l(2) = plot (y1, 'k--');

animalData.cohort(cohort_num).animal(animal_num).overall_suc = nevents';

if ~isempty(learn_sessions)
    l(3) = plot(learn_sessions,nevents(learn_sessions),'*m');
    plot(learn_sessions,nevents(learn_sessions),'*m')
end

set(gca,'box','off')
set(gca, 'Layer', 'top')

axis([1 inf 0.0 1.0])
xticks(1:numel(Events))
xticklabels(labels)

if ~isempty(learn_sessions)
    legend([l(1) l(3)],'Data','Sufficient d''','Location','northwest')
end
% legend(l,'Data',sprintf('Linear Fit (R^2=%.3f)',R_squared),...
%     'Sufficient d''','Location','northwest')
xlabel('Sessions')
ylabel('Success rate')
title({animalName;'Overall Success-rate'})

h = axes('Position',[0 0 1 1],'Visible','off');
descript = getStageDescription(cohort_num, str2double(animalName(2:end)));
text(.81,.45,descript,'FontSize',8.5)

hold off

%% Plots the d' Values of All Sessions

f = figure(4);
f.Name = 'dprimeSes';

if sum(stage_sessionCount ~= 1) ~= 0
    
    % Exclude stage 1 from analysis as it doesn't afford two choices yet
    plot(dprime_values(stage_sessionCount ~= 1),'ko:')
    hold on
    zero_line = zeros(1,sum(stage_sessionCount ~= 1));
    plot(zero_line,'Color','#666666')
    dprime_line = dprime_val*ones(1,sum(stage_sessionCount ~= 1));
    plot(dprime_line,'--','Color','#666666');
    
    colorplots(min(ylim),max(ylim),Sessions(stage_sessionCount ~= 1))
    
    plot(dprime_values(stage_sessionCount ~= 1),'ko:')
    plot(zero_line,'Color','#666666')
    plot(dprime_line,'--','Color','#666666');
    
    animalData.cohort(cohort_num).animal(animal_num).dvalues_sessions = dprime_values';
    animalData.cohort(cohort_num).animal(animal_num).cvalues_sessions = cvalues';
    
    axis tight
    set(gca,'box','off')
    set(gca, 'Layer', 'top')
    
    %     xlim([1 sum(stage_sessionCount ~= 1)])
    xlim([1 inf])
    xticks(1:sum(stage_sessionCount ~= 1))
    xticklabels(labels(stage_sessionCount ~= 1))
    xlabel('Sessions')
    ylabel('d'' value')
    title({animalName;'d'' Values of each Session'})
    hold off
else
    title({animalName;'d'' Values of each Session'})
    text(0.5,0.5,'No sessions in stage 2 yet.','FontSize',16,'Units','normalized',...
        'HorizontalAlignment','center')
    axis off
end

%% Calculates the d' Value for a Given Trial and its 200 Preceeding Trials

% This function counts the individual number of trials per stage
[stage_trialcount, stage2_trialcount] = count_stagetrials(Sessions, Lick_Events);

animalData.cohort(cohort_num).animal(animal_num).stage2_trialcount = stage2_trialcount;
animalData.cohort(cohort_num).animal(animal_num).stage_sessionCount = stage_sessionCount;

f = figure(3);
f.Name = 'dprimeTrial';

stage2 = [stage2_trialcount{1,:}]==2;

if sum(stage_sessionCount ~= 1)~=0 && any(stage2) && stage2_trialcount{3,stage2}>200
    % Start 200 trials after stage beginn, as the d' is averaged
    % over the past 200 trials.
    trialnum = 200;

    % This function checks how many log fits should be made
    fit = checklogfit(cohort_num, str2double(animalName(2:end)), stage2_trialcount);
    fit_names = fieldnames(fit);
    
    clear dvalues_trials
    a = find(stage_sessionCount==2,1);
    if isempty(a)
        All_lick_events = vertcat(Lick_Events{:});
    else
        All_lick_events = vertcat(Lick_Events{a:end});
    end
    dvalues_trials = zeros(1,numel(All_lick_events));
    cvalues_trials = zeros(1,numel(All_lick_events));
    for i = trialnum+1:numel(All_lick_events)
        k = i - trialnum;
        suc_go = sum(strncmpi('Go Success',All_lick_events(k:i),8));
        fail_go = sum(strncmpi('Go Failure',All_lick_events(k:i),8));
        
        suc_nogo = sum(strncmpi('No-Go Success',All_lick_events(k:i),8));
        fail_nogo = sum(strncmpi('No-Go Failure',All_lick_events(k:i),8));
        
        go_success_rate = suc_go/(suc_go+fail_go);
        nogo_success_rate = suc_nogo/(suc_nogo+fail_nogo);
        [new_dvalue, new_cvalue] = dprime(go_success_rate,1-nogo_success_rate,...
            (suc_go+fail_go), (suc_nogo+fail_nogo));
        if i == trialnum+1
            dvalues_trials(1:trialnum+1) = new_dvalue;
            cvalues_trials(1:trialnum+1) = new_cvalue;
        else
            dvalues_trials(i) = new_dvalue;
            cvalues_trials(i) = new_cvalue;
        end
    end
    
    clear suc_go fail_go suc_nogo fail_nogo
    
    dprime_line = dprime_val*ones(1,length(dvalues_trials));
    zero_line = zeros(1,length(dvalues_trials));
    
    plot(dvalues_trials, 'Color', '#0072BD')
    plot(cvalues_trials, 'Color', '#ff66ff')
    hold on
    
    colorplots_dprime(max([dvalues_trials cvalues_trials]),min([dvalues_trials cvalues_trials]),...
        a,numel(Events),Lick_Events,stage2_trialcount)
    
    p1 = plot(dvalues_trials, 'Color', '#0072BD');
    p2 = plot(cvalues_trials, 'Color', '#ff66ff');
    
    plot(dprime_line,'--','Color','#00b300')
    plot(zero_line,'Color','#666666')
    
    set(gca,'box','off')
    set(gca, 'Layer', 'top')
    
    animalData.cohort(cohort_num).animal(animal_num).dvalues_trials = dvalues_trials';
    animalData.cohort(cohort_num).animal(animal_num).cvalues_trials = cvalues_trials';
    
    intersec = nan(1,sum(~structfun(@isempty, fit)));
    for i = 1:sum(~structfun(@isempty, fit))
        if i == 1
            yval_rev = dvalues_trials(stage2_trialcount{2,fit.(fit_names{i})}:...
                stage2_trialcount{3,fit.(fit_names{i})});
            %             [~, trialnum] = min(yval_rev);
            yval_rev = yval_rev(trialnum+1:end);
            offset = min(yval_rev);
            yval = yval_rev - offset;
            
            x = 1:1:numel(yval);
            x = x + (stage2_trialcount{2,fit.(fit_names{i})}+trialnum-1);
            %             x = stage2_trialcount{2,fit.(fit_names{i})}:stage2_trialcount{3,fit.(fit_names{i})};
            
            Qpre_fit = [];
            try
                % fit_logistic
                [params]=sigm_fit(x,yval,[],[],0);
                Qpre_fit = params(1) + (params(2) - params(1))./ (1 + 10.^((params(3) - x) * params(4)));
                Qpre_fit = Qpre_fit + offset;
                %             yval = yval_rev - yval_rev(1);
                %             [Qpre_fit, ~] = fit_logistic(x', yval');
                %             Qpre_fit = Qpre_fit + yval_rev(1);
                %             offset = yval(1) - yval_rev(1);
                %             Qpre_fit = Qpre_fit - offset;
                
                p3 = plot(x,Qpre_fit, 'Color', '#33ffd6','LineWidth',2);
                
                % Total trial count for log fit intersection
                if all(Qpre_fit>dprime_val)
                    intersec(i) = stage2_trialcount{2,fit.(fit_names{i})};
                elseif params(2) > params(1) && params(4) > 0 % increasing sigmoidal
                    intersec(i) = find(Qpre_fit'>dprime_val,1)+stage2_trialcount{2,fit.(fit_names{i})}+trialnum;
                elseif params(1) > params(2) && params(4) < 0 % increasing sigmoidal
                    intersec(i) = find(Qpre_fit'>dprime_val,1)+stage2_trialcount{2,fit.(fit_names{i})}+trialnum;
                else % decreasing sigmoidal
                    intersec(i) = NaN;
                end    
                trials_to_nextstage = stage2_trialcount{3,fit.(fit_names{i})} - intersec(i);
                
                animalData.cohort(cohort_num).animal(animal_num).slope_initial = params(4);
                animalData.cohort(cohort_num).animal(animal_num).intersec_initial = intersec(i);
            catch
                yval_rev = dvalues_trials(stage2_trialcount{2,fit.(fit_names{i})}:...
                    stage2_trialcount{3,fit.(fit_names{i})});
                if  all(yval_rev>dprime_val)
                    trials_to_nextstage = numel(yval_rev);
                else
                    trials_to_nextstage = 0;
                end
            end
            ses_over_thres = dprime_values(stage_sessionCount==stage2_trialcount{1,fit.(fit_names{i})}) > dprime_val;
            bool = true;
            ses_count = 0;
            while bool && ses_count < numel(ses_over_thres)
                if ses_over_thres(end-ses_count)
                    ses_count = ses_count+1;
                else
                    bool = false;
                end
            end
            fprintf('\nSessions with sufficient performance at the end of initial learning stage: %d',...
                ses_count)
            fprintf('\nTrials with sufficient performance at the end of initial learning stage: %d\n\n',...
                trials_to_nextstage)
            
            animalData.cohort(cohort_num).animal(animal_num).dprime_logfit = Qpre_fit';
            
        else
            yval_rev = dvalues_trials(stage2_trialcount{2,fit.(fit_names{i})}:...
                stage2_trialcount{3,fit.(fit_names{i})}); 
            %             [~, trialnum] = min(yval_rev);
            yval_rev = yval_rev(trialnum+1:end);
            offset = min(yval_rev);
            yval = yval_rev - offset;
            
            x = 1:1:numel(yval);
            x = x + (stage2_trialcount{2,fit.(fit_names{i})}+trialnum-1);
            %             x = stage2_trialcount{2,fit.(fit_names{i})}:stage2_trialcount{3,fit.(fit_names{i})};
            
            % fit_logistic
            try
                [params]=sigm_fit(x,yval,[],[],0);
                Qpre_fit = params(1) + (params(2) - params(1))./ (1 + 10.^((params(3) - x) * params(4)));
                Qpre_fit = Qpre_fit + offset;
                
                plot(x,Qpre_fit, 'Color', '#33ffd6','LineWidth',2);
                
                %                 [Qpre_fit, ~] = fit_logistic(x', yval');
                %                 Qpre_fit = Qpre_fit + yval_rev(1);
                %                 offset = yval(1) - yval_rev(1);
                %                 Qpre_fit = Qpre_fit - offset;
                
                % Total trial count for log fit intersection
                if all(Qpre_fit>dprime_val)
                    intersec(i) = stage2_trialcount{2,fit.(fit_names{i})};
                elseif params(2) > params(1) && params(4) > 0 % increasing sigmoidal
                    intersec(i) = find(Qpre_fit'>dprime_val,1)+stage2_trialcount{2,fit.(fit_names{i})}+trialnum;
                elseif params(1) > params(2) && params(4) < 0 % increasing sigmoidal
                    intersec(i) = find(Qpre_fit'>dprime_val,1)+stage2_trialcount{2,fit.(fit_names{i})}+trialnum;
                else % decreasing sigmoidal
                    intersec(i) = NaN;
                end           
                trials_to_nextstage = stage2_trialcount{3,fit.(fit_names{i})} - intersec(i);
                
                if i==2
                    animalData.cohort(cohort_num).animal(animal_num).slope_second = params(4);
                    animalData.cohort(cohort_num).animal(animal_num).intersec_second = intersec(i)-stage2_trialcount{2,fit.(fit_names{i})};
                end
            catch
                yval_rev = dvalues_trials(stage2_trialcount{2,fit.(fit_names{i})}:...
                    stage2_trialcount{3,fit.(fit_names{i})});
                if  all(yval_rev>dprime_val)
                    trials_to_nextstage = numel(yval_rev);
                else
                    trials_to_nextstage = 0;
                end
            end
            
%             if isempty(trials_to_nextstage)
%                 trials_to_nextstage = 0;
%             end
            ses_over_thres = dprime_values(stage_sessionCount==stage2_trialcount{1,fit.(fit_names{i})}) > dprime_val;
            bool = true;
            ses_count = 0;
            while bool && ses_count < numel(ses_over_thres)
                if ses_over_thres(end-ses_count)
                    ses_count = ses_count+1;
                else
                    bool = false;
                end
            end
            fprintf('\nSessions with sufficient performance at the end of %d. fitted stage: %d',...
                i,ses_count)
            fprintf('\nTrials with sufficient performance at the end of %d. fitted stage: %d\n\n',...
                i,trials_to_nextstage)
        end
    end
    
    if dvalues_trials(end) < dprime_val || dprime_values(end) < dprime_val
        trialsBelow = numel(dvalues_trials)-find(dvalues_trials>dprime_val,1,'last');
        sessionsBelow = numel(dprime_values)-find(dprime_values>dprime_val,1,'last');
        if isempty(trialsBelow)
            fprintf('\nTrials below threshold since last threshold crossing in this stage: %d\n',numel(dvalues_trials))
        elseif trialsBelow > stage2_trialcount{end,end}
            fprintf('\nTrials below threshold since last threshold crossing in this stage: %d\n',stage2_trialcount{end,end})
        else
            fprintf('\nTrials below threshold since last threshold crossing in this stage: %d\n',trialsBelow)
        end
        if isempty(sessionsBelow) 
            fprintf('\nSessions below threshold since last threshold crossing in this stage: %d\n',sum(~isnan(dprime_values)))
        elseif sessionsBelow > sum(stage_sessionCount==stage_sessionCount(end))
            fprintf('\nSessions below threshold since last threshold crossing in this stage: %d\n',sum(stage_sessionCount==stage_sessionCount(end)))
        else
            fprintf('\nSessions below threshold since last threshold crossing in this stage: %d\n',sessionsBelow)
        end
    end
    
    axis([trialnum numel(All_lick_events) min([dvalues_trials cvalues_trials]) max([dvalues_trials cvalues_trials])])
    % Only plot legend, if the logistic fit was created
    if exist('p3','var')
        legend([p1 p2 p3],{'d'' values','bias / criterion', 'Logistic Fit'},'Location','Northwest')
    else
        legend([p1 p2],{'d'' values','bias / criterion'},'Location','Northwest')
    end
    
    xlabel('Trials')
    ylabel(sprintf('d'' for %d Trials',trialnum))
    % Learning speed is defined as trials after which the log fit d' > 1.65
    title({animalName;['d'' over trials',sprintf('\nLearning speed for %d. rule set: %d trials',...
        [1:sum(~structfun(@isempty, fit));intersec - cellfun(@(x) stage2_trialcount{2,fit.(x)}, fit_names(1:sum(~structfun(@isempty, fit))))'])]})
    hold off
    
elseif any(stage2)    
    title({animalName;'d'' over trials'})
    text(0.5,0.5,{'Not enough trials in stage 2.';...
        sprintf('Minimum of 200 trials - Currently at %d trials',...
        stage2_trialcount{3,2})},'FontSize',16,'Units','normalized',...
        'HorizontalAlignment','center')
    axis off
else
    title({animalName;'d'' over trials'})
    text(0.5,0.5,{'Not enough trials in stage 2.';...
        'Minimum of 200 trials - Currently 0 trials'},...
        'FontSize',16,'Units','normalized',...
        'HorizontalAlignment','center')
    axis off
    
end

%% Count the Share of Go Successes from all Lick Events

% Creates an index, as: b/(b+c)
% Should reflect the learning effect of animals
nevents=zeros(1,numel(Events));
for i=1:numel(Events)
    nevents(i)=success_go(i)/(success_go(i)+failure_nogo_first(i)+medium_lick(i));
end

% Linear fit with R squared value
[p, S] = polyfit(1:length(nevents), nevents, 1);
R_squared = 1 - (S.normr/norm(nevents - mean(nevents)))^2;
y1 = polyval(p,1:length(nevents));

f = figure(12);
f.Name = 'GoSucShare';
hold on
plot(nevents,'ko:')
plot (y1, 'k--')

colorplots(0,1,Sessions)

plot(nevents,'ko:')
plot (y1, 'k--')

set(gca,'box','off')
set(gca, 'Layer', 'top')

hold off

axis([1 inf 0.0 1.0])
xticks(1:numel(Events))
xticklabels(labels)
legend('Data',sprintf('Linear Fit (R^2=%.3f)',R_squared), 'Location','northwest')
xlabel('Sessions')
ylabel('Share')
title({animalName;'Share of Go-trials in all licking events'})

%% Count Lick Rate for All States

% Creates an index, as: b/(b+c)
% Should reflect the learning effect of animals
nevents = zeros(1,numel(Events));
oevents = zeros(1,numel(Events));
pevents = zeros(1,numel(Events));
for i = 1:numel(Events)
    nevents(i) = medium_lick(i)/(medium_nolick(i) + medium_lick(i));
    oevents(i) = success_go(i)/(success_go(i) + failure_go(i));
    pevents(i) = failure_nogo_first(i)/(success_nogo(i) + failure_nogo_first(i));
end

animalData.cohort(cohort_num).animal(animal_num).medium_lick = nevents';

% Linear fit with R squared value
idx = isnan(nevents);
[p, S] = polyfit(find(~idx),nevents(~idx),1);
R_squared = 1 - (S.normr/norm(nevents(~idx) - mean(nevents(~idx))))^2;
y1 = polyval(p,find(~idx));

f = figure(2);
f.Name = 'LickRates';
hold on
plot(nevents,'ko:');
plot(find(~idx),y1,'k--');
plot(oevents,'o:','Color','#248f24');
plot(pevents,'o:','Color','#b30000');

colorplots(0,1,Sessions)

q1 = plot(nevents,'ko:');
q2 = plot(find(~idx),y1,'k--');
q3 = plot(oevents,'o:','Color','#248f24');
q3.Color(4) = 0.3;
q3.MarkerEdgeColor(4) = 0.3;
q4 = plot(pevents,'o:','Color','#b30000');
q4.Color(4) = 0.3;
q4.MarkerEdgeColor(4) = 0.3;

set(gca,'box','off')
set(gca, 'Layer', 'top')

hold off
axis([1 inf 0.0 1.0])
xticks(1:numel(Events))
xticklabels(labels)

% Neccessary, because otherwise empty arrays (e.g. linear fit) will have a legend entry
all_plots = {q1 q2 q3 q4};
data_plot = ~cellfun(@isempty, all_plots);
data_legend = {'Lick rate Indifferent State',sprintf('Linear Fit (R^2=%.3f)',R_squared),...
    'Lick rate Go State','Lick rate No-Go State'};
legend([all_plots{data_plot}],data_legend(data_plot),'Location','northwest')
% legend([p1 p2],'Lick rate Go State','Lick rate No-Go State')
xlabel('Sessions')
ylabel('Lick rate')
title({animalName;'Lick rate for different states'})


%% Count Number of Trials

% Defined by the number of Middle Point crossings

nevents = zeros(1,numel(Events));
for i=1:numel(Events)
    nevents(i)=sum(contains(Events{i},'Middle point'));
end

animalData.cohort(cohort_num).animal(animal_num).trial_num = nevents';

% % Linear fit with R squared value
% [p, S] = polyfit(1:length(nevents), nevents, 1);
% R_squared = 1 - (S.normr/norm(nevents - mean(nevents)))^2;
% y1 = polyval(p,1:length(nevents));

f = figure(1);
f.Name = 'TrialNum';
hold on
p(1) = plot(nevents, 'ko:');
% plot (y1, 'k--')

colorplots(0,max(ylim),Sessions)

p(1) = plot(nevents, 'ko:');
% plot (y1, 'k--')

set(gca,'box','off')
set(gca, 'Layer', 'top')

yyaxis left
ylabel('Counts')
ylim([0 inf])

yyaxis right
ylabel('Body weight [%]')
xlim([1 inf])
% Reverse the y-axis
ax = gca;
ax.YColor = '#ff661a';
ax.YLim = [80 110];
ax.YDir = 'reverse';

p(2) = plot(bodyweight(:,1),bodyweight(:,3),'Color','#ff661a');

if min(bodyweight(:,3))<80 && max(bodyweight(:,3))>110
    ax.YLim = [min(bodyweight(:,3)) max(bodyweight(:,3))];
elseif min(bodyweight(:,3))<80
    ax.YLim = [min(bodyweight(:,3)) 110];
elseif max(bodyweight(:,3))>110
    ax.YLim = [80 max(bodyweight(:,3))];
end

hold off
xticks(1:numel(Events))
xticklabels(labels)
% legend('Data',sprintf('Linear Fit (R^2=%.3f)',R_squared), 'Location','northwest')
legend([p(1) p(2)],'Data','Bodyweight', 'Location','northwest')
xlabel('Sessions')
title({animalName; 'Trials'})

%% Average Time Needed, to Return from Lickport to Middle Point

diff_success_median = zeros(1,numel(Events));
diff_failure_median = zeros(1,numel(Events));
diff_medium_median = zeros(1,numel(Events));

for i=1:numel(Events)
    diff = [];
    
    middle_events_idx = find(contains(Events{i}, 'Middle point'));
    % For Go Success this is neccessary, otherwise it is confused with No-Go Success
    success_licks_idx = sort(vertcat(find(strcmp(Events{i},gs{1})),...
        find(strcmp(Events{i},gs{2}))));
    noise_licks_idx = find(contains(Events{i},'No-Go Failure') & contains(Events{i},'Noise triggered'));
    medium_licks_idx = find(contains(Events{i}, ml)); % Looks for Medium licks
    
    diff_success = NaN(1,numel(success_licks_idx));
    for ii = 1:length(success_licks_idx)
        j = find(middle_events_idx > success_licks_idx(ii),1);
        if ~isempty(j)
            diff = Timestamps{i}(middle_events_idx(j))- Timestamps{i}(success_licks_idx(ii));
            diff_success(ii) = diff;
        end
    end
    diff_success_median(i) = median(diff_success,'omitnan')/1000; % Time in sec
    
    diff_failure = NaN(1,numel(noise_licks_idx));
    for ii = 1:length(noise_licks_idx)
        j = find(middle_events_idx > noise_licks_idx(ii),1);
        if ~isempty(j)
            diff = Timestamps{i}(middle_events_idx(j))- Timestamps{i}(noise_licks_idx(ii));
            diff_failure(ii) = diff;
        end
    end
    diff_failure_median(i) = median(diff_failure,'omitnan')/1000; % Time in sec
    
    diff_medium = NaN(1,numel(medium_licks_idx));
    for ii = 1:length(medium_licks_idx)
        j = find(middle_events_idx > medium_licks_idx(ii),1);
        if ~isempty(j)
            diff = Timestamps{i}(middle_events_idx(j))- Timestamps{i}(medium_licks_idx(ii));
            diff_medium(ii) = diff;
        end
    end
    diff_medium_median(i) = median(diff_medium,'omitnan')/1000; % Time in sec
end

f = figure(13);
f.Name = 'LP2MP';
b = bar((1:numel(user_sessions)),[diff_success_median', diff_failure_median', diff_medium_median']);
b(1).FaceColor = '#b3ffb3';
b(2).FaceColor = '#ffc6b3';
b(3).FaceColor = '#ffffb3';

set(gca,'box','off')
set(gca, 'Layer', 'top')

% max_y = max([prctile(diff_success_median,99), prctile(diff_failure_median,99), prctile(diff_medium_median,99)]);
max_y = max([mean(diff_success_median,'omitnan'), mean(diff_failure_median,'omitnan'), mean(diff_medium_median,'omitnan')]) + ...
    max([std(diff_success_median,'omitnan'), std(diff_failure_median,'omitnan'), std(diff_medium_median,'omitnan')]);

try
    ylim([0 max_y])
catch
end

xticks(1:numel(Events))
xticklabels(labels)
legend('Reward to Middle Point',...
    'Noise to Middle Point',...
    'Neutral Lick to Middle Point','Location','northwest')
xlabel('Sessions')
ylabel('Time[s]')
title({animalName; 'Time needed, to return to Middle point'})

%% Discrimination Time for Go Success

% Time between Drums inner side (later on hopefully whisker touch point)
% and Lickport

nevents = zeros(1,numel(Events));
for i=1:numel(Events)
    idx_drums = find(contains(Events{i}, 'Drums'));
    idx_gosuccess = sort([find(strcmp(Events{i},gs{1}))' find(strcmp(Events{i},gs{2}))']);
    all_gosuccess_port = NaN(1,numel(idx_drums));
    for ii = 1:numel(idx_drums)
        % For every Lickport after a drum trigger, check its index in
        % Eventlist
        if any(find(idx_gosuccess > idx_drums(ii)))
            idx = idx_gosuccess(find(idx_gosuccess > idx_drums(ii), 1));
            % maybe I need another if statement to check for following drum trigger
            if idx < idx_drums(find(idx_drums > idx_drums(ii), 1))
                diff_success = Timestamps{i}(idx) - Timestamps{i}(idx_drums(ii));
                all_gosuccess_port(ii) = diff_success;
            end
        end
    end
    %     nevents(i) = mean(all_gosuccess_port)/1000;
    nevents(i) = median(all_gosuccess_port,'omitnan')/1000;
end

% Plot time intervall between drums and lickport also for No-Go Failures,
% as to compare descision times.

fevents = zeros(1,numel(Events));
for i=1:numel(Events)
    idx_drums = find(contains(Events{i}, 'Drums'));
    idx_nogofailure = find(contains(Events{i}, ngf));
    all_nogofailure_port = NaN(1,numel(idx_drums));
    for ii = 1:numel(idx_drums)
        % For every Lickport after a drum trigger, check its index in
        % Eventlist
        if any(find(idx_nogofailure > idx_drums(ii)))
            idx = idx_nogofailure(find(idx_nogofailure > idx_drums(ii), 1));
            % maybe I need another if statement to check for following drum trigger
            if idx < idx_drums(find(idx_drums > idx_drums(ii), 1))
                diff_failure = Timestamps{i}(idx) - Timestamps{i}(idx_drums(ii));
                all_nogofailure_port(ii) = diff_failure;
            end
        end
    end
    %     fevents(i) = mean(all_nogofailure_port)/1000;
    fevents(i) = median(all_nogofailure_port,'omitnan')/1000;
end

% Linear fit with R squared value
idx = isnan(nevents);
[p1, S] = polyfit(find(~idx),nevents(~idx),1);
R_squared = 1 - (S.normr/norm(nevents(~idx) - mean(nevents(~idx))))^2;
y1 = polyval(p1,find(~idx));

idx2 = isnan(fevents);
[p2, S] = polyfit(find(~idx2),fevents(~idx2),1);
R_squared2 = 1 - (S.normr/norm(fevents(~idx2) - mean(fevents(~idx2))))^2;
y2 = polyval(p2,find(~idx2));

f = figure(11);
f.Name = 'Drum2LP';
hold on
plot(nevents,'s:','Color','#248f24')
plot (find(~idx),y1,'--','Color','#248f24')
plot(fevents,'s:','Color','#b30000')
plot (find(~idx2),y2,'--','Color','#b30000')

colorplots(0,max(ylim),Sessions)

plot(nevents,'s:','Color','#248f24')
plot (find(~idx),y1,'--','Color','#248f24')
plot(fevents,'s:','Color','#b30000')
plot (find(~idx2),y2,'--','Color','#b30000')
hold off

max_y = max([mean(nevents,'omitnan'), mean(fevents,'omitnan')]) + ...
    max([std(nevents,'omitnan'), std(fevents,'omitnan')]);
try
    ylim([0 max_y])
catch
end
set(gca,'box','off')
set(gca, 'Layer', 'top')
xlim([1 inf])
xticks(1:numel(Events))
xticklabels(labels)
legend('Go Discrimination',sprintf('Linear Fit (R^2=%.3f)',R_squared),'No-Go Discrimination',...
    sprintf('Linear Fit (R^2=%.3f)',R_squared2),'Location','northwest')
xlabel('Sessions')
ylabel('Drums - Lickport [in sec]')
title({animalName;'Discrimination time for Go Success and No-Go Failure'})

%% Discrimination Time for No-Go Success

% Time between Drums inner side (later on hopefully whisker touch point) and Middle point

nevents = zeros(1,numel(Events));
for i=1:numel(Events)
    idx_drums = find(contains(Events{i}, 'Drums'));
    idx_nogosuccess = find(contains(Events{i}, ngs));
    all_nogosuccess_middle = NaN(1,numel(idx_drums));
    for ii = 1:numel(idx_drums)
        % For every Middle point after a drum trigger, check its index in
        % Eventlist
        if any(find(idx_nogosuccess > idx_drums(ii)))
            idx = idx_nogosuccess(find(idx_nogosuccess > idx_drums(ii), 1));
            % maybe I need another if statement to check for following drum trigger
            if idx < idx_drums(find(idx_drums > idx_drums(ii), 1))
                diff_nogosuccess = Timestamps{i}(idx) - Timestamps{i}(idx_drums(ii));
                all_nogosuccess_middle(ii) = diff_nogosuccess;
            end
        end
    end
    %     nevents(i) = mean(all_nogosuccess_middle)/1000;
    nevents(i) = median(all_nogosuccess_middle,'omitnan')/1000;
end

% Linear fit with R squared value
idx = isnan(nevents);
[p, S] = polyfit(find(~idx),nevents(~idx),1);
R_squared = 1 - (S.normr/norm(nevents(~idx) - mean(nevents(~idx))))^2;
y1 = polyval(p,find(~idx));

f = figure(10);
f.Name = 'Drum2MP';
hold on
plot(nevents,'ko:')
plot (find(~idx),  y1, 'k--')

colorplots(0,max(ylim),Sessions)

plot(nevents,'ko:')
plot (find(~idx),  y1, 'k--')
hold off

max_y = mean(nevents,'omitnan') + std(nevents,'omitnan');
if ~isnan(max_y)
    ylim([0 max_y])
else
    ylim([0 inf])
end

set(gca,'box','off')
set(gca, 'Layer', 'top')
xlim([1 inf])
xticks(1:numel(Events))
xticklabels(labels)
legend('Data',sprintf('Linear Fit (R^2=%.3f)',R_squared), 'Location','northwest')
xlabel('Sessions')
ylabel('Drums - Middle Point [in sec]')
title({animalName;'Discrimination time for No-Go Success'})


%% Pie Charts that Represent the Amount of Times, the Individual States Were Presented

% answer = questdlg('Would you like to plot the state pie charts for all chosen sessions?', ...
%     'Number of Sessions', ...
%     'Yes','No','Last 11 Sessions','Last 11 Sessions');
answer = 'Last 11 Sessions';

switch answer
    case 'Yes'
        acitivty_sessions = 1:numel(user_sessions);
    case 'No'
        acitivty_sessions = inputdlg(sprintf('Please choose the sessions of interest\nExample: 1,3,5-7 or 8-14'),...
            'Sessions',[1, 50]);
        acitivty_sessions = regexprep(acitivty_sessions{1},{'-',','},{':',' '});
        acitivty_sessions = str2double(acitivty_sessions);
        Sessions_sel = Sessions_copy(acitivty_sessions);
    case 'Last 11 Sessions'
        if numel(user_sessions) < 11
            acitivty_sessions = 1:numel(user_sessions);
            Sessions_sel = Sessions_copy(acitivty_sessions);
        else
            acitivty_sessions = numel(user_sessions)-10:numel(user_sessions);
            Sessions_sel = Sessions_copy(acitivty_sessions);
        end
end


num_row = ceil((numel(Sessions_sel)+1)/3);
f = figure(8);
f.Name = 'StatePresent';
for i=1:numel(Sessions_sel)
    no_go = success_go(acitivty_sessions(i)) + failure_go(acitivty_sessions(i));
    no_medium = medium_lick(acitivty_sessions(i)) + medium_nolick(acitivty_sessions(i));
    no_nogo = success_nogo(acitivty_sessions(i)) + failure_nogo_first(acitivty_sessions(i));
    
    l_labels = {'Go State','Neutral State','No-Go State'};
    subplot(num_row,3,i+1)
    p = pie([no_go no_medium no_nogo]);
    p(1).FaceColor = '#b3ffb3';
    p(3).FaceColor = '#ffffb3';
    p(5).FaceColor = '#ffc6b3';
    if i == 1
        l = legend(l_labels);
        legend('boxoff')
        newPosition = [0.12 0.76 0.25 0.15]; % Move legend to right spot
        newUnits = 'normalized';
        set(l,'Position', newPosition,'Units', newUnits);
        title({animalName; sprintf('Session No. %d \n', user_sessions(acitivty_sessions(i)))})
    else
        title(sprintf('Session No. %d \n', user_sessions(acitivty_sessions(i))))
    end
end

%% Activity Measured as Events per min for +/- 30 sec

% answer = questdlg('Would you like to plot the acitivity pattern from all chosen sessions?', ...
%     'Number of Sessions', ...
%     'Yes','No','Last 12 Sessions','Last 12 Sessions');
answer = 'Last 12 Sessions';

switch answer
    case 'Yes'
        acitivty_sessions = user_sessions;
    case 'No'
        acitivty_sessions = inputdlg(sprintf('Please choose the sessions of interest\nExample: 1,3,5-7 or 8-14'),...
            'Sessions',[1, 50]);
        acitivty_sessions = regexprep(acitivty_sessions{1},{'-',','},{':',' '});
        acitivty_sessions = str2double(acitivty_sessions);
        Timestamps_sel = Timestamps_copy(acitivty_sessions);
        Events_sel = Events_copy(acitivty_sessions);
        Sessions_sel = Sessions_copy(acitivty_sessions);
    case 'Last 12 Sessions'
        if numel(user_sessions) < 12
            acitivty_sessions = user_sessions;
            Timestamps_sel = Timestamps_copy(acitivty_sessions);
            Events_sel = Events_copy(acitivty_sessions);
            Sessions_sel = Sessions_copy(acitivty_sessions);
        else
            acitivty_sessions = user_sessions(end-11:end);
            Timestamps_sel = Timestamps_copy(acitivty_sessions);
            Events_sel = Events_copy(acitivty_sessions);
            Sessions_sel = Sessions_copy(acitivty_sessions);
        end
end



active_events = {'Go Success','No-Go Failure','Medium Lick','Repeat','Drums','Middle point'};
activeEvents = cell(1,numel(Sessions_sel));
activeEvents_ts = cell(1,numel(Sessions_sel));

for i=1:numel(Sessions_sel)
    logidx = contains(Events_sel{i}, active_events);
    
    % Important to include only 'Go Successes' and not the 'No-Go Successes'
    idx_gosuc = strncmpi(Events_sel{i}, active_events(1), 8);
    logidx = or(logidx,idx_gosuc);
    activeEvents{i} = Events_sel{i}(logidx);
    first_middle = contains(Events_sel{i}, 'Middle point');
    first_middle = find(first_middle, 1, 'first');
    first_middle = Timestamps_sel{i}(first_middle);
    
    % Substract first timestamp of Middle beam as a proxy for trial beginning
    activeEvents_ts{i} = Timestamps_sel{i}(logidx)-first_middle;
    
    % Exclude those events, that happen <0.5sec after one anthoer, as they
    % are most probably artefacts
    idx = ones(1,numel(activeEvents{i}));
    for ii=1:numel(activeEvents{i})-1
        if activeEvents_ts{i}(ii+1)-activeEvents_ts{i}(ii) < 500
            idx(ii+1) = 0;
        else
            idx(ii+1) = 1;
        end
    end
    idx = logical(idx);
    activeEvents_ts{i} = activeEvents_ts{i}(idx);
    activeEvents{i} = activeEvents{i}(idx);
end

totalTime_msec = cell(1,numel(Sessions_sel));
for i=1:numel(Sessions_sel)
    attributes = read([fileparts(fileparts(Sessions_sel{i})),'\attributes.toml']);
    first_middle = contains(Events_sel{i}, 'Middle point');
    first_middle = find(first_middle, 1, 'first');
    first_middle = Timestamps_sel{i}(first_middle);
    totalTime_msec{i} = attributes.recording_length_msec - first_middle;
end

num_row = ceil(numel(Sessions_sel)/3);
f = figure(9);
f.Name = 'Activity';
title(animalName)
for i=1:numel(Sessions_sel)
    if isequal(totalTime_msec{i}, 'No video file')
        subplot(num_row,3,i)
        title('Not able to determine length of trial')
    else
        activity = zeros(1,length(30000:1000:totalTime_msec{i}-30000));
        j = 1;
        for ii = 0:1000:totalTime_msec{i}
            j = j+1;
            k1 = ii - 30000;
            k2 = ii + 30000;
            if k1 < 0
                k1 = 0;
                % This determines the fraction of a minute, that is
                % presented an devides the value later on.
                fract_min = (k2-k1)/1000/60;
                new_value = sum(activeEvents_ts{i} < k2 & activeEvents_ts{i} > k1);
                new_value = new_value/fract_min;
            elseif k2 > totalTime_msec{i}
                k2 = totalTime_msec{i};
                fract_min = (k2-k1)/1000/60;
                new_value = sum(activeEvents_ts{i} < k2 & activeEvents_ts{i} > k1);
                new_value = new_value/fract_min;
            else
                new_value = sum(activeEvents_ts{i} < k2 & activeEvents_ts{i} > k1);
            end
            activity(j) = new_value;
        end
        % Check for triggered noise, to plot it
        logidx = contains(Events_sel{i},'Noise triggered');
        noise_triggers = (Timestamps_sel{i}(logidx))./1000;
        
        subplot(num_row,3,i)
        p1 = plot(activity, 'Color', '#0072BD');
        if ~isempty(noise_triggers)
            hold on
            y = [0 maxk(activity,1)];
            p2 = plot([noise_triggers'; noise_triggers'], y, 'r');
            hold off
            warning('off','MATLAB:legend:IgnoringExtraEntries')
            legend(p2,'Noise triggered','Box','off')
            warning('on','MATLAB:legend:IgnoringExtraEntries')
        end
        axis([1 ((totalTime_msec{i}-30000)/1000) 0 maxk(activity,1)])
        xlabel('time [sec]')
        ylabel('Events per min for +/- 30 sec')
        if i == 2
            title({animalName; sprintf('Session No. %d \n Length of trial: %.2fmin',...
                acitivty_sessions(i), totalTime_msec{i}/60000)})
        else
            title(sprintf('Session No. %d \n Length of trial: %.2fmin',...
                acitivty_sessions(i), totalTime_msec{i}/60000))
        end
    end
end

%% Function that Compares the Lick Sensitivities for Both Lick Ports

compare_licksensitivity(Events, Sessions, medium_lick, medium_nolick,...
    success_go, failure_go, failure_nogo_first, success_nogo, labels, animalName)
