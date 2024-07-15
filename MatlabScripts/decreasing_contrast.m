%% Popualtion performance over contrast
% only works if animalData.m is loaded
% load Cohort Data
cohortFlag = 14; %only cohort 14 was trained with the decreasing contrast protocol
cohort_Data = animalData.cohort(cohortFlag).animal;
cohort_Table = create_cohort_table(cohort_Data);

% adjust Cohort Table (this part delets the first stage, the relearning and whiskerpluck)
stages = string({'P3.1','P3.10','P3.10.1','P3.11','P3.11.1'});
stageflag = string(cohort_Table(:,2))==stages;
deleteflag = any(stageflag,2);
cohort_Table(deleteflag, :) = [];

stages = string(unique(cohort_Table(:,2)))';
mice = string(unique(cohort_Table(:,1)))';
stageflag = string(cohort_Table(:,2)) == stages;
mouseflag = string(cohort_Table(:,1)) == mice;

% this part creates a table with only the last four sessions for each stage
table_last_four = [];
for mf = mouseflag
    for sf = stageflag
        trueflag = find(mf & sf, 4, 'last');
        table_last_four = [table_last_four;cohort_Table(trueflag,:)];
    end
end

%% plot data
figure; hold on; 
boxchart(categorical(table_last_four(:,2)), [table_last_four{:,4}]','BoxFaceColor', 'k','MarkerStyle','none','MarkerColor','k')
scatter(categorical(table_last_four(:,2)), [table_last_four{:,4}]','k', '.', 'XJitter', 'density')
xticklabels({'20','16','12','10','8','6','4','2'})
title('Population performance over contrast')
xlabel('Contrast [mm]')
ylabel('d prime')
yline([1.65, 1.65],'Color','black','LineStyle','--')
yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')

%savefig(f1, fullfile('Z:\Josephine\Master-Thesis_Figures','Performance_over_contrast.fig'))