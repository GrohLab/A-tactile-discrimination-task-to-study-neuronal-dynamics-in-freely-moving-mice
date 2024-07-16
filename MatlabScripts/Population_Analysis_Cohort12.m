cohortData = horzcat(animalData.cohort(12).animal);

%% choose stages
stages = getstagenames(cohortData);
answer = listdlg('ListString',stages,'PromptString','Choose stages.');
stages = stages(answer);

%% plotting
figure
numMice = arrayfun(@(x) length(animalData.cohort(x).animal), cohorts);
max_dvalue = max(arrayfun(@(m) length(cohortData(m).dvalues_trials), 1:sum(numMice)));

alldvalues = NaN(max_dvalue,sum(numMice));
for stageIDX = 1:length(stages)
    for mouseIDX = 1:length(cohortData)
        % last session stage 1
        isStage1 = contains(cohortData(mouseIDX).session_names, 'P3.1');
        sesFlag_last_stage1 = find(isStage1, 1, 'last');

        isStage = contains(cohortData(mouseIDX).session_names, stages(stageIDX));
        sesFlag_first = find(isStage, 1, 'first');
        sesFlag_last = find(isStage, 1, 'last');

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
                dvalues(trialFlag:end) = [];
                dvalues(1:200) = [];
            end
        end

        %xvalues = (201:length(dvalues)+200)';
        %plot(xvalues, dvalues, 'Color', '#bfbfbf'), hold on

        alldvalues(1:length(dvalues),mouseIDX) = dvalues;
        clear dvalues
    end
    
    color_map = [[0.1294 0.4 0.6745]; [0.9373 0.5412 0.3843]; [0.9922 0.8588 0.7804]; [0.8392 0.3765 0.302]];
    trials_dprime_mean = mean(alldvalues,2,'omitnan'); trials_dprime_mean(isnan(trials_dprime_mean)) =[];
    trials_dprime_std = std(alldvalues,0,2,'omitnan'); trials_dprime_std(isnan(trials_dprime_std)) =[];
    curve1 = trials_dprime_mean + trials_dprime_std;
    curve2 = trials_dprime_mean - trials_dprime_std;
    %plot(201:length(curve1)+200, curve1,'Color','#4d4d4d'); hold on
    %plot(201:length(curve2)+200, curve2,'Color','#4d4d4d')
    fill([(1:length(curve1))+200 fliplr((1:length(curve1))+200)], [curve1' fliplr(curve2')],[0 0 .85],...
        'FaceColor',color_map(stageIDX,:), 'EdgeColor','none','FaceAlpha',0.5); hold on
    plot((1:length(trials_dprime_mean))+200,trials_dprime_mean, 'Color', color_map(stageIDX,:), 'LineWidth', 2)

    alldvalues = NaN(max_dvalue,sum(numMice));

    %learntime = find(trials_dprime_mean>1.65,1);
    if strcmp(stages{stageIDX}, 'P3.2')
        learntime = mean(vertcat(cohortData.intersec_initial));
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
    elseif strcmp(stages{stageIDX}, 'P3.4')
        learntime = mean(vertcat(cohortData.intersec_second));
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
    elseif strcmp(stages{stageIDX}, 'P3.7')
        learntime = mean([653, 940, 732, 552, 760]);
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
    elseif strcmp(stages{stageIDX}, 'P3.8')
        learntime = mean([598, 804]);
        plot([learntime learntime], [-2 1.65], 'Color', color_map(stageIDX,:),  'LineWidth', 1.5, 'LineStyle', ':')
    else
        continue
    end
end

xlabel('Trials')
ylabel('d prime')
yline([1.65, 1.65],'Color','black','LineStyle','--')
%yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')
title ('Population performance over trials')
%legend