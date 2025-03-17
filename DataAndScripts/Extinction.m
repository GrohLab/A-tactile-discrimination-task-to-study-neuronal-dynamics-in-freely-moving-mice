%% Extinction
% only works if animalData.m is loaded
currentFolder = pwd;
load(fullfile(currentFolder,'/RawData/animalData'))

%% create dprime-array for sessions 
% -> last four sessions intial rule, reversed rule and first four sessions extinction
% -> animals per row and sessions per column

cohortData = animalData.cohort(12).animal; %only cohort that underwent extinction
numMice = length(cohortData);
numSes = 4;

% extinction phase is stage P3.6 for all animals in cohort 12
% P3.2 is the conditioning phase for all animals
% P3.4 is the reversal phase for all animals
alldprime = NaN (sum(numMice),numSes*3);
for mouseIDX = 1:numMice
    isP6 = contains(cohortData(mouseIDX).session_names,'P3.6');
    isP2 = contains(cohortData(mouseIDX).session_names,'P3.2');
    isP4 = contains(cohortData(mouseIDX).session_names,'P3.4');
    sesFlag_first = find(isP6, 1, 'first');
    sesFlag_last_rev = find(isP4, 1, 'last');
    sesFlag_last_cond = find(isP2, 1, 'last');

    dprime_cond = cohortData(mouseIDX).dvalues_sessions(sesFlag_last_cond-numSes+1:sesFlag_last_cond);
    dprime_before = cohortData(mouseIDX).dvalues_sessions(sesFlag_last_rev-numSes+1:sesFlag_last_rev);
    dprime_after = cohortData(mouseIDX).dvalues_sessions(sesFlag_first:sesFlag_first+numSes-1);

    if isempty(dprime_after)
        continue
    else
        alldprime(mouseIDX, 1:numSes) = dprime_cond;
        alldprime(mouseIDX, numSes+1:numSes*2) = dprime_before;
        alldprime(mouseIDX, numSes*2+1:numSes*3) = dprime_after;
    end
end

% remove NaNs that result from animals not going through the extinction stage
alldprime(isnan(alldprime(:,1)),:) = [];

%% prepare array for plotting
mouseFlag = 1:height(alldprime);
dprime_cond =  cell2mat(arrayfun(@(a) vertcat(alldprime(a,1:numSes)), mouseFlag, 'UniformOutput', false));
dprime_before =  cell2mat(arrayfun(@(a) vertcat(alldprime(a,numSes+1:numSes*2)), mouseFlag, 'UniformOutput', false));
dprime_after =  cell2mat(arrayfun(@(a) vertcat(alldprime(a,numSes*2+1:numSes*3)), mouseFlag, 'UniformOutput', false));

%%
figure; hold on;
boxchart(ones(1,length(dprime_cond)), dprime_cond, 'BoxFaceColor', [0.1294 0.4 0.6745])
scatter(ones(1,length(dprime_cond)), dprime_cond,'Marker','.','Jitter','on','MarkerEdgeColor',[0.1294 0.4 0.6745])
boxchart(ones(1,length(dprime_before))+1, dprime_before, 'BoxFaceColor', [0.9373 0.5412 0.3843])
scatter(ones(1,length(dprime_before))+1, dprime_before,'Marker','.','Jitter','on','MarkerEdgeColor',[0.9373 0.5412 0.3843])
boxchart(ones(1,length(dprime_after))+2, dprime_after, 'BoxFaceColor', 'k', 'MarkerStyle', 'none')
scatter(ones(1,length(dprime_after))+2, dprime_after,'Marker','.','Jitter','on','MarkerEdgeColor','k')

yline([1.65, 1.65],'Color','black','LineStyle','--')
xticks([1 2 3]); xticklabels({'Initial rule','Reversed rule', 'Extinction'})
ylabel('d prime')
title('Population performance before and after extinction')

%% Extinction progression
% create array with all extinctions essions (in total 8, for previous analysis only used 4)
all_ext = NaN(numMice,8);
for mouseIDX = 1:numMice
    isP6 = contains(cohortData(mouseIDX).session_names,'P3.6'); %extinction phase
    sesFlag_first = find(isP6, 1, 'first');
    sesFlag_last= find(isP6, 1, 'last');

    dprime_ext = cohortData(mouseIDX).dvalues_sessions(sesFlag_first:sesFlag_last);
    numSes = length(dprime_ext);

    if isempty(dprime_after)
        continue
    else
        all_ext(mouseIDX, 1:numSes) = dprime_ext;
    end
end
all_ext(isnan(all_ext(:,1)),:) = [];

% calculate mean and std
dprime_mean = mean(all_ext,1,'omitnan');  dprime_mean(isnan(dprime_mean)) =[];
dprime_std = std(all_ext,0,1,'omitnan'); dprime_std(isnan(dprime_std)) =[];
curve1 = dprime_mean + dprime_std;
curve2 = dprime_mean - dprime_std;

% plot data
figure; title('Extinction dynamics'); xlabel('Sessions')

yyaxis right;
fill([1:length(curve1) fliplr(1:length(curve1))], [curve1 fliplr(curve2)],[0 0 .85],...
    'FaceColor',[0.6 0.32 0.65], 'EdgeColor','none','FaceAlpha',0.5); hold on
plot((1:length(dprime_mean)),dprime_mean, 'Color', [0.6 0.32 0.65], 'LineWidth', 2, 'LineStyle','-')

% --------- calculate lick rates for aperture state -----------------------
animals = {'#33','#34','#35','#36','#38'};
HS_Trials = cell(length(animals),1);
for mouseIDX = 1:length(animals)
    [rate_w, rate_n, HST] = get_lickrates(animals{mouseIDX});

    lickrate_w(mouseIDX,:) = rate_w;
    lickrate_n(mouseIDX,:) = rate_n;
    HS_Trials{mouseIDX} = HST;
end

% calculate mean and std wide
mean_rw = mean(lickrate_w,1,'omitnan');
std_rw = std(lickrate_w,0,1,'omitnan');
curve1 = mean_rw + std_rw;
curve2 = mean_rw - std_rw;
% plot data wide
yyaxis left;
fill([1:length(curve1) fliplr(1:length(curve1))], [curve1 fliplr(curve2)],[0 0 .85],...
    'FaceColor','k', 'EdgeColor','none','FaceAlpha',0.5); hold on
plot((1:length(mean_rw)),mean_rw, 'Color', 'k', 'LineWidth', 2, 'LineStyle','--')

% calculate mean and std narrow
mean_rn = mean(lickrate_n,1,'omitnan');
std_rn = std(lickrate_n,0,1,'omitnan');
curve1 = mean_rn + std_rn;
curve2 = mean_rn - std_rn;
% plot data narrow
fill([1:length(curve1) fliplr(1:length(curve1))], [curve1 fliplr(curve2)],[0 0 .85],...
    'FaceColor','k', 'EdgeColor','none','FaceAlpha',0.5); hold on
plot((1:length(mean_rn)),mean_rn, 'Color', 'k', 'LineWidth', 2,'LineStyle','-')

yyaxis left; ylabel('Lick rate'); ylim([0.88 1])
ax = gca; ax.YColor = 'k';
yyaxis right; ylabel('d prime')
ax = gca; ax.YColor = [0.6 0.32 0.65];
legend('','wide','','narrow')

%% look only at first session
for mouseIDX = 1:length(HS_Trials)
    HS_first = HS_Trials{mouseIDX}(1).HispeedTrials;
    Timestamps = cellfun(@(t) t(1), HS_first.Timestamps); [~,sortIDX] = sort(Timestamps);
    HS_first = HS_first(sortIDX,:);

    HS_second = HS_Trials{mouseIDX}(2).HispeedTrials;
    Timestamps = cellfun(@(t) t(1), HS_second.Timestamps); [~,sortIDX] = sort(Timestamps);
    HS_second = HS_second(sortIDX,:);
    
    HS_fs = vertcat(HS_first,HS_second); %concatenate first and second session

    % preallocate rate_nt and rate_wt in the first loop
    if mouseIDX == 1
        bin_size = 30;
        num_trials = arrayfun(@(m) height(vertcat(HS_Trials{m}(1).HispeedTrials, HS_Trials{m}(2).HispeedTrials)), 1:height(HS_Trials));
        num_bins = arrayfun(@(m) ceil(num_trials(m)/bin_size), 1:length(num_trials));
        rate_nt = NaN(length(animals),max(num_bins)); rate_wt = NaN(length(animals),max(num_bins));
    end
    axis_norm{mouseIDX} = linspace(0, 1, num_bins(mouseIDX));  %Rescaled trial axis (normalized to 0-1)

    for binIDX = 1:num_bins(mouseIDX)
        start_trial = (binIDX-1)*bin_size + 1;
        end_trial = min(binIDX*bin_size, height(HS_fs));
        binned_data = HS_fs(start_trial:end_trial,:);

        %calculate lick rate for binned trials
        for stateIDX = 1:2
            stateFlag = binned_data.Go_NoGo_Neutral_settingBased == stateIDX;
            licks = binned_data(stateFlag,:).Lick;
            licks = licks(~isnan(licks));
            rate = sum(licks)/length(licks);

            if stateIDX == 1
                rate_nt(mouseIDX,binIDX) = rate;
            elseif stateIDX == 2
                rate_wt(mouseIDX,binIDX) = rate;
            end
        end
    end
end

fig_binTrials = plot_patch(rate_nt', axis_norm,'g', 10);
plot_patch(rate_wt', axis_norm,'r', 10, fig_binTrials);
title(sprintf('Lick rates over binned trials for the first two sessions (bin size (%d trials))', char(bin_size)))
ylabel('Lick rates'), ylim([0.9 1])
xlabel('Training progression')
legend('narrow','','wide')
