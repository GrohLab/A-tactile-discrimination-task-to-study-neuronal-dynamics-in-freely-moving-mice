%% Quantify learning instability in BC lesioned mice
% Get mice learning information
close all; clearvars; clc
currentFolder = pwd;
fileName = fullfile(currentFolder,'\RawData\animalData.mat');
load(fileName,'animalData')

% Cohort 24 represents the BC lesion intervention group
% Mice 28, 29, 32, and 33 were ablated from the beginning
% Mice 26, 27, 30, and 31 were ablated after expert performance
cohortData = animalData.cohort(24);
beginningIdx = [3,4,7,8];
expertIdx = [1,2,5,6];

% Define if you want to analyze all trials or only until/starting from threshold crossing 

answer = questdlg('Would you like to analyze all trials of initial learning?', ...
    'Trial selection', ...
    'Yes','No, only until threshold crossing','No, starting from threshold crossing','Yes');
switch answer
    case 'Yes'
        analysisFlag = 1;
    case 'No, only until threshold crossing'
        analysisFlag = 2;
    case 'No, starting from threshold crossing'
        analysisFlag = 3;
end

dPrimeVals = cell(1,8);
for idx = 1:height(cohortData.animal(:))
    switch analysisFlag 
        % Start with 200 trial offset as d primes are calculated for the
        % past 200 trials
        case 1
            dPrimeVals{idx} = cohortData.animal(idx).dvalues_trials(201:cohortData.animal(idx).stage2_trialcount{3,2});
        case 2
            dPrimeVals{idx} = cohortData.animal(idx).dvalues_trials(201:cohortData.animal(idx).intersec_initial);
        case 3
            dPrimeVals{idx} = cohortData.animal(idx).dvalues_trials(cohortData.animal(idx).intersec_initial+1:cohortData.animal(idx).stage2_trialcount{3,2});
    end
end

%% Coefficient of variation (CV) in the trial based learning increase (first derivative)

diffAblated = cell(1,4);
diffNative = cell(1,4);
for idx = 1:4
    diffAblated{idx} = diff(dPrimeVals{beginningIdx(idx)});
    diffNative{idx} = diff(dPrimeVals{expertIdx(idx)});
end

diffAblated_all = vertcat(diffAblated{:});
diffNative_all = vertcat(diffNative{:});

figure('Name','LearningDiffsHistoComp')
title('Learning diff between successive trials in ablated and native mice')
colorpalette = {'#009933';'#cc0000'}; 
cmap = cell2mat(cellfun(@(x) hex2rgb(x), colorpalette, 'UniformOutput', false));
colormap(cmap);
nhist({diffAblated_all, diffNative_all},'legend',{'Ablated','Native'},...
    'box','samebins','binfactor',1,'color','colormap','proportion');

% Plot the proportion of negative trial performance progression
negativeTrials_ablated = cellfun(@(x) sum(x<0)/numel(x), diffAblated);
negativeTrials_native = cellfun(@(x) sum(x<0)/numel(x), diffNative);

p = ranksum(negativeTrials_ablated, negativeTrials_native);

% Plot mean with 95% confidence interval
figure('Name','NegTrialProportion_MeanCI')
title('Proportion of trials with performance drop')
hold on
yval_mean = mean(negativeTrials_ablated,'omitmissing');
yval_std = std(negativeTrials_ablated,'omitmissing');
yval_ci = (yval_std*1.96)./sqrt(numel(negativeTrials_ablated));
plot(ones(1,numel(negativeTrials_ablated)),negativeTrials_ablated,'o')
errorbar(1,yval_mean,yval_ci,'o',...
    'MarkerFaceColor','#000000','Color','#000000','LineWidth',2);

yval_mean = mean(negativeTrials_native,'omitmissing');
yval_std = std(negativeTrials_native,'omitmissing');
yval_ci = (yval_std*1.96)./sqrt(numel(negativeTrials_native));
plot(2*ones(1,numel(negativeTrials_native)),negativeTrials_native,'o')
errorbar(2,yval_mean,yval_ci,'o',...
    'MarkerFaceColor','#000000','Color','#000000','LineWidth',2);

yl = ylim;
if p <= 0.001
    plot([1.2 1.8], [yl(1)+diff(yl)*0.8 yl(1)+diff(yl)*0.8], '-k'),  text(1.5, yl(1)+diff(yl)*0.825, '***','HorizontalAlignment','center','FontSize',12)
elseif p <= 0.01
    plot([1.2 1.8], [yl(1)+diff(yl)*0.8 yl(1)+diff(yl)*0.8], '-k'),  text(1.5, yl(1)+diff(yl)*0.825, '**','HorizontalAlignment','center','FontSize',12)
elseif p <= 0.05
    plot([1.2 1.8], [yl(1)+diff(yl)*0.8 yl(1)+diff(yl)*0.8], '-k'),  text(1.5, yl(1)+diff(yl)*0.825, '*','HorizontalAlignment','center','FontSize',12)
else
    plot([1.2 1.8], [yl(1)+diff(yl)*0.8 yl(1)+diff(yl)*0.8], '-k'),  text(1.5, yl(1)+diff(yl)*0.825, 'n.s.','HorizontalAlignment','center','FontSize',12)
end

xticks(1:2)
xticklabels({'Ablated','Native'})
xlim([0.5 2.5])
ylabel('Proportion')

%% Deviation from the sigmoid model fit (Residual Analysis)

% Start 200 trials after stage beginn, as the d' is averaged
% over the past 200 trials.
trialnum = 200;

residAblated = cell(1,4);
residNative = cell(1,4);
for idx = 1:4
    yvals_ablated = dPrimeVals{beginningIdx(idx)};
    yvals_native = dPrimeVals{expertIdx(idx)};
    
    yval = yvals_ablated - min(yvals_ablated);
    x = 1:1:numel(yval);

    % Fit logistic function
    [params]=sigm_fit(x,yval,[],[],0);
    fitValues = params(1) + (params(2) - params(1))./ (1 + 10.^((params(3) - x) * params(4)));
    fitValues = fitValues + min(yvals_ablated);

    residAblated{idx} = abs(fitValues' - yvals_ablated);

    yval = yvals_native - min(yvals_native);

    x = 1:1:numel(yval);

    % Fit logistic function
    [params]=sigm_fit(x,yval,[],[],0);
    fitValues = params(1) + (params(2) - params(1))./ (1 + 10.^((params(3) - x) * params(4)));
    fitValues = fitValues + min(yvals_native);
    residNative{idx} = abs(fitValues' - yvals_native);
end

residAblated_all = vertcat(residAblated{:});
residNative_all = vertcat(residNative{:});

figure('Name','FitResidualsHistoComp')
title('Residuals of the sigmoidal fit in ablated and native mice')
colorpalette = {'#009933';'#cc0000'}; 
cmap = cell2mat(cellfun(@(x) hex2rgb(x), colorpalette, 'UniformOutput', false));
colormap(cmap);
nhist({residAblated_all, residNative_all},'legend',{'Ablated','Native'},...
    'box','samebins','binfactor',1,'color','colormap','proportion');

stdTemp = std(residAblated_all,'omitmissing');
ciTemp = (stdTemp*1.96)./sqrt(numel(residAblated_all));
fprintf('\nResiduals ablated [mean+-95%%CI]: %.4f+-%.4f',mean(residAblated_all,'omitmissing'),ciTemp)

stdTemp = std(residNative_all,'omitmissing');
ciTemp = (stdTemp*1.96)./sqrt(numel(residNative_all));
fprintf('\nResiduals native [mean+-95%%CI]: %.4f+-%.4f',mean(residNative_all,'omitmissing'),ciTemp)

p = ranksum(residAblated_all, residNative_all);
fprintf('\np-value: %e\n', p)

%% Autocorrelation analysis

% Define a window of trials before and after each trial
window_size = 20;

% Compute the autocorrelation within the window for each trial
autoCorrAblated = cell(1,4);
absoluteAblated = cell(1,4);
autoCorrNative = cell(1,4);
absoluteNative = cell(1,4);

for idx = 1:4
    % Autocorrelation of ablated mice
    num_trials = numel(dPrimeVals{beginningIdx(idx)});
    autocorr_results = nan(num_trials, 4 * window_size + 1);
    absolute_results = nan(num_trials, 2 * window_size + 1);

    for i = 1:num_trials
        % Define the window limits
        start_idx = max(1, i - window_size);
        start_diff = abs(min(0, i-1-window_size))+1;
        
        end_idx = min(num_trials, i + window_size);
        end_diff = 2*window_size+1 - (max(num_trials, i + window_size)-num_trials);

        % Extract the local window of d' values
        local_window = dPrimeVals{beginningIdx(idx)}(start_idx:end_idx);

        % Compute autocorrelation (normalized to make max = 1)
        local_autocorr = xcorr(local_window, 'coeff');

        % Store the results (align to center)
        len = length(local_autocorr);
        autocorr_results(i, (-floor(len/2):floor(len/2))+2*window_size+1) = local_autocorr;
        absolute_results(i, start_diff:end_diff) = local_window-dPrimeVals{beginningIdx(idx)}(i);
    end
    autoCorrAblated{idx} = autocorr_results;
    absoluteAblated{idx} = absolute_results;

    % Autocorrelation of native mice
    num_trials = numel(dPrimeVals{expertIdx(idx)});
    autocorr_results = nan(num_trials, 4 * window_size + 1);
    absolute_results = nan(num_trials, 2 * window_size + 1);

    for i = 1:num_trials
        % Define the window limits
        start_idx = max(1, i - window_size);
        start_diff = abs(min(0, i-1-window_size))+1;
        
        end_idx = min(num_trials, i + window_size);
        end_diff = 2*window_size+1 - (max(num_trials, i + window_size)-num_trials);

        % Extract the local window of d' values
        local_window = dPrimeVals{expertIdx(idx)}(start_idx:end_idx);

        % Compute autocorrelation (normalized to make max = 1)
        local_autocorr = xcorr(local_window, 'coeff');

        % Store the results (align to center)
        len = length(local_autocorr);
        autocorr_results(i, (-floor(len/2):floor(len/2))+2*window_size+1) = local_autocorr;
        absolute_results(i, start_diff:end_diff) = local_window-dPrimeVals{expertIdx(idx)}(i);
    end
    autoCorrNative{idx} = autocorr_results;
    absoluteNative{idx} = absolute_results;
end

% Compute the average autocorrelation over all trials
mean_autocorr_ablated = mean(vertcat(autoCorrAblated{:}), 1, 'omitmissing'); 
mean_autocorr_native = mean(vertcat(autoCorrNative{:}), 1,'omitmissing');

lags = -2*window_size:2*window_size; % Define lag values

% Plot the average autocorrelation function
figure
hold on
p(1) = stem(lags, mean_autocorr_ablated);
p(2) = stem(lags, mean_autocorr_native);
legend(p,{'Ablated','Native'})
xlabel('Lag (trials)');
ylabel('Autocorrelation');
title('Mean Single-Trial Autocorrelation of Native Mice');
grid on;

% Compute the average absoulte values over all trials
mean_abs_ablated = mean(vertcat(absoluteAblated{:}), 1, 'omitmissing'); 
mean_abs_native = mean(vertcat(absoluteNative{:}), 1,'omitmissing');

lags = -window_size:window_size; % Define lag values

% Plot the average autocorrelation function
figure
hold on
p(1) = stem(lags, mean_abs_ablated);
p(2) = stem(lags, mean_abs_native);
legend(p,{'Ablated','Native'})
xlabel('Lag (trials)');
ylabel('Absolute diff');
title('Mean Single-Trial Absolute Diffs of Native Mice');
grid on;