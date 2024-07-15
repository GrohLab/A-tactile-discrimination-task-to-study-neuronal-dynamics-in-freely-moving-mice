%% Backlights
% load relevant Cohort Data
cohortData = animalData.cohort(18).animal;
numMice = length(cohortData);

SesFlag = arrayfun(@(m) contains(cohortData(m).session_names,{'no_backlights'}), 1:numMice, 'UniformOutput', false);
numSes = arrayfun(@(m) sum(SesFlag{m}), 1:numMice);
maxSes = max(numSes);
numSes = min(numSes(numSes>0));

alldprime_lights = NaN(numMice,numSes);
alldprime_nolights = NaN(numMice,maxSes);
for mouseIDX = 1:numMice
    d_nolights = cohortData(mouseIDX).dvalues_sessions(SesFlag{mouseIDX});
    lightsFlag = find(SesFlag{mouseIDX},1, 'first')-numSes;
    d_lights = cohortData(mouseIDX).dvalues_sessions(lightsFlag:lightsFlag+(numSes-1));

    if isempty(d_nolights)
        continue
    else
        alldprime_lights(mouseIDX,:) = d_lights;
        alldprime_nolights(mouseIDX,1:length(d_nolights)) = d_nolights;
    end
end
alldprime_nolights(:,numSes+1:end) = [];

%%
% statistics
[~,p_paired] = ttest(alldprime_lights, alldprime_nolights);

alldprime = horzcat(vertcat(alldprime_lights(:,1),alldprime_lights(:,2)),...
    vertcat(alldprime_nolights(:,1),alldprime_nolights(:,2)));

% plot data
figure; hold on
boxchart(alldprime, 'BoxFaceColor','k')
scatter(1:numSes,alldprime,'Marker','.','Jitter','on','MarkerEdgeColor','k')

ylabel('d prime')
yline([1.65, 1.65],'Color','black','LineStyle','--')
xticklabels({'Backlights on', 'Backlights off'})
title('Population performance with and without backlights')
max_dprime = max(max(alldprime));
plotStatistics(min(p_paired),max_dprime,1,2)
