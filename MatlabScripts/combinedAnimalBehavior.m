%% Choose Cohort

close all
clearvars
clc

startPath = 'Z:\Filippo\Animals';
try
    load(fullfile(startPath,'animalData.mat'))
catch
    fprintf(2,'\nThe variable "animalData.mat" doesn''t exist.')
    fprintf(2,'\nYou have to create it first.\n\n')
    return
end

cohortDirs = dir(fullfile(startPath,'cohort*'));
list = {cohortDirs.name};

cohort_idx = listdlg('PromptString',{'Which cohort would you like to plot?'},...
    'SelectionMode','single','ListSize',[250 180],...
    'ListString',list);

cohort = cell2mat(regexp(cohortDirs(cohort_idx).name,'Cohort(\d+)','tokens','once'));
cohort_vars = animalData.cohort(str2double(cohort)).animal;

%%%
for i = 1:height(cohort_vars)
    cohort_vars(i).session_names = strrep(cohort_vars(i).session_names,'second_rules_one_wing','initial_rules_one_wing');
end
%%%

for i = 1:numel(cohort_vars)
    % Only consider percentage values, if absolute bodyweights are present
    if size(cohort_vars(i).bodyweight,2) > 1
        cohort_vars(i).bodyweight = cohort_vars(i).bodyweight(:,2);
    end
    % If some bodyweights are missing, add nan values
    if numel(cohort_vars(1).session_names) > numel(cohort_vars(1).bodyweight)
        cohort_vars(i).bodyweight = [cohort_vars(i).bodyweight;...
            nan(numel(cohort_vars(1).session_names)-numel(cohort_vars(1).bodyweight),1)];
    elseif numel(cohort_vars(i).bodyweight) > numel(cohort_vars(i).session_names)
        fprintf(2,'\nThere are more entries in the bodyweight file of mouse %s, than there are registered sessions. Check sessions again.\n',cohort_vars(i).animalName)
    end
end


%% Chose approriate alignment

% Reference stage names of cohort
stage_names = cell(1,numel(cohort_vars));
for i = 1:numel(cohort_vars)
    stage_names{i} = cellfun(@(x) regexp(x,'P3.*_','match'), cohort_vars(i).session_names);
end

unique_list = cell(1, size(stage_names, 2));
for i = 1:size(stage_names, 2)
    unique_list{i} = unique(stage_names{i});
end
unique_ses = unique(cat(1, unique_list{:}));

corr_animals = cell(size(unique_ses,1),numel(cohort_vars));
for i = 1:numel(unique_ses)
    loglist = cellfun(@(x) contains(x, unique_ses(i)),unique_list,'UniformOutput',false);
    for k = 1:numel(loglist)
        if any(loglist{k})
            corr_animals{i,k} = cohort_vars(k).animalName;
        end
    end
end
unique_ses_split = regexp(unique_ses,'_','split', 'once');

bracket_names = cell(size(unique_ses,1),1);
for i = 1:numel(unique_ses)
    temp_cell = corr_animals(i,~cellfun('isempty',corr_animals(i,:)));
    bracket_names{i} = [sprintf('%s, ',temp_cell{1:end-1}),temp_cell{end}];
end

list_cell = [vertcat(unique_ses_split{:}), bracket_names(:)];
list = cell(1, size(unique_ses_split, 1));
for i = 1:size(unique_ses_split, 1)
    list{i} = ['Stage ',list_cell{i,1}(4:end),' - ',list_cell{i,2}(1:end-1),...
        ' (',list_cell{i,3},')'];
end


% Define start and end stage
[start_idx,tf] = listdlg('PromptString',{'Chose Stage at which data should be aligned.'},...
    'SelectionMode','single','ListSize',[350 180],...
    'ListString',list);
if tf == 0
    return
end

if start_idx == numel(list)
    preselect = start_idx;
else
    preselect = start_idx+1;
end

[end_idx,tf] = listdlg('PromptString',{'Chose Stage until which d-prime data should be plotted.'},...
    'SelectionMode','single','ListSize',[350 180],...
    'InitialValue',preselect,'ListString',list);
if tf == 0
    return
end

start_stage = list_cell{start_idx,1}(4:end);
end_stage = list_cell{end_idx,1}(4:end);

% For the d prime per trial plot we only start at stage 2, so that's the
% first cutoff
first_stage2 = ones(numel(cohort_vars),1);
for i = 1:numel(cohort_vars)
    first_stage2(i) = find(contains(cohort_vars(i).session_names,'P3.2'),1);
    cohort_vars(i).Lick_Events_stage2 = cohort_vars(i).Lick_Events(first_stage2(i):end);
end

start_trial = nan(numel(cohort_vars),1);
end_trial = nan(numel(cohort_vars),1);
for i = 1:numel(cohort_vars)
    d = find(contains(cohort_vars(i).session_names,unique_ses{start_idx}),1);
    start_trial(i) = numel(vertcat(cohort_vars(i).Lick_Events_stage2{1:d-first_stage2(i)}));

    d = find(contains(cohort_vars(i).session_names,unique_ses{end_idx}),1,'last');
    end_trial(i) = numel(vertcat(cohort_vars(i).Lick_Events_stage2{1:d-first_stage2(i)+1}));

    if ~isempty(cohort_vars(i).dvalues_trials)
        cohort_vars(i).dvalues_select = cohort_vars(i).dvalues_trials(start_trial(i)+1:end_trial(i));
    else
        fprintf('\n%s has no or not enough trials in the selected stages.',cohort_vars(i).animalName)
    end
end


answer = questdlg('Do you only want to plot the selected window?',...
    'Plotting Option',...
    'Yes','No, just align at start stage.','Yes');
switch answer
    case 'Yes'
        alignment = false;
        animal_idx = find(strcmp(corr_animals(start_idx,:),corr_animals(end_idx,:)));
        if numel(animal_idx) == numel(cohort_vars)
            fprintf('\nAll animals were present in the chosen start and end stages. No animal is omitted.\n')
        else
            fprintf('\nOnly animals %s were present in the chosen start and end stages. All the other animals are omitted.\n',...
                [sprintf('%s, ',cohort_vars(animal_idx(1:end-1)).animalName),cohort_vars(animal_idx(end)).animalName])
        end
        cohort_vars = cohort_vars(animal_idx);

        for i = 1:numel(cohort_vars)
            s_idx = find(contains(cohort_vars(i).session_names,unique_ses{start_idx}),1);
            e_idx = find(contains(cohort_vars(i).session_names,unique_ses{end_idx}),1,'last');
            cohort_vars(i).session_names = cohort_vars(i).session_names(s_idx:e_idx);
            cohort_vars(i).overall_suc = cohort_vars(i).overall_suc(s_idx:e_idx);
            cohort_vars(i).dvalues_sessions = cohort_vars(i).dvalues_sessions(s_idx:e_idx);
            cohort_vars(i).cvalues_sessions = cohort_vars(i).cvalues_sessions(s_idx:e_idx);
            cohort_vars(i).nogo_suc = cohort_vars(i).nogo_suc(s_idx:e_idx);
            cohort_vars(i).gogo_suc = cohort_vars(i).gogo_suc(s_idx:e_idx);
            cohort_vars(i).bodyweight = cohort_vars(i).bodyweight(s_idx:e_idx);
            cohort_vars(i).trial_num = cohort_vars(i).trial_num(s_idx:e_idx);
            cohort_vars(i).medium_lick = cohort_vars(i).medium_lick(s_idx:e_idx);
        end

        if start_idx == end_idx
            title_str = ['Stage ',start_stage];
        else
            title_str = ['Stages ',start_stage,'-',end_stage];
        end
    case 'No, just align at start stage.'
        alignment = true;
        title_str = ['All Stages (aligned at Stage ',start_stage,')'];
        animal_idx = ~cellfun('isempty',corr_animals(start_idx,:));
        if sum(animal_idx) == numel(cohort_vars)
            fprintf('\nAll animals are aligned. No animal is omitted.\n')
        else
            fprintf('\nAnimals %s are aligned. The others are omitted.\n',bracket_names{start_idx})
        end
        cohort_vars = cohort_vars(animal_idx);
    otherwise
        % Return if no answer was picked
        return
end


%% Reshape the variables in the correct alignment

xvals = cell(numel(cohort_vars),1);
for i = 1:numel(cohort_vars)
    xvals{i} = 1:numel(cohort_vars(i).session_names);
end

start = ones(numel(cohort_vars),1);
if tf == 1
    for i = 1:numel(cohort_vars)
        start(i) = find(contains(cohort_vars(i).session_names,unique_ses{start_idx}),1);
        xvals{i} = xvals{i}-(start(i)-1);
    end
end

latest = max(start);
for i = 1:numel(cohort_vars)
    xvals{i} = [nan(1,(latest-start(i))), xvals{i}];
    cohort_vars(i).overall_suc = [nan((latest-start(i)),1);...
        cohort_vars(i).overall_suc];
    cohort_vars(i).dvalues_sessions = [nan((latest-start(i)),1);...
        cohort_vars(i).dvalues_sessions];
    cohort_vars(i).cvalues_sessions = [nan((latest-start(i)),1);...
        cohort_vars(i).cvalues_sessions];
    cohort_vars(i).nogo_suc = [nan((latest-start(i)),1);...
        cohort_vars(i).nogo_suc];
    cohort_vars(i).gogo_suc = [nan((latest-start(i)),1);...
        cohort_vars(i).gogo_suc];
    cohort_vars(i).bodyweight = [nan((latest-start(i)),1);...
        cohort_vars(i).bodyweight];
    cohort_vars(i).trial_num = [nan((latest-start(i)),1);...
        cohort_vars(i).trial_num];
    cohort_vars(i).medium_lick = [nan((latest-start(i)),1);...
        cohort_vars(i).medium_lick];
end

longest = max(cellfun('size',{cohort_vars.overall_suc},1));
for i = 1:numel(cohort_vars)
    xvals{i} = [xvals{i}, nan(1,longest-numel(cohort_vars(i).overall_suc))];
    cohort_vars(i).overall_suc = [cohort_vars(i).overall_suc; nan(longest-numel(cohort_vars(i).overall_suc),1)];
    cohort_vars(i).dvalues_sessions = [cohort_vars(i).dvalues_sessions; nan(longest-numel(cohort_vars(i).dvalues_sessions),1)];
    cohort_vars(i).cvalues_sessions = [cohort_vars(i).cvalues_sessions; nan(longest-numel(cohort_vars(i).cvalues_sessions),1)];
    cohort_vars(i).nogo_suc = [cohort_vars(i).nogo_suc; nan(longest-numel(cohort_vars(i).nogo_suc),1)];
    cohort_vars(i).gogo_suc = [cohort_vars(i).gogo_suc; nan(longest-numel(cohort_vars(i).gogo_suc),1)];
    cohort_vars(i).bodyweight = [cohort_vars(i).bodyweight; nan(longest-numel(cohort_vars(i).bodyweight),1)];
    cohort_vars(i).trial_num = [cohort_vars(i).trial_num; nan(longest-numel(cohort_vars(i).trial_num),1)];
    cohort_vars(i).medium_lick = [cohort_vars(i).medium_lick; nan(longest-numel(cohort_vars(i).medium_lick),1)];
end

prec_trials = nan(1,numel(cohort_vars));
x_alldprime = cell(1,numel(cohort_vars));
for i = 1:numel(cohort_vars)
    % Correct the start session with the cutoff untill stage 2
    start(i) = start(i) - first_stage2(i);
    prec_trials(i) = numel(vertcat(cohort_vars(i).Lick_Events_stage2{1:start(i)-1}));
    x_alldprime{i} = 1:numel(cohort_vars(i).dvalues_trials);
    x_alldprime{i} = x_alldprime{i}-prec_trials(i);
end

longest = max(cellfun('size',{cohort_vars.dvalues_select},1));
for i = 1:numel(cohort_vars)
    %     x_alldprime{i} = [nan(1,(latest-prec_trials(i))), x_alldprime{i},...
    %         nan(1,longest-numel(cohort_vars(i).dvalues_trials))];
    cohort_vars(i).dvalues_select = [cohort_vars(i).dvalues_select;...
        nan(longest-numel(cohort_vars(i).dvalues_select),1)];
end

latest = max(prec_trials);
for i = 1:numel(cohort_vars)
    x_alldprime{i} = [nan(1,(latest-prec_trials(i))), x_alldprime{i}];
    cohort_vars(i).dvalues_trials = [nan((latest-prec_trials(i)),1);...
        cohort_vars(i).dvalues_trials];
end

longest = max(cellfun('size',{cohort_vars.dvalues_trials},1));
for i = 1:numel(cohort_vars)
    x_alldprime{i} = [x_alldprime{i},...
        nan(1,longest-numel(cohort_vars(i).dvalues_trials))];
    cohort_vars(i).dvalues_trials = [cohort_vars(i).dvalues_trials;...
        nan(longest-numel(cohort_vars(i).dvalues_trials),1)];
end

% cohort_vars.dvalues_select


% Replacing all NaN for the x values with integers
for i = 1:numel(cohort_vars)
    oneidx = find(ismember(xvals{i},1));
    xvals{i}(oneidx+1:end) = 2:1:(numel(xvals{i})-(oneidx-1));
    if oneidx~=1
        xvals{i}(oneidx-1:-1:1) = 0:-1:-(oneidx-2);
    end

    oneidx = find(ismember(x_alldprime{i},1));
    x_alldprime{i}(oneidx+1:end) = 2:1:(numel(x_alldprime{i})-(oneidx-1));
    if oneidx~=1
        x_alldprime{i}(oneidx-1:-1:1) = 0:-1:-(oneidx-2);
    end
end


%% Evaluate Correlation between Bodyweight and No-Go Successes

Pearson_R = nan(numel(cohort_vars),1);
p_value = nan(numel(cohort_vars),1);
for i = 1:numel(cohort_vars)
    corr = [cohort_vars(i).bodyweight, cohort_vars(i).nogo_suc];
    [R,p] = corrcoef(corr,'rows','complete');
    Pearson_R(i) = R(2);
    p_value(i) = p(2);
end
corr_bw_nogosuc = table(Pearson_R,p_value);


%% Define the mean average and standard deviations

C = horzcat(cohort_vars.overall_suc);
overall_suc_mean = mean(C,2,'omitnan');
overall_suc_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.dvalues_sessions);
ses_dprime_mean = mean(C,2,'omitnan');
ses_dprime_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.dvalues_select);
fittedtrials_dprime_mean = mean(C,2,'omitnan');
fittedtrials_dprime_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.dvalues_trials);
alltrials_dprime_mean = mean(C,2,'omitnan');
alltrials_dprime_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.nogo_suc);
nogo_suc_mean = mean(C,2,'omitnan');
nogo_suc_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.gogo_suc);
gogo_suc_mean = mean(C,2,'omitnan');
gogo_suc_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.bodyweight);
bodyweight_mean = mean(C,2,'omitnan');
bodyweight_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.trial_num);
trial_num_mean = mean(C,2,'omitnan');
trial_num_std = std(C,0,2,'omitnan');

C = horzcat(cohort_vars.medium_lick);
medium_lick_mean = mean(C,2,'omitnan');
medium_lick_std = std(C,0,2,'omitnan');


%% Plot Overall Success Rate
f = figure(1);
f.Name = 'SucRateTotal';
hold on

curve1 = overall_suc_mean + overall_suc_std;
curve2 = overall_suc_mean - overall_suc_std;

p1 = plot(xvals{1}, curve1,'Color','#4d4d4d');
p2 = plot(xvals{1}, curve2,'Color','#4d4d4d');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#e6e6e6','EdgeColor','none');

for i = 1:numel(cohort_vars)
    plot(xvals{i},cohort_vars(i).overall_suc,'Color','#bfbfbf')
end
plot(xvals{1},overall_suc_mean,'k');
plot([0;0], [0;1],'--','Color','#a6a6a6'); hold off

set(gca,'box','off')
set(gca, 'Layer', 'top')

idx1 = find(~isnan(xvals{1}),1);
idx2 = find(~isnan(xvals{1}),1,'last');
axis([xvals{1}(idx1) xvals{1}(idx2) 0.0 1.0])
xlabel('Sessions')
ylabel('Success rate')
title({['Cohort ',cohort];'Population Overall Success-rate';title_str})


%% Plot No-Go Success Rate
f = figure(2);
f.Name = 'SucRateNoGo';
hold on

yyaxis left
xlabel('Sessions')
ylabel('Success rate')
idx1 = find(~isnan(xvals{1}),1);
idx2 = find(~isnan(xvals{1}),1,'last');
xlim([xvals{1}(idx1) xvals{1}(idx2)])
ylim([0.0 1.0])

curve1 = nogo_suc_mean + nogo_suc_std;
curve2 = nogo_suc_mean - nogo_suc_std;

plot(xvals{1}, curve1,'-','Color','#4d4d4d');
plot(xvals{1}, curve2,'-','Color','#4d4d4d');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#e6e6e6','EdgeColor','none');

for i = 1:numel(cohort_vars)
    plot(xvals{i},cohort_vars(i).nogo_suc,'-','Color','#bfbfbf')
end
plot(xvals{1},nogo_suc_mean,'-k');
plot([0;0], [0;1],'--','Color','#a6a6a6');

set(gca,'box','off')
set(gca, 'Layer', 'top')

yyaxis right
ylabel('Body weight [%]')
set(gca,'ycolor','#ff751a')
ylim([85 105])

plot(xvals{1},bodyweight_mean,'Color','#ff751a'); hold off

title({['Cohort ',cohort];'Population No-Go Success-rate';title_str})


%% Plot Go Success Rate
f = figure(3);
f.Name = 'SucRateGo';
hold on

curve1 = gogo_suc_mean + gogo_suc_std;
curve2 = gogo_suc_mean - gogo_suc_std;

plot(xvals{1}, curve1,'Color','#4d4d4d');
plot(xvals{1}, curve2,'Color','#4d4d4d');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#e6e6e6','EdgeColor','none');

for i = 1:numel(cohort_vars)
    plot(xvals{i},cohort_vars(i).gogo_suc,'Color','#bfbfbf')
end
plot(xvals{1},gogo_suc_mean,'k');
plot([0;0], [0;1],'--','Color','#a6a6a6'); hold off

set(gca,'box','off')
set(gca, 'Layer', 'top')

idx1 = find(~isnan(xvals{1}),1);
idx2 = find(~isnan(xvals{1}),1,'last');
axis([xvals{1}(idx1) xvals{1}(idx2) 0.0 1.0])
xlabel('Sessions')
ylabel('Success rate')
title({['Cohort ',cohort];'Population Go Success-rate';title_str})


%% Plot Lick Rates for every State
f = figure(4);
f.Name = 'LickRates';
hold on

curve1 = gogo_suc_mean + gogo_suc_std;
curve2 = gogo_suc_mean - gogo_suc_std;

plot(xvals{1}, curve1,'Color','#b3ffb3');
plot(xvals{1}, curve2,'Color','#b3ffb3');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#b3ffb3','EdgeColor','none');

curve1 = medium_lick_mean + medium_lick_std;
curve2 = medium_lick_mean - medium_lick_std;

plot(xvals{1}, curve1,'Color','#ffffb3');
plot(xvals{1}, curve2,'Color','#ffffb3');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#ffffb3','EdgeColor','none');

curve1 = (1-nogo_suc_mean) + nogo_suc_std;
curve2 = (1- nogo_suc_mean) - nogo_suc_std;

plot(xvals{1}, curve1,'Color','#ffc6b3');
plot(xvals{1}, curve2,'Color','#ffc6b3');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#ffc6b3','EdgeColor','none');

plot(xvals{1},gogo_suc_mean,'Color','#009900');
plot(xvals{1},medium_lick_mean,'Color','#999900');
plot(xvals{1},(1-nogo_suc_mean),'Color','#992600');
plot([0;0], [0;1],'--','Color','#a6a6a6'); hold off

set(gca,'box','off')
set(gca, 'Layer', 'top')

idx1 = find(~isnan(xvals{1}),1);
idx2 = find(~isnan(xvals{1}),1,'last');
axis([xvals{1}(idx1) xvals{1}(idx2) 0.0 1.0])
xlabel('Sessions')
ylabel('Lick rate')
if ~all(isnan(medium_lick_mean))
    legend({'','','Go Trials','','','Neutral Trials','','','No-Go Trials'})
elseif ~all(isnan(nogo_suc_mean))
    legend({'','','Go Trials','','','','','No-Go Trials'})
else
    legend({'','','Go Trials'})
end
title({['Cohort ',cohort];'Population Lick Rates';title_str})


%% Plot Session d prime
f = figure(5);
f.Name = 'dPrimeSession';
hold on

zero_line = zeros(1,numel(xvals{1}));
dprime_cutoff = 1.65*ones(1,numel(xvals{1}));
plot(xvals{1},zero_line,'Color','#e6e6e6')
plot(xvals{1},dprime_cutoff,':','Color','#999999')

curve1 = ses_dprime_mean + ses_dprime_std;
curve2 = ses_dprime_mean - ses_dprime_std;

plot(xvals{1}, curve1,'Color','#4d4d4d');
plot(xvals{1}, curve2,'Color','#4d4d4d');

x = xvals{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#e6e6e6','EdgeColor','none');

for i = 1:numel(cohort_vars)
    plot(xvals{i},cohort_vars(i).dvalues_sessions,'Color','#bfbfbf')
end
plot(xvals{1},ses_dprime_mean,'k');
plot([0;0], [min(ylim);max(ylim)],'--','Color','#a6a6a6'); hold off

if strcmp(start_idx,'6.1')
    p.YData = [min(ylim) max(ylim) max(ylim) min(ylim)];
end

set(gca,'box','off')
set(gca, 'Layer', 'top')

idx1 = find(~isnan(xvals{1}),1);
idx2 = find(~isnan(xvals{1}),1,'last');
xlim([xvals{1}(idx1) xvals{1}(idx2)])
xlabel('Sessions')
ylabel('d prime')

title({['Cohort ',cohort];'Population Session d prime';title_str;...
    sprintf('Session where average exceeds d'' of 1.65: %d',...
    find(ses_dprime_mean>dprime_cutoff(1),1))})


%% Plot Trial d prime (only previously defined stages)
f = figure(6);
f.Name = 'dPrimeTrialWindow';
hold on

x = 1:numel(cohort_vars(1).dvalues_select);

curve1 = fittedtrials_dprime_mean + fittedtrials_dprime_std;
curve1 = curve1(~isnan(curve1));
curve2 = fittedtrials_dprime_mean - fittedtrials_dprime_std;
curve2 = curve2(~isnan(curve2));

zero_line = zeros(1,numel(x));
dprime_cutoff = 1.65*ones(1,numel(x));
plot(zero_line,'Color','#e6e6e6')
plot(dprime_cutoff,'--','Color','#404040')

x1 = 1:numel(curve1);
plot(x1, curve1,'Color','#4d4d4d');
plot(x1, curve2,'Color','#4d4d4d');
fill([x1 fliplr(x1)], [curve1' fliplr(curve2')],[0 0 .85],'FaceColor','#e6e6e6',...
    'EdgeColor','none');

for i = 1:numel(cohort_vars)
    plot(x,cohort_vars(i).dvalues_select,'Color','#bfbfbf')
end

y2 = fittedtrials_dprime_mean(~isnan(fittedtrials_dprime_mean));
x2 = 1:numel(y2);

plot(x2,y2,'k');

startmin = 200;

yval = y2(startmin:end);
offset = min(yval);
yval = yval' - offset;
xval = 1:1:numel(yval);
xval = xval+startmin;

% [Qpre, ~] = fit_logistic_beta(x2', yval');

[params]=sigm_fit(xval', yval',[],[],0);
Qpre_fit = params(1) + (params(2) - params(1))./ (1 + 10.^((params(3) - xval) * params(4)));
Qpre_fit = Qpre_fit + offset;
plot(xval,Qpre_fit, 'Color', '#0047b3'); hold off

set(gca,'box','off')
set(gca, 'Layer', 'top')

intersec = find(Qpre_fit>dprime_cutoff(1),1);
if isempty(intersec)
    intersec_string = 'Learning speed: NaN';
else
    intersec_string = sprintf('Learning speed: %d Trials',intersec+startmin);
end

xlim([1 numel(cohort_vars(1).dvalues_select)])
if start_stage == end_stage
    title({['Cohort ',cohort];['Population Trial d prime (Stage ',start_stage,')'];...
        intersec_string})
else
    title({['Cohort ',cohort];['Population Trial d prime (Stages ',start_stage,'-',end_stage,')'];...
        intersec_string})
end
xlabel('Trial')
ylabel('d prime')


%% Plot Trial d prime
if ~strcmp(start_stage,'1')
    f = figure(7);
    f.Name = 'dPrimeTrialAll';
    hold on
end

zero_line = zeros(1,numel(x_alldprime{1}));
dprime_cutoff = 1.65*ones(1,numel(x_alldprime{1}));
plot(x_alldprime{1},zero_line,'Color','#e6e6e6')
plot(x_alldprime{1},dprime_cutoff,'--','Color','#404040')

curve1 = alltrials_dprime_mean + alltrials_dprime_std;
curve2 = alltrials_dprime_mean - alltrials_dprime_std;

plot(x_alldprime{1}, curve1,'Color','#4d4d4d');
plot(x_alldprime{1}, curve2,'Color','#4d4d4d');

x = x_alldprime{1}(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1' fliplr(curve2')],[0 0 .85],...
    'FaceColor','#e6e6e6','EdgeColor','none');

for i = 1:numel(cohort_vars)
    plot(x_alldprime{1},cohort_vars(i).dvalues_trials,'Color','#bfbfbf')
end
plot(x_alldprime{1},alltrials_dprime_mean,'-k');
plot([0;0], [min(ylim);max(ylim)],'--','Color','#a6a6a6'); hold off

set(gca,'box','off')
set(gca, 'Layer', 'top')

idx1 = find(~isnan(x_alldprime{1}),1);
idx2 = find(~isnan(x_alldprime{1}),1,'last');
xlim([x_alldprime{1}(idx1) x_alldprime{1}(idx2)])

zero_idx = find(~x_alldprime{1});
if strcmp(start_stage,'2')
    title({['Cohort ',cohort];'Population Trial d prime [all Sessions]';...
        ['Aligned at Stage ',start_stage];...
        sprintf('Trial where average exceeds d'' of 1.65: %d',...
        find(alltrials_dprime_mean>dprime_cutoff(1),1))})
elseif strcmp(start_stage,'7')
    title({['Cohort ',cohort];'Population Trial d prime [all Sessions]';...
        ['Aligned at Stage ',start_stage];...
        sprintf('Trial where average exceeds d'' of 1.65: %d',...
        find(alltrials_dprime_mean(zero_idx+200:end)>dprime_cutoff(1),1))})
else
    title({['Cohort ',cohort];'Population Trial d prime [all Sessions]';['Aligned at P3.',start_stage]})
end
