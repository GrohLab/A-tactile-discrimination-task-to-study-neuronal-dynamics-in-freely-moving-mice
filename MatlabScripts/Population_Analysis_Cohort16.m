%% Population trial d'prime initial rules cohort 16
cohorts = 16;
cohortData = animalData.cohort(cohorts).animal;

numMice = arrayfun(@(x) length(animalData.cohort(x).animal), cohorts);
max_dvalue = max(arrayfun(@(m) length(cohortData(m).dvalues_trials), 1:sum(numMice)));

% stages = getstagenames(cohortData);
% answer = listdlg('ListString',stages,'PromptString','Choose stages.');
stages = {'P3.2','P3.4'};

close all
fig14mm = figure;
fig16mm = figure;

alldvalues = NaN(max_dvalue,sum(numMice));
contrastFlag = NaN(1,sum(numMice));
for stageIDX = 1:length(stages)
    for mouseIDX = 1:length(cohortData)
        isStage1 = contains(cohortData(mouseIDX).session_names, 'P3.1');
        sesFlag_last_stage1 = find(isStage1, 1, 'last');

        isStage = contains(cohortData(mouseIDX).session_names,stages(stageIDX));
        sesFlag_first = find(isStage, 1, 'first');
        sesFlag_last = find(isStage, 1, 'last');
        if isempty(sesFlag_first)
            continue
        end

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

        if contains(cohortData(mouseIDX).session_names,'14mm')
            contrastFlag(mouseIDX) = 14;
        elseif contains(cohortData(mouseIDX).session_names,'16mm')
            contrastFlag(mouseIDX) = 16;
        end

        alldvalues(1:length(dvalues),mouseIDX) = dvalues;
        clear dvalues
    end

    color_map = [[0.1294 0.4 0.6745]; [0.9373 0.5412 0.3843]];

    figure(1)
    trials_dprime_mean = mean(alldvalues(:,contrastFlag==14),2,'omitnan'); trials_dprime_mean(isnan(trials_dprime_mean)) =[];
    trials_dprime_std = std(alldvalues(:,contrastFlag==14),0,2,'omitnan'); trials_dprime_std(isnan(trials_dprime_std)) =[];
    curve1 = trials_dprime_mean + trials_dprime_std;
    curve2 = trials_dprime_mean - trials_dprime_std;
    fill([(1:length(curve1))+200 fliplr((1:length(curve1))+200)], [curve1' fliplr(curve2')],[0 0 .85],...
        'FaceColor',color_map(stageIDX,:), 'EdgeColor','none','FaceAlpha',0.5); hold on
    plot((1:length(trials_dprime_mean))+200,trials_dprime_mean, 'Color', color_map(stageIDX,:), 'LineWidth', 2)

    figure(2)
    trials_dprime_mean = mean(alldvalues(:,contrastFlag==16),2,'omitnan'); trials_dprime_mean(isnan(trials_dprime_mean)) =[];
    trials_dprime_std = std(alldvalues(:,contrastFlag==16),0,2,'omitnan'); trials_dprime_std(isnan(trials_dprime_std)) =[];
    curve1 = trials_dprime_mean + trials_dprime_std;
    curve2 = trials_dprime_mean - trials_dprime_std;
    fill([(1:length(curve1))+200 fliplr((1:length(curve1))+200)], [curve1' fliplr(curve2')],[0 0 .85],...
        'FaceColor',color_map(stageIDX,:), 'EdgeColor','none','FaceAlpha',0.5); hold on
    plot((1:length(trials_dprime_mean))+200,trials_dprime_mean, 'Color', color_map(stageIDX,:), 'LineWidth', 2)

    if strcmp(stages{stageIDX}, 'P3.2')
        intersec_initial = vertcat(cohortData.intersec_initial);
        figure(1)
        learntime = mean(intersec_initial(contrastFlag == 14));
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
        figure(2)
        learntime = mean(intersec_initial(contrastFlag == 16));
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
    elseif strcmp(stages{stageIDX}, 'P3.4')
        emptyFlag = arrayfun(@(m) isempty(cohortData(m).intersec_second),1:sum(numMice));
        cohortData(emptyFlag).intersec_second = NaN;
        intersec_second = vertcat(cohortData.intersec_second);
        figure(1)
        learntime = mean(intersec_second(contrastFlag == 14), 'omitnan');
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
        figure(2)
        learntime = mean(intersec_second(contrastFlag == 16), 'omitnan');
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
    else
        continue
    end

    alldvalues = NaN(max_dvalue,sum(numMice));
end

figure(1)
xlabel('Trials')
ylabel('d prime')
yline([1.65, 1.65],'Color','black','LineStyle','--')
% yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')
title('Population performance over trials (contrast 14mm)')
xlim([200 3055])

figure(2)
xlabel('Trials')
ylabel('d prime')
yline([1.65, 1.65],'Color','black','LineStyle','--')
% yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')
title('Population performance over trials (contrast 16mm)')