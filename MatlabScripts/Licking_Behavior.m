%% Lick rates for initial rule, neutral stage and reversed rule
% only works if animalData.m is loaded

%% choose cohorts
cohorts = arrayfun(@(x) num2str(x), 1:numel(animalData.cohort), 'UniformOutput', false);
answer = listdlg('ListString',cohorts,'PromptString','Choose your cohort.');
cohorts = cellfun(@str2double, cohorts(answer));
cohortData = horzcat(animalData.cohort(cohorts).animal);

%% choose stages
stages = getstagenames(cohortData);
answer = listdlg('ListString',stages,'PromptString','Choose stages.');
stages = stages(answer);

%% get lick rates
numMice = length(cohortData);
max_gosuc = max(arrayfun(@(m) length(cohortData(m).gogo_suc), 1:sum(numMice)));
max_nogosuc = max(arrayfun(@(m) length(cohortData(m).nogo_suc), 1:sum(numMice)));
allgosuc_initial = NaN(max_gosuc, numMice);
allnogosuc_initial = NaN(max_nogosuc, numMice);
allgosuc_switched = NaN(max_gosuc, numMice);
allnogosuc_switched = NaN(max_nogosuc, numMice);

all_ses_ini = []; all_ses_swi = [];
for mouseIDX = 1:length(cohortData)
    for stageIDX = 1:length(stages)
        isStage = contains(cohortData(mouseIDX).session_names, stages(stageIDX));
        sesFlag_first = find(isStage, 1, 'first');
        sesFlag_last = find(isStage, 1, 'last');
        num_ses = sesFlag_last-sesFlag_first;

        if isempty(num_ses)
            continue
        else
            norm_ses = (1:num_ses)/num_ses;

            gosuc = cohortData(mouseIDX).gogo_suc;
            gosuc(sesFlag_last+1:end) = [];
            gosuc(1:sesFlag_first-1) = [];

            nogosuc = cohortData(mouseIDX).nogo_suc;
            nogosuc(sesFlag_last+1:end) = [];
            nogosuc(1:sesFlag_first-1) = [];

            if strcmp(stages{stageIDX}, 'P3.2')
                all_ses_ini = cat(1, all_ses_ini(:), {norm_ses});
                allgosuc_initial(1:length(gosuc),mouseIDX) = gosuc;
                allnogosuc_initial(1:length(nogosuc),mouseIDX) = nogosuc;
            elseif strcmp(stages{stageIDX}, 'P3.3')
                allgosuc_neu(1:length(gosuc),mouseIDX) = gosuc;
                allnogosuc_neu(1:length(nogosuc),mouseIDX) = nogosuc;

                neulick = cohortData(mouseIDX).medium_lick;
                neulick(sesFlag_last+1:end) = [];
                neulick(1:sesFlag_first-1) = [];
                allneutral(1:length(neulick),mouseIDX) = neulick;
            elseif strcmp(stages{stageIDX}, 'P3.4')
                all_ses_swi = cat(1, all_ses_swi(:), {norm_ses});
                allgosuc_switched(1:length(gosuc),mouseIDX) = gosuc;
                allnogosuc_switched(1:length(nogosuc),mouseIDX) = nogosuc;
            end
        end
    end
end

%% plot data
% initial rule
fig_1 = plot_patch(1-allnogosuc_initial,all_ses_ini,[0.6350 0.0780 0.1840],30);
plot_patch(allgosuc_initial,all_ses_ini,[0.4660 0.6740 0.1880],30,fig_1);
title('Population lick rates (initial rule)')
xlabel('Session proportion'); ylabel('Lick rate')
legend({'No-go trials' '' 'Go trials'}, 'Box', 'off', 'Location', 'best')
set(gca,'Box','off','Color','none')

% reversed rule
fig_2 = plot_patch(1-allnogosuc_switched,all_ses_swi,[0.6350 0.0780 0.1840],40);
plot_patch(allgosuc_switched,all_ses_swi,[0.4660 0.6740 0.1880],40,fig_2);
title('Population lick rates (reversed rule)')
xlabel('Session proportion'); ylabel('Lick rate')
legend({'No-go trials' '' 'Go trials'}, 'Box', 'off', 'Location', 'best')
set(gca,'Box','off','Color','none')

% neutral state
% as all animals had 8 sessions in stage 3 we don't necessarly need the proportion function
numSes = 8; xvalues = 1:numSes;
allrates_neu = [1-allnogosuc_neu; allgosuc_neu; allneutral];
color_map = [[0.6350 0.0780 0.1840]; [0.4660 0.6740 0.1880]; [0.9290 0.6940 0.1250]];

figure; hold on
for trialIDX = 1:length(stages)
    sig_plot = std(allrates_neu((trialIDX*numSes)-(numSes-1):numSes*trialIDX,:),1,2,'omitnan');
    mu_plot = mean(allrates_neu((trialIDX*numSes)-(numSes-1):numSes*trialIDX,:),2,"omitnan");
    curve1 = mu_plot + sig_plot;
    curve2 = mu_plot - sig_plot;

    plot(xvalues, mu_plot, 'Color', color_map(trialIDX,:))
    fill([1:length(curve1) fliplr(1:length(curve1))], [curve1' fliplr(curve2')],[0 0 .85],...
        'FaceColor',color_map(trialIDX,:), 'EdgeColor','none','FaceAlpha',0.1)
end

% labels
ylim([0,1])
title('Population lick rates (neutral aperture state)')
xlabel('Session'); ylabel('Lick rate')
legend({'No-go trials' '' 'Go trials' '' 'Neutral trials'}, 'Box', 'off', 'Location', 'best')
set(gca,'Box','off','Color','none')