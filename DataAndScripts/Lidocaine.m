%% Performance with lidocaine application
% only works if animalData.m is loaded
currentFolder = pwd;
load(fullfile(currentFolder,'/RawData/animalData'))

%% load relevent Cohort Data
cohorts = [11,12]; %only animals from these cohorts were tested with lidocaine on the whiskerpad
sesFlag = 'P3.5'; %the stage for all animals was P3.5
miceFlag11 = 2; %only animal 2 form cohort 11 became lidocaine application

alldvalues = NaN(8,4);
for cohortIDX = cohorts
    cohortData = animalData.cohort(cohortIDX).animal;
    for mouseIDX = 1:length(cohortData)
        isLido = contains(cohortData(mouseIDX).session_names,sesFlag);

        sesFlag_first = find(isLido, 1, 'first');
        sesFlag_last = find(isLido, 1, 'last');

        dvalues = cohortData(mouseIDX).dvalues_sessions(sesFlag_first:sesFlag_last);

        if isempty (dvalues)
            continue
        elseif cohortIDX == 11 && miceFlag11 == mouseIDX
            alldvalues(2:length(dvalues)+1,1) = dvalues; %first session was a lidocaine session
        elseif cohortIDX == 12
            alldvalues(1:length(dvalues),mouseIDX-1) = dvalues;
        else
            continue
        end
    end
end

dprimeBepa = vertcat(alldvalues(1,:),alldvalues(3,:),alldvalues(5,:),alldvalues(7,:)); % odd rows are control sessions
dprimeLido = vertcat(alldvalues(2,:),alldvalues(4,:),alldvalues(6,:),alldvalues(8,:)); % even rows are lidocaine sessions

dprime_all = horzcat(vertcat(dprimeBepa(:,1),dprimeBepa(:,2),dprimeBepa(:,3),dprimeBepa(:,4)),...
    vertcat(dprimeLido(:,1),dprimeLido(:,2),dprimeLido(:,3),dprimeLido(:,4)));

%% statistics
meanbepa = mean(dprimeBepa,1,'omitnan');
meanlido = mean(dprimeLido,1,'omitnan');

[~,p,ci,stats] = ttest(meanbepa, meanlido);

%% plot data
figure, hold on

boxchart(dprime_all, 'BoxFaceColor', 'k')
scatter(ones(1,length(dprimeBepa)), dprimeBepa(:,1),'Marker','.','Jitter','on','MarkerEdgeColor','k')
scatter(ones(1,length(dprimeBepa))*2, dprimeLido(:,1),'Marker','.','Jitter','on','MarkerEdgeColor','k')

yline([1.65, 1.65],'Color','black','LineStyle','--')
yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')
title('Performance with and without lidocaine application')
xticklabels({'Control','Lidocaine'})
ylabel('d prime')