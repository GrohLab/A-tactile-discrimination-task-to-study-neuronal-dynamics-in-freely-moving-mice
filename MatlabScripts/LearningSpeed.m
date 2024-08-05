%% Learning time and speed
% only works if animalData.m is loaded
currentFolder = pwd;
load(fullfile(currentFolder,'/RawData/animalData'))

%% Gather information
% for contrast=20mm cohorts have to be pooled later on
% -> this means std and mean have to be calculated with pooled cohorts (see later sections)

% add cohorts you want to analyze
cohorts = arrayfun(@(x) num2str(x), 1:numel(animalData.cohort), 'UniformOutput', false);
answer = listdlg('ListString',cohorts,'PromptString','Choose your cohort (11, 12, 15, 16 for Manuscript-Plots).');
cohorts = cellfun(@str2double, cohorts(answer));

if sum(ismember(16, cohorts))
    answer = questdlg('You picked cohort 16! The code only works with cohort 16 if the cohort order is: 11, 12, 15, 16. Did you picked those cohorts?');
    switch answer
        case 'Yes'
        case 'No'
            error('Choose other cohorts')
    end
end

if sum(ismember(12, cohorts))
    answer = questdlg('Do you want to analyse repeated rule switches?');
    switch answer
        case 'Yes'
            error('For anlysing repeated rule switches use LearningSpeed_Cohort12.m')
        case 'No'
    end
end

if sum(ismember([18, 19], cohorts))
    error('This code does not work with Cohort 18 or 19, use LearningSpeed_DREADDs.m (found in https://github.com/0815Phine/LabrotationSalience.git)')
end

% points to the values of learning time for each animal
FieldofChoice = {'intersec_initial', 'intersec_second'};

% add the contrast used for each cohort, keep the same shape as used for the cohorts variable
if isequal(cohorts, [11 12 15 16])
    contrast16 = [14,16]; %because 16 was trained on two different contrasts
    contrastOrder = [20,20,12,NaN];
else
    contrastOrder = ones(1,length(cohorts))*20; % indicate the contrast order here, has to be changed according to the cohorts you want to analyze
end

if length(cohorts) ~= length(contrastOrder)
    error('You picked less cohorts than contrasts were indicated, check the variable contrastOrder and adjust accordingly')
end

%% create Speed-cell with speed per animal for each cohort
% we will create two cells for each rule set
Speed_ini_co = cell(2, length(cohorts));
Speed_swi_co = cell(2, length(cohorts));
for cohortIDX = 1:length(cohorts)
    cohortData = animalData.cohort(cohorts(cohortIDX)).animal;

    % cohort 16 was trained on two different contrasts therefore animals have to be split
    if cohorts(cohortIDX) == 16
        Speed_ini_co{1,cohortIDX} = cell(1,2);
        Speed_swi_co{1,cohortIDX} = cell(1,2);
        % create a flag for the different contrast
        for mouseIDX = 1:length(cohortData)
            session_names{mouseIDX} = cohortData(mouseIDX).session_names;
            Flag_14mm(mouseIDX,1) = sum(contains(session_names{1,mouseIDX}, '14mm')) > 0;
            Flag_16mm(mouseIDX,1) = sum(contains(session_names{1,mouseIDX}, '16mm')) > 0;
        end
        Speed_ini_co{1,cohortIDX}{1} = horzcat(cohortData(Flag_14mm).(FieldofChoice{1}));
        Speed_ini_co{1,cohortIDX}{2}  = horzcat(cohortData(Flag_16mm).(FieldofChoice{1}));
        Speed_swi_co{1,cohortIDX}{1} = horzcat(cohortData(Flag_14mm).(FieldofChoice{2}));
        Speed_swi_co{1,cohortIDX}{2}  = horzcat(cohortData(Flag_16mm).(FieldofChoice{2}));

    % the rest can be directly assigned without further preperation
    else
        Speed_ini_co{1,cohortIDX} = horzcat(cohortData.(FieldofChoice{1}));
        Speed_swi_co{1,cohortIDX} = horzcat(cohortData.(FieldofChoice{2}));
    end
end

%% Reshape Speed-cell according to contrast
% this part adds the contrast value to the cell array
for contrastIDX = 1:length(contrastOrder)
    % cohort 16 was trained on two different contrasts
    if isnan(contrastOrder(contrastIDX)) && cohorts(contrastIDX) == 16
        Speed_ini_co{2,contrastIDX}{1} = contrast16(1)*ones(size(Speed_ini_co{1,contrastIDX}{1}));
        Speed_ini_co{2,contrastIDX}{2} = contrast16(2)*ones(size(Speed_ini_co{1,contrastIDX}{2}));
        Speed_swi_co{2,contrastIDX}{1} = contrast16(1)*ones(size(Speed_swi_co{1,contrastIDX}{1}));
        Speed_swi_co{2,contrastIDX}{2} = contrast16(2)*ones(size(Speed_swi_co{1,contrastIDX}{2}));
    else
        Speed_ini_co{2,contrastIDX} = contrastOrder(contrastIDX)*ones(size(Speed_ini_co{1,contrastIDX}));
        Speed_swi_co{2,contrastIDX} = contrastOrder(contrastIDX)*ones(size(Speed_swi_co{1,contrastIDX}));
    end
end

% now we prepare the cell so we can use it for plotting
Speed_ini_contrast = Speed_ini_co;
Speed_swi_contrast = Speed_swi_co;
% first we break down cohort 16
if isequal(cohorts, [11 12 15 16])
    for rowIDX = 1:height(Speed_ini_contrast)
        Speed_co16 = horzcat(Speed_ini_contrast{rowIDX,4});
        Speed_ini_contrast{rowIDX,4} = horzcat(Speed_co16{1},Speed_co16{2});
        Speed_co16 = horzcat(Speed_swi_contrast{rowIDX,4});
        Speed_swi_contrast{rowIDX,4} = horzcat(Speed_co16{1},Speed_co16{2});
    end
end

% change the format
Speed_ini_contrast = cell2mat(Speed_ini_contrast);
Speed_swi_contrast = cell2mat(Speed_swi_contrast);
% remove animals where learning speed is 0 or NaN(might result from other learning stages used)
Speed_swi_contrast(:,Speed_swi_contrast(1,:) == 0) = [];
Speed_swi_contrast(:,isnan(Speed_swi_contrast(1,:))) = [];

% prompt to remove animal #65
% dlgTitle    = 'User Question';
% dlgQuestion = 'Do you want to remove animal #65 (only if you choose Manuscript-cohorts!!)';
% choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
% if strcmpi(choice, 'Yes')
%     Speed_ini_contrast(:,21) = [];
% end

%% Comparison between contrasts
% Boxcharts (initial and reversed rule)
figure; boxchart(Speed_ini_contrast(2,:), Speed_ini_contrast(1,:), 'BoxFaceColor', [0.1294 0.4 0.6745], 'MarkerStyle', 'none')
hold on; boxchart(Speed_swi_contrast(2,:), Speed_swi_contrast(1,:), 'BoxFaceColor', [0.9373 0.5412 0.3843], 'MarkerStyle', 'none')
%scatter(Speed_ini_contrast(2,:), Speed_ini_contrast(1,:),'k','.')
%scatter(Speed_swi_contrast(2,:), Speed_swi_contrast(1,:),'MarkerEdgeColor', [0.5,0.5,0.5],'Marker','.')

contrast = unique(Speed_ini_contrast(2,:));
speed_max = vertcat(arrayfun(@(c) max(Speed_ini_contrast(1, Speed_ini_contrast(2,:) == c)),contrast),...
    arrayfun(@(c) max(Speed_swi_contrast(1, Speed_swi_contrast(2,:) == c)),contrast));
speed_max = max(speed_max);

for contrastIDX = 1:length(unique(contrastOrder))
    if length(Speed_ini_contrast(1,Speed_ini_contrast(2,:)==contrast(contrastIDX))) == length(Speed_swi_contrast(1,Speed_swi_contrast(2,:)==contrast(contrastIDX)))
        [~,p] = ttest(Speed_ini_contrast(1,Speed_ini_contrast(2,:)==contrast(contrastIDX)),...
            Speed_swi_contrast(1,Speed_swi_contrast(2,:)==contrast(contrastIDX)));
    else %% not all animals were trained with both rule sets
        [p,~] = ranksum(Speed_ini_contrast(1,Speed_ini_contrast(2,:)==contrast(contrastIDX)),...
            Speed_swi_contrast(1,Speed_swi_contrast(2,:)==contrast(contrastIDX)));
    end
    plotStatistics(p, speed_max(contrastIDX), contrast(contrastIDX), [])
end

xlabel('Contrast [mm]')
ylabel('Trials to expert')
title('Learning time over contrast')
%xline(6,'--','Performance cutoff','LabelHorizontalAlignment','center','LabelVerticalAlignment','middle')
xlim([10 22]); set ( gca, 'xdir', 'reverse')
legend('Initial rule','Reversed rule','Location','southeast','Box','off')

%% Comparison between initial and reversed rule
% compare the learning time as a factor between the switched and initial rule
if isequal(cohorts, [11 12 15 16])
    % first adjust the speed_ini_contrast array so it only contains animals trained on both rules
    % -> for now this is hard-coded !!!!
    speed_ini_adjust = Speed_ini_contrast;
    speed_ini_adjust(:,21) = []; speed_ini_adjust(:,14:18) = [];

    % now we calculate the factor for each contrast and compare them to contrast 20mm
    factor = arrayfun(@(c) Speed_swi_contrast(1,Speed_swi_contrast(2,:)==c)./speed_ini_adjust(1,speed_ini_adjust(2,:)==c), contrast, 'UniformOutput', false);
    factor_mean = mean([factor{:}]);
    for i = 1:length(factor)-1
        [p,~] = ranksum(factor{1,4},factor{1,i},'tail','right');
        if p <= 0.05
            fprintf('The factor between contrast 20mm and contrast %dmm is significantly different (p=%.2f).\n', contrast(i), p)
        else
            fprintf('The factor between contrast 20mm and contrast %dmm is not significantly different (p=%.2f).\n', contrast(i), p)
        end
    end
end

% line plot learning time (contrast 20mm)
figure; hold on
Speed_ini_20 = Speed_ini_contrast(1,Speed_ini_contrast(2,:)==20);
Speed_swi_20 = Speed_swi_contrast(1,Speed_swi_contrast(2,:)==20);
% plot all individual animals
%xvalues = ones(1,length(Speed_ini_20)); scatter(xvalues,Speed_ini_20, 'k','filled')
%xvalues = ones(1,length(Speed_swi_20)); scatter(xvalues+1,Speed_swi_20, 'k','filled')
% connect the pairs
% -> the logic of the Speed-array guarantes that animal 1 in the initial array is he same animal 1 in the reversed array
% -> this might not be true if the input data is changed!!
for i = 1:length(Speed_swi_20)
    plot([1,2],[Speed_ini_20(i),Speed_swi_20(i)],'Color','k','LineStyle',':')
end
% plot the mean
plot([1,2],[mean(Speed_ini_20), mean(Speed_swi_20)], 'Color', 'k', 'LineWidth', 1.5)
%statistics
[~,p_paired] = ttest(Speed_ini_20(1,1:length(Speed_swi_20)), Speed_swi_20);
plotStatistics(p_paired, speed_max(contrast == 20), 1, 2)
errorbar(0.9,mean(Speed_ini_20),std(Speed_ini_20), 'o', 'MarkerFaceColor', [0.1294 0.4 0.6745], 'Color', [0.1294 0.4 0.6745])
errorbar(2.1,mean(Speed_swi_20),std(Speed_swi_20), 'o', 'MarkerFaceColor', [0.9373 0.5412 0.3843], 'Color', [0.9373 0.5412 0.3843])
% add labels and title
title('Learning time per animal')
xticks([1,2]), xticklabels({'Initial rule','Reversed rule'})
ylabel('Trials to expert')

% line plot learning speed (contrast 20mm)
figure; hold on
cohortData = horzcat(animalData.cohort(cohorts(contrastOrder == 20)).animal);
FieldofChoice = {'slope_initial', 'slope_second'};

Slope_ini_20 = horzcat(cohortData.(FieldofChoice{1}));
Slope_swi_20 = horzcat(cohortData.(FieldofChoice{2}));
Slope_ini_std = std(Slope_ini_20,0,2,'omitnan');
Slope_ini_mean = mean(Slope_ini_20,2,'omitnan');
Slope_swi_std = std(Slope_swi_20,0,2,'omitnan');
Slope_swi_mean = mean(Slope_swi_20,2,'omitnan');

for i = 1:length(Slope_swi_20)
    plot([1,2],[Slope_ini_20(i),Slope_swi_20(i)],'Color','k', 'LineStyle', ':')
end
plot([1,2],[Slope_ini_mean , Slope_swi_mean], 'Color', 'k', 'LineWidth', 2)

[~,p_paired] = ttest(Slope_ini_20, Slope_swi_20);
slope_max = max(horzcat(Slope_ini_20,Slope_swi_20));
plotStatistics(p_paired,slope_max,1,2)
errorbar(0.9,Slope_ini_mean,Slope_ini_std, 'o', 'MarkerFaceColor', [0.1294 0.4 0.6745], 'Color', [0.1294 0.4 0.6745])
errorbar(2.1,Slope_swi_mean,Slope_swi_std, 'o', 'MarkerFaceColor', [0.9373 0.5412 0.3843], 'Color', [0.9373 0.5412 0.3843])

title('Learning speed per animal')
xticks([1,2]), xticklabels({'Initial rule','Reversed rule'})
ylabel('Slope of logistic fit')
