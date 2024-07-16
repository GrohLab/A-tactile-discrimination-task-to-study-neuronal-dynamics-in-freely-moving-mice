%% Population trial d'prime
% only works if animalData.m is loaded

%% choose cohorts
cohorts = arrayfun(@(x) num2str(x), 1:numel(animalData.cohort), 'UniformOutput', false);
answer = listdlg('ListString',cohorts,'PromptString','Choose your cohort.');
cohorts = cellfun(@str2double, cohorts(answer));
cohortData = horzcat(animalData.cohort(cohorts).animal);

if sum(ismember(16, cohorts))
    error('This code does not work with Cohort 16, use Population_Analysis_Cohort16.m')
end

%% choose stages
stages = getstagenames(cohortData);
answer = listdlg('ListString',stages,'PromptString','Choose stages.');
stages = stages(answer);

if sum(ismember({'P3.7','P3.8'}, stages))
    answer = questdlg('Do you want to analyse repeated rule switches?');
    switch answer
        case 'Yes'
            error('For anlysing repeated rule switches use Population_Analysis_Cohort12.m')
        case 'No'
            warning('The stages you choosed might result in errors throughout the script, double check for compatibility')
    end
end

%% plotting
close all; fig_trials = figure; fig_sessions = figure;
color_map = [[0.1294 0.4 0.6745]; [0.9373 0.5412 0.3843]];
numMice = arrayfun(@(x) length(animalData.cohort(x).animal), cohorts);
max_dvalue = max(arrayfun(@(m) length(cohortData(m).dvalues_trials), 1:sum(numMice)));

alldvalues_trials = NaN(max_dvalue,sum(numMice));
alldvalues_sessions = NaN(max_dvalue,sum(numMice));
for stageIDX = 1:length(stages)
    for mouseIDX = 1:length(cohortData)
        % last session stage 1
        isStage1 = contains(cohortData(mouseIDX).session_names, 'P3.1');
        sesFlag_last_stage1 = find(isStage1, 1, 'last');

        isStage = contains(cohortData(mouseIDX).session_names, stages(stageIDX));
        sesFlag_first = find(isStage, 1, 'first');
        sesFlag_last = find(isStage, 1, 'last');
        if isempty(sesFlag_first)
            continue
        end

        % dprime over sessions
        dvalues = cohortData(mouseIDX).dvalues_sessions(sesFlag_first:sesFlag_last);
        alldvalues_sessions(1:length(dvalues),mouseIDX) = dvalues;
        clear dvalues

        % dprime over trials
        if strcmp(stages{stageIDX}, 'P3.2')
            trialFlag = sum(cellfun(@numel, cohortData(mouseIDX).Lick_Events(sesFlag_first:sesFlag_last)));
            if trialFlag == 0
                continue
            else
                dvalues = cohortData(mouseIDX).dvalues_trials;
                dvalues(trialFlag+1:end) = [];
                dvalues(1:200) = [];
            end
        else
            dvalues = cohortData(mouseIDX).dvalues_trials;
            % this part removes all dvalues from stage 2 to the analysed stage
            trialFlag = sum(cellfun(@numel, cohortData(mouseIDX).Lick_Events(sesFlag_last_stage1+1:sesFlag_first-1)));
            dvalues(1:trialFlag) = [];
            % removing the dvalues after the analysed stage and the first 200 (because of 200 trial binning window)
            trialFlag = sum(cellfun(@numel, cohortData(mouseIDX).Lick_Events(sesFlag_first:sesFlag_last)));
            if trialFlag == 0
                continue
            else
                dvalues(trialFlag+1:end) = [];
                dvalues(1:200) = [];
            end
        end
        alldvalues_trials(1:length(dvalues),mouseIDX) = dvalues;
        clear dvalues
    end

    alldvalues.trials = alldvalues_trials;
    alldvalues.sessions = alldvalues_sessions;
    xfield= fieldnames(alldvalues);
    for fieldIDX = 1:length(xfield)
        dprime_mean = mean(alldvalues.(xfield{fieldIDX}),2,'omitnan'); dprime_mean(isnan(dprime_mean)) =[];
        dprime_std = std(alldvalues.(xfield{fieldIDX}),0,2,'omitnan'); dprime_std(isnan(dprime_std)) =[];
        curve1 = dprime_mean + dprime_std;
        curve2 = dprime_mean - dprime_std;

        if strcmp(xfield{fieldIDX}, 'trials')
            figure(fieldIDX)
            fill([(1:length(curve1))+200 fliplr((1:length(curve1))+200)], [curve1' fliplr(curve2')],[0 0 .85],...
                'FaceColor',color_map(stageIDX,:), 'EdgeColor','none','FaceAlpha',0.5); hold on
            plot((1:length(dprime_mean))+200,dprime_mean, 'Color', color_map(stageIDX,:), 'LineWidth', 2)

            if strcmp(stages{stageIDX}, 'P3.2')
                learntime = mean(vertcat(cohortData.intersec_initial));
                plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
            elseif strcmp(stages{stageIDX}, 'P3.4')
                learntime = mean(vertcat(cohortData.intersec_second));
                plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
            else
                continue
            end
        elseif strcmp(xfield{fieldIDX}, 'sessions')
            figure(fieldIDX)
            fill([1:length(curve1) fliplr(1:length(curve1))], [curve1' fliplr(curve2')],[0 0 .85],...
                'FaceColor',color_map(stageIDX,:), 'EdgeColor','none','FaceAlpha',0.5); hold on
            plot((1:length(dprime_mean)),dprime_mean, 'Color', color_map(stageIDX,:), 'LineWidth', 2)

            learntime = find(dprime_mean>1.65,1);
            plot([learntime learntime], [-3 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
        end
    end

    alldvalues_trials = NaN(max_dvalue,sum(numMice));
    alldvalues_sessions = NaN(max_dvalue,sum(numMice));
end

for fieldIDX = 1:length(xfield)
    figure(fieldIDX)
    xlabel(sprintf('%s', xfield{fieldIDX})); ylabel('d prime')
    yline([1.65, 1.65],'Color','black','LineStyle','--')
    %yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')
    title (sprintf('Population performance over %s', xfield{fieldIDX}))
    legend('','Initial rule','','','Reversed rule','Location','southeast','Box','off')
end
