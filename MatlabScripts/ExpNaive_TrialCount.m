%% Trial count for initial and reversed rule
% only works if animalData.m is loaded

%% choose cohorts and number of sessions
cohorts = arrayfun(@(x) num2str(x), 1:numel(animalData.cohort), 'UniformOutput', false);
answer = listdlg('ListString',cohorts,'PromptString','Choose your cohort.');
cohorts = cellfun(@str2double, cohorts(answer));
%cohortData = horzcat(animalData.cohort(cohorts).animal);

%numCohorts = length(cohortFlag);
numMice = arrayfun(@(x) length(animalData.cohort(x).animal), cohorts);

% specify the number of sessions you want to analyze for each condition
prompt = "How many sessions you want to analyze for each condition?";
numSes = str2double(inputdlg(prompt));

%% Initial rule (should be called P3.2) expert vs. naive
alltrials_ini = NaN (sum(numMice),numSes*2);
for cohortIdx = 1:length(cohorts)
    cohortData = animalData.cohort(cohorts(cohortIdx)).animal;
    mouseFlag = length(cohortData);

    for mouseIdx = 1:mouseFlag
        isP2 = contains(cohortData(mouseIdx).session_names,'P3.2');
        sesFlag_first = find(isP2, 1, 'first');
        sesFlag_last = find(isP2, 1, 'last');

        % count trials
        trialcountnaive = cellfun(@numel, cohortData(mouseIdx).Lick_Events(sesFlag_first:sesFlag_first+(numSes-1)));
        trialcountexp = cellfun(@numel, cohortData(mouseIdx).Lick_Events(sesFlag_last-(numSes-1):sesFlag_last));
        
        rowIdx = sum(numMice(1:cohortIdx-1)) + mouseIdx;
        alltrials_ini(rowIdx, 1:numSes) = trialcountnaive;
        alltrials_ini(rowIdx, numSes+1:numSes*2) = trialcountexp;
    end
end

% calculate mean trials for both conditions
naivetrials_ini = mean(alltrials_ini(:,1:numSes), 2);
experttrials_ini = mean(alltrials_ini(:,numSes+1:numSes*2), 2);

% Statistics and normalization
[~,p1] = ttest(naivetrials_ini, experttrials_ini);
%ztrials_ini = zscore(alltrials_ini,0,2);

%% Reversed rule (should be called P3.4) expert vs. naive
alltrials_swi = NaN (sum(numMice),numSes*2);
for cohortIdx = 1:length(cohorts)
    cohortData = animalData.cohort(cohorts(cohortIdx)).animal;
    mouseFlag = length(cohortData);

    for mouseIdx = 1:length(cohortData)
        isP4 = contains(cohortData(mouseIdx).session_names,'P3.4');
        sesFlag_first = find(isP4, 1, 'first');
        sesFlag_last = find(isP4, 1, 'last');
        
        % count Trials
        trialcountnaive = cellfun(@numel, cohortData(mouseIdx).Lick_Events(sesFlag_first:sesFlag_first+(numSes-1)));
        trialcountexp = cellfun(@numel, cohortData(mouseIdx).Lick_Events(sesFlag_last-(numSes-1):sesFlag_last));
        
        rowIdx = sum(numMice(1:cohortIdx-1)) + mouseIdx;
        alltrials_swi(rowIdx, 1:numSes) = trialcountnaive;
        alltrials_swi(rowIdx, numSes+1:numSes*2) = trialcountexp;      
    end
end

% calculate mean trials for both conditions
naivetrials_swi = mean(alltrials_swi(:,1:numSes), 2);
experttrials_swi = mean(alltrials_swi(:,numSes+1:numSes*2), 2);

% Statistics and normalization
%[p2,~] = signrank(naivetrials_swi, experttrials_swi);
[~,p2] = ttest(naivetrials_swi, experttrials_swi);
%ztrials_swi = zscore(alltrials_swi,0,2);

%% plot data initial rule
% line plot
figure; hold on
%boxchart(ones(1,length(naivetrials_ini)),naivetrials_ini,'BoxFaceColor','k','MarkerStyle','none','BoxWidth',0.2)
%boxchart(ones(1,length(experttrials_ini))+1,experttrials_ini,'BoxFaceColor','k','MarkerStyle','none','BoxWidth',0.2)
errorbar(0.9,mean(naivetrials_ini),std(naivetrials_ini),'o','Color','k','MarkerFaceColor','k')
errorbar(2.1,mean(experttrials_ini),std(experttrials_ini),'o','Color','k','MarkerFaceColor','k')
for i = 1:length(experttrials_ini)
    plot([1,2],[naivetrials_ini(i),experttrials_ini(i)],'Color','k','LineStyle','--')
end
plot([1,2],[mean(naivetrials_ini),mean(experttrials_ini)],'Color','k','LineWidth',2)
maxexpert = max(experttrials_ini);
plotStatistics(p1,maxexpert,1,2)
title('Trials per session', 'Initial rule')
xticks([1 2]); xticklabels({'Naive','Expert'})
ylabel('Trials')

%% plot data switched rule
% line plot
figure; hold on
errorbar(0.9,mean(naivetrials_swi),std(naivetrials_swi),'o','Color','k','MarkerFaceColor','k')
errorbar(2.1,mean(experttrials_swi),std(experttrials_swi),'o','Color','k','MarkerFaceColor','k')
for i = 1:length(experttrials_swi)
    plot([1,2],[naivetrials_swi(i),experttrials_swi(i)],'Color','k','LineStyle','--')
end
plot([1,2],[mean(naivetrials_swi),mean(experttrials_swi)],'Color','k','LineWidth',2)
maxexpert = max(experttrials_swi);
plotStatistics(p2,maxexpert,1,2)
title('Trials per session', 'Reversed rule')
xticks([1 2]); xticklabels({'Naive','Expert'})
ylabel('Trials')