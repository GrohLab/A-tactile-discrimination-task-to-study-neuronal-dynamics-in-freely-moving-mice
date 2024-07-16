cohort_Data = animalData.cohort(12).animal;

FieldofChoice = {'intersec_initial', 'intersec_second'};
Speed_ini = horzcat(cohort_Data.(FieldofChoice{1}));
Speed_swi = horzcat(cohort_Data.(FieldofChoice{2}));

% Speed of each animal for the second and third reversal
Speed_second = [653, 940, 732, 552, NaN, 760];
Speed_third = [NaN, NaN, 598, 804, NaN, NaN];

%%
speeds = vertcat(Speed_ini,Speed_swi,Speed_second,Speed_third);
for stageIDX = 1:height(speeds)
speed_mean(stageIDX,:) = mean(speeds(stageIDX,:),'omitnan');
speed_std(stageIDX,:) = std(speeds(stageIDX,:),'omitnan');
end

%% line plot
figure; hold on

for mouseIDX = 1:length(speeds)
    plot([1,2,3,4],speeds(:,mouseIDX),'Color','k','LineStyle','--')
end
% plot the mean
plot([1,2,3,4],speed_mean,'LineWidth', 1.5, 'Color', 'k')

% plot stage distribution
color_map = [[0.1294 0.4 0.6745]; [0.9373 0.5412 0.3843]; [0.1294 0.4 0.6745]; [0.9373 0.5412 0.3843]];
for stageIDX = 1: height(speeds)
    errorbar(stageIDX,speed_mean(stageIDX), speed_std(stageIDX),...
        'o', 'MarkerFaceColor', color_map(stageIDX,:), 'Color', color_map(stageIDX,:))
end

% statistics
speed_max = arrayfun(@(s) max(speeds(s,:)),1:height(speeds));
for i = 2:height(speeds)
    if i == 2
        [~,p_paired] = ttest(speeds(1,:), speeds(i,:));
        plotStatistics(p_paired, max(speed_max)+i*100, 1, i)
    else
        [~,p_paired] = ttest(speeds(2,:), speeds(i,:));
        plotStatistics(p_paired, max(speed_max)+i*100, 2, i)
    end
end

% add labels and title
title('Learning time per animal')
xticks([1,2,3,4]), xticklabels({'Initial rule','Reversed rule','2nd reversal (initial rule)','3rd reversal (reversed rule)'})
ylabel('Trials to expert')