%% Test the responsivness of cells on several behavioral metrics

close all; clearvars; clc
currentFolder = pwd;
fileName = fullfile(currentFolder,'\RawData\animalData.mat');
load(fileName,'animalData')

% Define brain areas
area_names = {'BC','VPM','POm','ZIv'};
area_colors = {'#377eb8','#4daf4a','#984ea3','#ff7f00'};

stageNum = 2;

all_sesNames = cell(1,6);
all_dprimes = cell(1,6);
for i = 1:6
    idx = find(animalData.cohort(12).animal(i).stage_sessionCount==stageNum);
    ses = animalData.cohort(12).animal(i).session_names(idx);
    dvals = animalData.cohort(12).animal(i).dvalues_sessions(idx);
    all_dprimes{i} = dvals;
    all_sesNames{i} = ses;
end
% If a certain stage is not represented for an animal, omit this individual
all_sesNames = all_sesNames(~cellfun(@isempty,all_sesNames));

all_dprimes = vertcat(all_dprimes{:});
all_sesNames = vertcat(all_sesNames{:});
[~,~,group] = histcounts(all_dprimes,'BinEdges',[-Inf,-1.65,-0.5,0.5,1.65,Inf]);
fileSelection = fullfile(fileparts(fileparts(all_sesNames(group==5))),'intan-signals\automatedCuration');

stageDescription = 'initialLearningExpert';

animalNum = cell2mat(cellfun(@(x) str2double(regexp(x,'#(\d+)','tokens','once')), fileSelection, 'UniformOutput', false));

% Check how many animals are analyzed
indiAnimals = unique(animalNum);

%% Locomotion vs. resting

% Framerate in Hz
video_fr = 60;
% Define moving window size
windSize = 0.2; % Size in sec
framesIdx = round(video_fr*windSize/2)-1;

% Tuning tables per session with n x 7 dimensions, n being the number of
% units, and the columns being: unitID, area, frLocomotion, frRest, p_value,
% timeLocomotion,timeRest
unitTuning = cell(1,numel(fileSelection));

unitTuningAnalyzed = {};
fileSelectionAnalyzed = {};

count = 1; % For progress bar
clear analysisFlag
for ses = 1:numel(fileSelection) % Use parfor for parallel computing
    if ismember(fileSelection{ses}, fileSelectionAnalyzed) && ~exist('analysisFlag','var')
        answer = questdlg('The locomotion-rest firing rates for these sessions have already been analyzed. Analyze again?',...
            'Analysis repetition','Yes (for all sessions)','No (for all sessions)','No (for all sessions)');
        if isequal(answer,'No (for all sessions)')
            analysisFlag = 0;
            unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
            continue
        else
            analysisFlag = 1;
        end
    elseif ismember(fileSelection{ses}, fileSelectionAnalyzed) && exist('analysisFlag','var') && ~analysisFlag
        unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
        continue
    end
    dataInfo = dir(fullfile(fileSelection{ses},'*all_channels.mat'));
    loadData = load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs');
    sortedData = loadData.sortedData;
    sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);

    clInfo = getClusterInfo(fullfile(fileSelection{ses},'cluster_info.tsv'));

    str_idx = regexp(fileSelection{ses},'#\d*','end');
    animalPath = fileSelection{ses}(1:str_idx);

    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')
    include = ismember(cell2mat(sortedData(:,3)), [1,2]) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for i = 1:size(sortedData,1)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{i,1})));
        switch depth
            case 1
                sortedData{i,4} = 'BC';
            case 1400
                sortedData{i,4} = 'POm';
            case 1700
                sortedData{i,4} = 'VPM';
            case 2400
                sortedData{i,4} = 'ZIv';
        end
    end

    WaveformInfo = dir(fullfile(dataInfo(1).folder, '*waveforms_all.mat'));
    try load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')
    catch
        fprintf('Couldn''t find waveforms_all.mat file for loading the clWaveforms variable.')
    end

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(clWaveforms),1);
        for ii = 1:height(sortedData)
            unitOrder(ii) = find(ismember(clWaveforms(:,1),sortedData{ii,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the sortedData.')
    end

    load(fullfile(fileSelection{ses},'FrameInfo.mat'),'FrameInfo')

    rhdFile = dir(fullfile(fileparts(fileSelection{ses}),'*.rhd'));
    [sampleNum,sampleRate] = Intan_sampleNum(fullfile(rhdFile(1).folder,rhdFile(1).name));
    totalDuration = sampleNum/sampleRate; % In sec

    frLocomotion = nan(height(sortedData),1);
    frRest = nan(height(sortedData),1);
    timeLocomotion = nan(height(sortedData),1);
    timeRest = nan(height(sortedData),1);
    p_value = nan(height(sortedData),1);
    % Calculate tuning index of each unit
    for unit = 1:height(sortedData)
        spikeTimesCategory = [];
        spikeTimesCategoryShuff = cell(1,100);
        logicalCategory = logical([]);
        logicalCategoryShuff = cell(1,100);

        % Each millisecond with one value to track the total time with a moving window
        totaltimeLocomotion = false(1, round(totalDuration*1000));
        totaltimeRest = false(1, round(totalDuration*1000));

        spikeTimes = sortedData{unit,2}; % In sec
        spikeTimes_shuffled = NaN(numel(sortedData{unit,2}),100);
        rng("default")
        for shuff = 1:100
            spikeTimes_shuffled(:,shuff) = spikeTimes+rand*totalDuration;
        end
        spikeTimes_shuffled(spikeTimes_shuffled>totalDuration) = spikeTimes_shuffled(spikeTimes_shuffled>totalDuration)-totalDuration;

        % Get velocity from only within a defined window of the linear track (FrameInfo.inside), in order
        % to rule out unspecific effects of whisker interactions close to the reward sites.
        velocity = FrameInfo.velocity(FrameInfo.inside); % Velocities on linear track
        frameNum = FrameInfo.frameNum(FrameInfo.inside); % Respective frame numbers
        frameTs = round(FrameInfo.time(FrameInfo.inside)*1000); % Respective frame time stamps [msec] for total behavior times
        for frame = 1:numel(frameNum)
            ts = frameTs(frame)-floor(windSize*500):frameTs(frame)+floor(windSize*500); % Timestamps in msec (!) for total behavior times
            velWind = velocity(max([1, frame+1-framesIdx]):min([numel(frameNum), frame+framesIdx]));
            % Only calculate velocities, if 3 or less frames are missing
            numWind = frameNum(max([1, frame+1-framesIdx]):min([numel(frameNum), frame+framesIdx]));

            % Periods of velocities > 100 mm/s lasting more than 200 ms were defined as "locomotion"
            % and periods with velocities < 10 mm/s as "rest".
            if mean(velWind,'omitmissing') > 100 && sum(diff(numWind)-1) <=3
                % Count spikes in time frame
                spikesInWind = spikeTimes(spikeTimes>ts(1)/1000 & spikeTimes<=ts(end)/1000);
                [spikeTimesCategory,~,newVals] = union(spikeTimesCategory, spikesInWind);
                logicalCategory = [logicalCategory; true(numel(newVals),1)]; %#ok<AGROW>
                totaltimeLocomotion(ts) = true; % In msec
                for shuff = 1:100
                    spikesInWind = spikeTimes_shuffled(spikeTimes_shuffled(:,shuff)>ts(1)/1000 &...
                        spikeTimes_shuffled(:,shuff)<=ts(end)/1000,shuff);
                    [spikeTimesCategoryShuff{shuff},~,newVals] = union(spikeTimesCategoryShuff{shuff}, spikesInWind);
                    logicalCategoryShuff{shuff} = [logicalCategoryShuff{shuff}; true(numel(newVals),1)];
                end
            elseif mean(velWind,'omitmissing') < 10 && sum(diff(numWind)-1) <=3
                spikesInWind = spikeTimes(spikeTimes>ts(1)/1000 & spikeTimes<=ts(end)/1000);
                [spikeTimesCategory,~,newVals] = union(spikeTimesCategory, spikesInWind);
                logicalCategory = [logicalCategory; false(numel(newVals),1)]; %#ok<AGROW>
                totaltimeRest(ts) = true; % In msec
                for shuff = 1:100
                    spikesInWind = spikeTimes_shuffled(spikeTimes_shuffled(:,shuff)>ts(1)/1000 &...
                        spikeTimes_shuffled(:,shuff)<=ts(end)/1000,shuff);
                    [spikeTimesCategoryShuff{shuff},~,newVals] = union(spikeTimesCategoryShuff{shuff}, spikesInWind);
                    logicalCategoryShuff{shuff} = [logicalCategoryShuff{shuff}; false(numel(newVals),1)];
                end
            end
        end

        % Calculate overall firing rate
        % Add-one smoothing (also called Laplace smoothing) for better stability, when time windows are small
        timeLocomotion(unit) = sum(totaltimeLocomotion)/1000; % In sec
        timeRest(unit) = sum(totaltimeRest)/1000; % In sec
        frLocomotion(unit) = (sum(logicalCategory)+1)/(timeLocomotion(unit)+1);
        frLocomotionShuff = cellfun(@(x) (sum(x)+1)/(timeLocomotion(unit)+1), logicalCategoryShuff);

        frRest(unit) = (sum(~logicalCategory)+1)/(timeRest(unit)+1);
        frRestShuff = cellfun(@(x) (sum(~x)+1)/(timeRest(unit)+1), logicalCategoryShuff);

        observed_diff = frLocomotion(unit) - frRest(unit);
        observed_diffShuff = frLocomotionShuff - frRestShuff;

        if ~isnan(observed_diff)
            p_value(unit) = sum(abs(observed_diffShuff) > abs(observed_diff))/numel(observed_diffShuff);
        else
            p_value(unit) = NaN;
        end

    end
    unitTuning{ses} = cell2table([sortedData(:,1), sortedData(:,4), num2cell(frLocomotion), ...
        num2cell(frRest), num2cell(p_value), num2cell(timeLocomotion), num2cell(timeRest)],...
        "VariableNames",{'unitID','area','frLocomotion','frRest','p_value','timeLocomotion','timeRest'});

    % Progress bar (without parallel processing)
    if ses==numel(fileSelection)
        fprintf('100%% of sessions analyzed.\n')
    elseif ses/numel(fileSelection)>=0.05*count
        fprintf('%i%% of sessions analyzed.\n',5*count)
        count = count+1;
    end
end

unitTuning_concat = vertcat(unitTuning{:});

for ar = 1:numel(area_names)
    areaIdx = contains(unitTuning_concat.area,area_names{ar});

    % Calculate the mean firing rate for each condition

    meanRest = mean(unitTuning_concat.frRest(unitTuning_concat.p_value<=0.05 & areaIdx),'omitnan');
    meanLocomotion = mean(unitTuning_concat.frLocomotion(unitTuning_concat.p_value<=0.05 & areaIdx),'omitnan');

    % Plot individual value pairs (thin gray lines)
    fig = figure('Name',sprintf('FR_Comparison_%s',area_names{ar}));
    hold on
    plot([1, 2], [unitTuning_concat.frRest(unitTuning_concat.p_value>0.05 & areaIdx),...
        unitTuning_concat.frLocomotion(unitTuning_concat.p_value>0.05 & areaIdx)],...
        '.','Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    plot([1, 2], [unitTuning_concat.frRest(unitTuning_concat.p_value<=0.05 & areaIdx),...
        unitTuning_concat.frLocomotion(unitTuning_concat.p_value<=0.05 & areaIdx)],...
        '.','Color', area_colors{ar}, 'LineWidth', 0.5);

    % Plot mean firing rates as thicker line
    plot([1, 2], [meanRest, meanLocomotion], 'Color', area_colors{ar}, 'LineWidth', 2);

    set(gca, 'XTick', [1, 2], 'XTickLabel', {'Rest', 'Locomotion'})
    ylabel('Firing rate (Hz)')
    title('Comparison of behavioral states')
    xlim([0.8 2.7])

    axes('Position',[.75 .75 .1 .1]), box off
    piePlot = pie([sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frLocomotion-unitTuning_concat.frRest > 0), ...
        sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frLocomotion-unitTuning_concat.frRest < 0), ...
        sum(areaIdx & unitTuning_concat.p_value>0.05), ...
        sum(areaIdx & isnan(unitTuning_concat.frLocomotion-unitTuning_concat.frRest))], {'Increased','Decreased','n.s.','NaN'});
    patchHand = findobj(piePlot, 'Type', 'Patch');
    arrayfun(@(x) set(patchHand(x), 'FaceColor', area_colors{ar}),(1:4));
    patchHand(1).FaceAlpha = 1.0;
    patchHand(2).FaceAlpha = 0.8;
    patchHand(3).FaceAlpha = 0.6;
    patchHand(4).FaceAlpha = 0.4;

    axes('Position',[.75 .55 .1 .1]), box off
    piePlot = pie([sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frLocomotion-unitTuning_concat.frRest > 0), ...
        sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frLocomotion-unitTuning_concat.frRest < 0), ...
        sum(areaIdx & unitTuning_concat.p_value>0.05)], {'Increased','Decreased','n.s.'});
    patchHand = findobj(piePlot, 'Type', 'Patch');
    arrayfun(@(x) set(patchHand(x), 'FaceColor', area_colors{ar}),(1:3));
    patchHand(1).FaceAlpha = 1.0;
    patchHand(2).FaceAlpha = 0.8;
    patchHand(3).FaceAlpha = 0.6;

    hold off

    [~,p,ci] = ttest(unitTuning_concat.frRest(areaIdx), unitTuning_concat.frLocomotion(areaIdx));
    [~,pOnlyTuned,ciOnlyTuned] = ttest(unitTuning_concat.frRest(areaIdx & unitTuning_concat.p_value<=0.05), unitTuning_concat.frLocomotion(areaIdx & unitTuning_concat.p_value<=0.05));

    Info = struct('cellNum_all', {sum(areaIdx)},...
        'cellNum_sign', {sum(unitTuning_concat.p_value<=0.05 & areaIdx)},...
        'Incr_Decr_NonSig_NaN', {[sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frLocomotion-unitTuning_concat.frRest > 0), ...
        sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frLocomotion-unitTuning_concat.frRest < 0), ...
        sum(areaIdx & unitTuning_concat.p_value>0.05), ...
        sum(areaIdx & isnan(unitTuning_concat.frLocomotion-unitTuning_concat.frRest))]}, ...
        'meanRest', {meanRest},...
        'meanLocomotion',{meanLocomotion},...
        'ttest_p_all', {p},...
        'ttest_ci_all', {ci},...
        'ttest_p_onlyTuned', {pOnlyTuned},...
        'ttest_ci_onlyTuned', {ciOnlyTuned});
    fig.UserData = Info;

    % Save figures
    destfile = fullfile(destinationDir,sprintf('%s.fig',fig.Name));
    savefig(fig, destfile)

end

%% Putative spatially tuned cells
% Check if some units respond to the position on the maze

% Model taken from Pillow and Park 2016 "Adaptive Bayesian Methods for
% Closed-Loop Neurophysiology", and expanded with a linear term for the
% speed effect:
model_fun = @(params, x) ...
    params(1) * exp(-(x(:,1) - params(2)).^2 / (2 * params(3)^2)) + params(4) * x(:,2) + params(5);
% params(1) is 𝑎 (amplitude),
% params(2) is 𝜇 (center of the spatial tuning),
% params(3) is 𝜎 (width of the spatial tuning),
% params(4) is 𝑏 (speed effect),
% params(5) is 𝑐 (baseline firing rate).

destinationDir = fullfile('Z:\Filippo\Animals\Cohort12_33-38\Analysis-Figures\Behavioral-Metrics\Place-Cells',stageDescription{:});
if ~exist(destinationDir,'dir')
    mkdir(destinationDir);
end

% Define moving window size
bin_size = 0.1; % 100 ms bins

% Tuning arrays per session with n x 13 dimensions, n being the number of
% units, and the columns being unitID, area, modulationSign, amplitude, amplitudeCI,...
% centerPosition, centerPositionCI, width, widthCI, speedCoef, speedCoefCI,...
% baseline, baselineCI
unitTuningAnalyzed = {};
fileSelectionAnalyzed = {};

count = 1; % For progress bar
clear analysisFlag
unitTuning = cell(1,numel(fileSelection));
for ses = 1:numel(fileSelection)
    if ismember(fileSelection{ses}, fileSelectionAnalyzed) && ~exist('analysisFlag','var')
        answer = questdlg('The spatially tuned cells for these sessions have already been analyzed. Analyze again?',...
            'Analysis repetition','Yes (for all sessions)','No (for all sessions)','No (for all sessions)');
        if isequal(answer,'No (for all sessions)')
            analysisFlag = 0;
            unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
            continue
        else
            analysisFlag = 1;
        end
    elseif ismember(fileSelection{ses}, fileSelectionAnalyzed) && exist('analysisFlag','var') && ~analysisFlag
        unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
        continue
    end

    % Load spike times of that session
    dataInfo = dir(fullfile(fileSelection{ses},'*all_channels.mat'));
    loadData = load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs');
    sortedData = loadData.sortedData;
    sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);
    clInfo = getClusterInfo(fullfile(fileSelection{ses},'cluster_info.tsv'));

    str_idx = regexp(fileSelection{ses},'#\d*','end');
    animalPath = fileSelection{ses}(1:str_idx);

    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')
    include = ismember(cell2mat(sortedData(:,3)), [1,2]) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for i = 1:size(sortedData,1)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{i,1})));
        switch depth
            case 1
                sortedData{i,4} = 'BC';
            case 1400
                sortedData{i,4} = 'POm';
            case 1700
                sortedData{i,4} = 'VPM';
            case 2400
                sortedData{i,4} = 'ZIv';
        end
    end

    WaveformInfo = dir(fullfile(dataInfo(1).folder, '*waveforms_all.mat'));
    try load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')
    catch
        fprintf('Couldn''t find waveforms_all.mat file for loading the clWaveforms variable.')
    end

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(clWaveforms),1);
        for ii = 1:height(sortedData)
            unitOrder(ii) = find(ismember(clWaveforms(:,1),sortedData{ii,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the sortedData.')
    end

    load(fullfile(fileSelection{ses},'FrameInfo.mat'),'FrameInfo')

    rhdFile = dir(fullfile(fileparts(fileSelection{ses}),'*.rhd'));
    [sampleNum,sampleRate] = Intan_sampleNum(fullfile(rhdFile(1).folder,rhdFile(1).name));
    totalDuration = sampleNum/sampleRate; % In sec

    edges = 0:bin_size:max(totalDuration);
    centerPoints = edges(1:end-1) + bin_size / 2;
    % Create an empty array to store the filtered firing rates
    includeBins = false(1,numel(edges)-1);

    % Get bars for whisker touch events
    startTimes = strfind(FrameInfo.inside', [0 1]);
    if FrameInfo.inside(1)
        startTimes = [1, startTimes+1];
    end
    endTimes = strfind(FrameInfo.inside', [1 0]);
    if FrameInfo.inside(end)
        endTimes = [endTimes, numel(FrameInfo.inside)]; %#ok<AGROW>
    end
    % Loop through each frame where the mouse is within the FOV
    for i = 1:numel(startTimes)
        % Find the firing rate bins that overlap with this frame time window
        bin_idx = (edges(1:end-1) >= FrameInfo.time(startTimes(i))) & (edges(1:end-1) < FrameInfo.time(endTimes(i)));

        % Append the corresponding firing rates to the filtered list
        includeBins = includeBins | bin_idx;
    end

    % X-position of the mouse at each time point
    position = interp1(FrameInfo.time(FrameInfo.inside), cellfun(@(x) x(1), FrameInfo.position(FrameInfo.inside)), centerPoints); % interpolate position to time bins
    position = position(includeBins);
    % Speed of the mouse at each time point
    speed = interp1(FrameInfo.time(FrameInfo.inside), FrameInfo.velocity(FrameInfo.inside), centerPoints); % interpolate position to time bins
    speed = speed(includeBins);

    modulationSign = false(height(sortedData),1);
    amplitude = NaN(height(sortedData),1);
    amplitudeCI = cell(height(sortedData),1);
    centerPosition = NaN(height(sortedData),1);
    centerPositionCI = cell(height(sortedData),1);
    width = NaN(height(sortedData),1);
    widthCI = cell(height(sortedData),1);
    speedCoef = NaN(height(sortedData),1);
    speedCoefCI = cell(height(sortedData),1);
    baseline = NaN(height(sortedData),1);
    baselineCI = cell(height(sortedData),1);

    for unit = 1:height(sortedData)
        spikeTimes = sortedData{unit,2}; % In sec
        spikeTimes_shuffled = NaN(numel(sortedData{unit,2}),100);
        rng("default")
        for shuff = 1:100
            spikeTimes_shuffled(:,shuff) = spikeTimes+rand*totalDuration;
        end
        spikeTimes_shuffled(spikeTimes_shuffled>totalDuration) = spikeTimes_shuffled(spikeTimes_shuffled>totalDuration)-totalDuration;

        % Observed firing rate of the unit
        firing_rate = histcounts(spikeTimes, edges) / bin_size; % in Hz
        firing_rate = firing_rate(includeBins);

        % Initial guesses for parameters [a, mu, sigma, b, c]
        initial_params = [max(firing_rate), mean(position,'omitmissing'),...
            std(position,'omitmissing'), 0, mean(firing_rate,'omitmissing')];

        warning('off','all')
        % Perform non-linear regression
        inputVar = [position', speed']; % nlinfit only takes one independent variable as input
        [est_params, resids, J, covb, mse] = nlinfit(inputVar, firing_rate', model_fun, initial_params);

        % Position Tuning: If the Gaussian component (a, mu, and sigma) is significant
        % (i.e., 0 outside of 95%CI), this suggests spatial tuning.
        % If b (speed coefficient) is near zero or insignificant (i.e., 0 within 95%CI),
        % it suggests that speed has little effect on firing rate, implying that
        % the response is location-specific.

        % Compute confidence intervals for estimated parameters
        ci = nlparci(est_params, resids, 'jacobian', J);
        warning('on','all')

        % Add results to table
        amplitude(unit) = est_params(1);
        amplitudeCI{unit} = [ci(1,1), ci(1,2)];
        centerPosition(unit) = est_params(2);
        centerPositionCI{unit} = [ci(2,1), ci(2,2)];
        width(unit) = est_params(3);
        widthCI{unit} = [ci(3,1), ci(3,2)];
        speedCoef(unit) = est_params(4);
        speedCoefCI{unit} = [ci(4,1), ci(4,2)];
        baseline(unit) = est_params(5);
        baselineCI{unit} = [ci(5,1), ci(5,2)];

        % If the CI of the amplitude [ci(1,:)] is significant, plot results
        % Only significantly space modulated, if speed [ci(4,:)] has no significant effect
        if prod([ci(1,1), ci(1,2)])>0 && prod([ci(4,1), ci(4,2)])<0
            modulationSign(unit) = true;
        end
    end

    unitTuning{ses} = cell2table([sortedData(:,1), sortedData(:,4), num2cell(modulationSign), ...
        num2cell(amplitude), amplitudeCI, num2cell(centerPosition), centerPositionCI, ...
        num2cell(width), widthCI, num2cell(speedCoef), speedCoefCI, ...
        num2cell(baseline), baselineCI],...
        "VariableNames",{'unitID','area','modulationSign','amplitude','amplitudeCI',...
        'centerPosition','centerPositionCI','width','widthCI','speedCoef','speedCoefCI',...
        'baseline','baselineCI'});

    % Progress bar (without parallel processing)
    if ses==numel(fileSelection)
        fprintf('100%% of sessions analyzed.\n')
    elseif ses/numel(fileSelection)>=0.05*count
        fprintf('%i%% of sessions analyzed.\n',5*count)
        count = count+1;
    end
end

unitTuning_concat = vertcat(unitTuning{:});

clear fig
fig(1) = figure('Name','SpaceTuned_MeanStdGraph');
ax1 = axes(fig(1));
xticks(ax1,(1:numel(area_names)))
xticklabels(ax1,area_names)
xlim(ax1, [0.5 numel(area_names)+0.5])
ylabel(ax1,'Proportion')
title(ax1,'Proportion of spatially tuned units')

% Save one mean value per area per individual
signUnits_rel_anim = NaN(numel(indiAnimals),numel(area_names));
for ar = 1:numel(area_names)
    areaIdx = contains(unitTuning_concat.area,area_names{ar});

    
    % Plot modulated units as mean with std of each session
    for anim = 1:numel(indiAnimals)
        animalIdx = ismember(animalNum,indiAnimals(anim));
        signUnits_rel = NaN(sum(animalIdx),1);
        count = 1;
        for ses = find(animalIdx)'
            totalUnits_ses = sum(contains(unitTuning{ses}.area,area_names{ar}));
            signUnits_ses = contains(unitTuning{ses}.area,area_names{ar}) & unitTuning{ses}.modulationSign;
            signUnits_rel(count) = sum(signUnits_ses)/totalUnits_ses;
            count = count + 1;
        end
        signUnits_rel_anim(anim,ar) = mean(signUnits_rel,'omitmissing');
    end

    hold(ax1,'on')
    plot(ax1,ar * ones(1,height(signUnits_rel_anim)), signUnits_rel_anim(:,ar), 'o', ...
        'MarkerEdgeColor', [0.5 0.5 0.5], 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 4);
    errorbar(ax1, ar, mean(signUnits_rel_anim(:,ar),'omitmissing'), std(signUnits_rel_anim(:,ar),'omitmissing'),...
        'o','LineWidth',3,'CapSize',10,'MarkerSize',10,'Color',area_colors{ar},'MarkerFaceColor',area_colors{ar});
    hold(ax1,'off')

end

%% Whisking vs. quiescence

% Framerate in Hz
video_fr = 240;
% Define moving window size 
windSize = 0.1; % Size in sec
framesIdx = round(video_fr*windSize/2)-1;
% Define window for spike exclusion after touch event
spikeExclusion = 0.05; % in sec

% Tuning table per session with n x 5 dimensions, n being the number of
% units, and the columns being: unitID, area, frWhisking, frQuiescence, p_value
unitTuning = cell(1,numel(fileSelection));

unitTuningAnalyzed = {};
fileSelectionAnalyzed = {};

count = 1; % For progress bar
clear analysisFlag
for ses = 1:numel(fileSelection) % Use parfor for parallel computing
    if ismember(fileSelection{ses}, fileSelectionAnalyzed) && ~exist('analysisFlag','var')
        answer = questdlg('The whisking-quiescence firing rates for these sessions have already been analyzed. Analyze again?',...
            'Analysis repetition','Yes (for all sessions)','No (for all sessions)','No (for all sessions)');
        if isequal(answer,'No (for all sessions)')
            analysisFlag = 0;
            unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
            continue
        else
            analysisFlag = 1;
        end
    elseif ismember(fileSelection{ses}, fileSelectionAnalyzed) && exist('analysisFlag','var') && ~analysisFlag
        unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
        continue
    end
    % Load spike times of that session
    dataInfo = dir(fullfile(fileSelection{ses},'*all_channels.mat'));
    loadData = load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs');
    sortedData = loadData.sortedData;
    sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);
    clInfo = getClusterInfo(fullfile(fileSelection{ses},'cluster_info.tsv'));

    str_idx = regexp(fileSelection{ses},'#\d*','end');
    animalPath = fileSelection{ses}(1:str_idx);

    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')
    include = ismember(cell2mat(sortedData(:,3)), [1,2]) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for i = 1:size(sortedData,1)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{i,1})));
        switch depth
            case 1
                sortedData{i,4} = 'BC';
            case 1400
                sortedData{i,4} = 'POm';
            case 1700
                sortedData{i,4} = 'VPM';
            case 2400
                sortedData{i,4} = 'ZIv';
        end
    end
    
    WaveformInfo = dir(fullfile(dataInfo(1).folder, '*waveforms_all.mat'));
    try load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')
    catch
        fprintf('Couldn''t find waveforms_all.mat file for loading the clWaveforms variable.')
    end

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(clWaveforms),1);
        for ii = 1:height(sortedData)
            unitOrder(ii) = find(ismember(clWaveforms(:,1),sortedData{ii,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the sortedData.')
    end

    loadData = load(fullfile(fileparts(fileparts(fileSelection{ses})),'videos\HispeedTrials.mat'),'HispeedTrials');
    HispeedTrials = loadData.HispeedTrials;

    rhdFile = dir(fullfile(fileparts(fileSelection{ses}),'*.rhd'));
    [sampleNum,sampleRate] = Intan_sampleNum(fullfile(rhdFile(1).folder,rhdFile(1).name));
    totalDuration = sampleNum/sampleRate; % In sec

    frWhisking = nan(height(sortedData),1);
    frQuiescence = nan(height(sortedData),1);
    timeWhisking = nan(height(sortedData),1);
    timeQuiescence = nan(height(sortedData),1);
    p_value = nan(height(sortedData),1);
    % Calculate tuning index of each unit
    for unit = 1:height(sortedData)
        spikeTimesCategory = [];
        spikeTimesCategoryShuff = cell(1,100);
        logicalCategory = logical([]);
        logicalCategoryShuff = cell(1,100);

        % Each millisecond with one value to track the total time with a moving window
        totalTimeWhisking = false(1, round(totalDuration*1000));
        totalTimeQuiescence = false(1, round(totalDuration*1000));

        spikeTimes = sortedData{unit,2}; % In sec
        spikeTimes_shuffled = NaN(numel(sortedData{unit,2}),100);
        rng("default")
        for shuff = 1:100
            spikeTimes_shuffled(:,shuff) = spikeTimes+rand*totalDuration;
        end
        spikeTimes_shuffled(spikeTimes_shuffled>totalDuration) = spikeTimes_shuffled(spikeTimes_shuffled>totalDuration)-totalDuration;

        totalHighspeedTime = nan(1, height(HispeedTrials));
        for sec = 1:height(HispeedTrials)
            totalHighspeedTime(sec) = HispeedTrials.Timestamps{sec}(end)-HispeedTrials.Timestamps{sec}(1);
            % Subtract from 180 deg to invert it (protraction = bigger angle)
            whiskerAngles = 180 - mean(HispeedTrials.WhiskerAngle{sec},2,'omitnan');
            touchLogical = ismember(HispeedTrials.Timestamps{sec},HispeedTrials.ContactLeft{sec}) | ismember(HispeedTrials.Timestamps{sec},HispeedTrials.ContactRight{sec});
            for frame = 1:numel(HispeedTrials.Timestamps{sec})

                % Check time points including windSize (e.g., 100 ms) after and classify it.
                ts = HispeedTrials.Timestamps{sec}(max([1, frame+1-framesIdx]):min([numel(whiskerAngles), frame+framesIdx])); % Timestamps in msec (!) for total behavior times
                angleWind = whiskerAngles(max([1, frame+1-framesIdx]):min([numel(whiskerAngles), frame+framesIdx])); % Angle in deg
                touchWind = touchLogical(max([1, frame-round(video_fr*spikeExclusion)]):frame); % Window after touch event

                % Periods of whisking amplitude > 5° and no-touch lasting more than 200 ms were defined as "free whisking"
                % and periods with amplitude < 3° and no-touch as "quiescence".
                if range(angleWind) > 5 && ~any(touchWind) && ...
                        max(diff(angleWind)) < 30 && mean(angleWind,'omitmissing') > 40
                    % Count spikes in time frame
                    spikesInWind = spikeTimes(spikeTimes>ts(1)/1000 & spikeTimes<=ts(end)/1000);
                    [spikeTimesCategory,~,newVals] = union(spikeTimesCategory, spikesInWind);
                    logicalCategory = [logicalCategory; true(numel(newVals),1)]; %#ok<AGROW>
                    totalTimeWhisking(ts(1):ts(end)) = true; % In msec
                    for shuff = 1:100
                        spikesInWind = spikeTimes_shuffled(spikeTimes_shuffled(:,shuff)>ts(1)/1000 &...
                            spikeTimes_shuffled(:,shuff)<=ts(end)/1000,shuff);
                        [spikeTimesCategoryShuff{shuff},~,newVals] = union(spikeTimesCategoryShuff{shuff}, spikesInWind);
                        logicalCategoryShuff{shuff} = [logicalCategoryShuff{shuff}; true(numel(newVals),1)];
                    end
                elseif range(angleWind) < 2 && ~any(touchWind) && ...
                        max(diff(angleWind)) < 30 && mean(angleWind,'omitmissing') > 40
                    spikesInWind = spikeTimes(spikeTimes>ts(1)/1000 & spikeTimes<=ts(end)/1000);
                    [spikeTimesCategory,~,newVals] = union(spikeTimesCategory, spikesInWind);
                    logicalCategory = [logicalCategory; false(numel(newVals),1)]; %#ok<AGROW>
                    totalTimeQuiescence(ts(1):ts(end)) = true; % In msec
                    for shuff = 1:100
                        spikesInWind = spikeTimes_shuffled(spikeTimes_shuffled(:,shuff)>ts(1)/1000 &...
                            spikeTimes_shuffled(:,shuff)<=ts(end)/1000,shuff);
                        [spikeTimesCategoryShuff{shuff},~,newVals] = union(spikeTimesCategoryShuff{shuff}, spikesInWind);
                        logicalCategoryShuff{shuff} = [logicalCategoryShuff{shuff}; false(numel(newVals),1)];
                    end
                end
            end
        end

        % Calculate overall firing rate
        % Add-one smoothing (also called Laplace smoothing) for better stability, when time windows are small
        timeWhisking = sum(totalTimeWhisking)/1000; % In sec
        timeQuiescence = sum(totalTimeQuiescence)/1000; % In sec
        totalHighspeedTime = sum(totalHighspeedTime)/1000; % In sec;
        frWhisking(unit) = (sum(logicalCategory)+1)/(timeWhisking+1);
        frWhiskingShuff = cellfun(@(x) (sum(x)+1)/(timeWhisking+1), logicalCategoryShuff);

        frQuiescence(unit) = (sum(~logicalCategory)+1)/(timeQuiescence+1);
        frQuiescenceShuff = cellfun(@(x) (sum(~x)+1)/(timeQuiescence+1), logicalCategoryShuff);

        observed_diff = frWhisking(unit) - frQuiescence(unit);
        observed_diffShuff = frWhiskingShuff - frQuiescenceShuff;

        if ~isnan(observed_diff)
            p_value(unit) = sum(abs(observed_diffShuff) > abs(observed_diff))/numel(observed_diffShuff);
        else
            p_value(unit) = NaN;
        end

    end
    unitTuning{ses} = cell2table([sortedData(:,1), sortedData(:,4), num2cell(frWhisking), ...
        num2cell(frQuiescence), num2cell(p_value)],...
        "VariableNames",{'unitID','area','frWhisking','frQuiescence','p_value'});

    % Progress bar (without parallel processing)
    if ses==numel(fileSelection)
        fprintf('100%% of sessions analyzed.\n')
    elseif ses/numel(fileSelection)>=0.05*count
        fprintf('%i%% of sessions analyzed.\n',5*count)
        count = count+1;
    end
end

unitTuning_concat = vertcat(unitTuning{:});

for ar = 1:numel(area_names)
    areaIdx = contains(unitTuning_concat.area,area_names{ar});

    % Calculate the mean firing rate for each condition
    meanQuiescence = mean(unitTuning_concat.frQuiescence(unitTuning_concat.p_value<=0.05 & areaIdx),'omitnan');
    meanWhisking = mean(unitTuning_concat.frWhisking(unitTuning_concat.p_value<=0.05 & areaIdx),'omitnan');

    % Plot individual value pairs (thin gray lines)
    fig = figure('Name',sprintf('FR_Comparison_%s',area_names{ar}));
    hold on
    plot([1, 2], [unitTuning_concat.frQuiescence(unitTuning_concat.p_value>0.05 & areaIdx),...
        unitTuning_concat.frWhisking(unitTuning_concat.p_value>0.05 & areaIdx)],...
        '.','Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    plot([1, 2], [unitTuning_concat.frQuiescence(unitTuning_concat.p_value<=0.05 & areaIdx),...
        unitTuning_concat.frWhisking(unitTuning_concat.p_value<=0.05 & areaIdx)],...
        '.','Color', area_colors{ar}, 'LineWidth', 0.5);

    % Plot mean firing rates as thicker line
    plot([1, 2], [meanQuiescence, meanWhisking], 'Color', area_colors{ar}, 'LineWidth', 2);

    set(gca, 'XTick', [1, 2], 'XTickLabel', {'Quiescence', 'Whisking'})
    ylabel('Firing rate (Hz)')
    title('Comparison of behavioral states')
    xlim([0.8 2.7])

    axes('Position',[.75 .75 .1 .1]), box off
    piePlot = pie([sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence > 0), ...
        sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence < 0), ...
        sum(areaIdx & unitTuning_concat.p_value>0.05), ...
        sum(areaIdx & isnan(unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence))], {'Increased','Decreased','n.s.','NaN'});
    patchHand = findobj(piePlot, 'Type', 'Patch');
    arrayfun(@(x) set(patchHand(x), 'FaceColor', area_colors{ar}),(1:4));
    patchHand(1).FaceAlpha = 1.0;
    patchHand(2).FaceAlpha = 0.8;
    patchHand(3).FaceAlpha = 0.6;
    patchHand(4).FaceAlpha = 0.4;

    axes('Position',[.75 .55 .1 .1]), box off
    piePlot = pie([sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence > 0), ...
        sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence < 0), ...
        sum(areaIdx & unitTuning_concat.p_value>0.05)], {'Increased','Decreased','n.s.'});
    patchHand = findobj(piePlot, 'Type', 'Patch');
    arrayfun(@(x) set(patchHand(x), 'FaceColor', area_colors{ar}),(1:3));
    patchHand(1).FaceAlpha = 1.0;
    patchHand(2).FaceAlpha = 0.8;
    patchHand(3).FaceAlpha = 0.6;

    hold off

    [h,p,ci] = ttest(unitTuning_concat.frQuiescence(areaIdx), unitTuning_concat.frWhisking(areaIdx));

    Info = struct('cellNum_all', {sum(areaIdx)},...
        'cellNum_sign', {sum(unitTuning_concat.p_value<=0.05 & areaIdx)},...
        'Incr_Decr_NonSig_NaN', {[sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence > 0), ...
        sum(areaIdx & unitTuning_concat.p_value<=0.05 & unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence < 0), ...
        sum(areaIdx & unitTuning_concat.p_value>0.05), ...
        sum(areaIdx & isnan(unitTuning_concat.frWhisking-unitTuning_concat.frQuiescence))]}, ...
        'meanQuiescence', {meanQuiescence},...
        'meanWhisking',{meanWhisking},...
        'ttest_p', {p},...
        'ttest_ci', {ci});
    fig.UserData = Info;

end

%% Head-angle (overview camera)

% Framerate in Hz
video_fr = 60;
% Define bin size and edges
binSize = 5; % Size in deg
bin_edges = -90:binSize:90;

% Tuning arrays per session with n x 5 dimensions, n being the number of
% units, and the columns being unitID, area, modulationIndex, modulationMax, modulationSign
unitTuning = cell(1,numel(fileSelection));
unitTuningAnalyzed = {};
fileSelectionAnalyzed = {};

count = 1; % For progress bar (without parallel processing)
plotUnits_ego = ones(2,numel(area_names)); % For plotting three sign (first row) and three insign (second row) units
plotUnits_allo = ones(2,numel(area_names)); % For plotting three sign (first row) and three insign (second row) units
clear analysisFlag
for ses = 1:numel(fileSelection) % Use parfor for parallel computing
    if ismember(fileSelection{ses}, fileSelectionAnalyzed) && ~exist('analysisFlag','var')
        answer = questdlg('The head-angles for this session and potentially others have already been analyzed. Analyze again?',...
            'Analysis repetition','Yes (for all sessions)','No (for all sessions)','No (for all sessions)');
        if isequal(answer,'No (for all sessions)')
            analysisFlag = 0;
            unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
            continue
        else
            analysisFlag = 1;
        end
    elseif ismember(fileSelection{ses}, fileSelectionAnalyzed) && exist('analysisFlag','var') && ~analysisFlag
        unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
        continue
    end
    % Load spike times of that session
    dataInfo = dir(fullfile(fileSelection{ses},'*all_channels.mat'));
    loadData = load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs');
    sortedData = loadData.sortedData;
    sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);
    clInfo = getClusterInfo(fullfile(fileSelection{ses},'cluster_info.tsv'));

    str_idx = regexp(fileSelection{ses},'#\d*','end');
    animalPath = fileSelection{ses}(1:str_idx);

    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')
    include = ismember(cell2mat(sortedData(:,3)), [1,2]) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for i = 1:size(sortedData,1)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{i,1})));
        switch depth
            case 1
                sortedData{i,4} = 'BC';
            case 1400
                sortedData{i,4} = 'POm';
            case 1700
                sortedData{i,4} = 'VPM';
            case 2400
                sortedData{i,4} = 'ZIv';
        end
    end

    WaveformInfo = dir(fullfile(dataInfo(1).folder, '*waveforms_all.mat'));
    try load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')
    catch
        fprintf('Couldn''t find waveforms_all.mat file for loading the clWaveforms variable.')
    end

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(clWaveforms),1);
        for ii = 1:height(sortedData)
            unitOrder(ii) = find(ismember(clWaveforms(:,1),sortedData{ii,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the sortedData.')
    end    

    load(fullfile(fileSelection{ses},'FrameInfo.mat'),'HeadAngle')

    rhdFile = dir(fullfile(fileparts(fileSelection{ses}),'*.rhd'));
    [sampleNum,sampleRate] = Intan_sampleNum(fullfile(rhdFile(1).folder,rhdFile(1).name));
    totalDuration = sampleNum/sampleRate; % In sec

    modulationIndex_ego = NaN(height(sortedData),1);
    modulationMax_ego = NaN(height(sortedData),1);
    modulationSign_ego = false(height(sortedData),1);
    modulationIndex_allo = NaN(height(sortedData),1);
    modulationMax_allo = NaN(height(sortedData),1);
    modulationSign_allo = false(height(sortedData),1);
    % Calculate tuning index of each unit
    for unit = 1:height(sortedData)
        binCounts_ego = zeros(1,numel(bin_edges)-1);
        binCounts_allo = zeros(1,numel(bin_edges)-1);
        durPerBin_ego = zeros(1,numel(bin_edges)-1);
        durPerBin_allo = zeros(1,numel(bin_edges)-1);
        spikesPerBin_ego = zeros(1,numel(bin_edges)-1);
        spikesPerBin_allo = zeros(1,numel(bin_edges)-1);

        % For statistical testing
        spikesPerBin_shuffled_ego = zeros(100,numel(bin_edges)-1);
        spikesPerBin_shuffled_allo = zeros(100,numel(bin_edges)-1);
        rng("default")

        spikeTimes = sortedData{unit,2}; % In sec
        spikeTimes_shuffled = NaN(numel(sortedData{unit,2}),100);
        for shuff = 1:100
            spikeTimes_shuffled(:,shuff) = spikeTimes+rand*totalDuration;
        end
        spikeTimes_shuffled(spikeTimes_shuffled>totalDuration) = spikeTimes_shuffled(spikeTimes_shuffled>totalDuration)-totalDuration;

        % Get head angles from only within a defined window of the linear track (HeadAngle.inside), in order
        % to rule out unspecific effects of whisker interactions close to the reward sites.
        egocentric = HeadAngle.egocentric(HeadAngle.inside); % Egocentric angles on linear track
        allocentric = HeadAngle.allocentric(HeadAngle.inside); % Allocentric angles on linear track
        frameNum = HeadAngle.frameNum(HeadAngle.inside); % Respective frame numbers
        frameTs = HeadAngle.time(HeadAngle.inside); % Respective frame time stamps [msec] for total behavior times

        for frame = 1:numel(frameNum)
            % Assign degree value to the appropriate bin
            binCounts_ego = binCounts_ego+histcounts(egocentric(frame), bin_edges);
            binCounts_allo = binCounts_allo+histcounts(allocentric(frame), bin_edges);
            timeWind = [frameTs(frame)-0.5/video_fr frameTs(frame)+0.5/video_fr];

            % Add time window to the respective bin (in sec)
            durPerBin_ego = durPerBin_ego+histcounts(egocentric(frame), bin_edges).*diff(timeWind);
            durPerBin_allo = durPerBin_allo+histcounts(allocentric(frame), bin_edges).*diff(timeWind);

            % Add spike counts
            spikesPerBin_ego = spikesPerBin_ego+histcounts(egocentric(frame), bin_edges).*sum(spikeTimes>=timeWind(1) & spikeTimes<timeWind(2));
            spikesPerBin_allo = spikesPerBin_allo+histcounts(allocentric(frame), bin_edges).*sum(spikeTimes>=timeWind(1) & spikeTimes<timeWind(2));

            spikesPerBin_shuffled_ego = spikesPerBin_shuffled_ego+histcounts(egocentric(frame), bin_edges).*...
                sum(spikeTimes_shuffled>=timeWind(1) & spikeTimes_shuffled<timeWind(2))';
            spikesPerBin_shuffled_allo = spikesPerBin_shuffled_allo+histcounts(allocentric(frame), bin_edges).*...
                sum(spikeTimes_shuffled>=timeWind(1) & spikeTimes_shuffled<timeWind(2))';
        end
        % For stability, remove bin counts lower than 5
        includeBins = binCounts_ego>=5;
        if any(includeBins)
            % Modulation index defined as: (Rmax - Rmin)/Rmean,
            % where Rmax, Rmin, and Rmean are the maximal, minimal and mean firing rate of the tuning curve, respectively.
            [modulationIndex_ego, modulationMax_ego, modulationSign_ego, plotUnits_ego] = getModulationIndex...
                (modulationIndex_ego,modulationMax_ego,modulationSign_ego,unit,spikesPerBin_ego,...
                durPerBin_ego,spikesPerBin_shuffled_ego,plotUnits_ego,includeBins,bin_edges,binSize,sortedData,destinationDir,'ego');
        end

        includeBins = binCounts_allo>=5;
        if any(includeBins)
            % Modulation index defined as: (Rmax - Rmin)/Rmean,
            % where Rmax, Rmin, and Rmean are the maximal, minimal and mean firing rate of the tuning curve, respectively.
            [modulationIndex_allo, modulationMax_allo, modulationSign_allo, plotUnits_allo] = getModulationIndex...
                (modulationIndex_allo,modulationMax_allo,modulationSign_allo,unit,spikesPerBin_allo,...
                durPerBin_allo,spikesPerBin_shuffled_allo,plotUnits_allo,includeBins,bin_edges,binSize,sortedData,destinationDir,'allo');
        end

    end
    unitTuning{ses} = cell2table([sortedData(:,1), sortedData(:,4), num2cell(modulationIndex_ego), ...
        num2cell(modulationMax_ego), num2cell(modulationSign_ego), num2cell(modulationIndex_allo), ...
        num2cell(modulationMax_allo), num2cell(modulationSign_allo)],...
        "VariableNames",{'unitID','area','modulationIndex_ego','modulationMax_ego','modulationSign_ego',...
        'modulationIndex_allo','modulationMax_allo','modulationSign_allo'});

    % Progress bar (without parallel processing)
    if ses==numel(fileSelection)
        fprintf('100%% of sessions analyzed.\n')
    elseif ses/numel(fileSelection)>=0.05*count
        fprintf('%i%% of sessions analyzed.\n',5*count)
        count = count+1;
    end
end

unitTuning_concat = vertcat(unitTuning{:});

clear fig
fig(1) = figure('Name','HeadAngleEgo_BarGraphs');
ax(1) = axes(fig(1));
xticks(ax(1),(1:numel(area_names)))
xticklabels(ax(1),area_names)
ylabel(ax(1),'Proportion')
title(ax(1),'Proportion of head angle (egocentric) tuned units')

fig(2) = figure('Name','HeadAngleAllo_BarGraphs');
ax(2) = axes(fig(2));
xticks(ax(2),(1:numel(area_names)))
xticklabels(ax(2),area_names)
ylabel(ax(2),'Proportion')
title(ax(2),'Proportion of head angle (allocentric) tuned units')

fig(5) = figure('Name','HeadAngleEgo_MeanStdGraph');
ax(5) = axes(fig(5));
xticks(ax(5),(1:numel(area_names)))
xticklabels(ax(5),area_names)
xlim(ax(5), [0.5 numel(area_names)+0.5])
ylabel(ax(5),'Proportion')
title(ax(5),'Proportion of head angle (egocentric) tuned units')

fig(6) = figure('Name','HeadAngleAllo_MeanStdGraph');
ax(6) = axes(fig(6));
xticks(ax(6),(1:numel(area_names)))
xticklabels(ax(6),area_names)
xlim(ax(6), [0.5 numel(area_names)+0.5])
ylabel(ax(6),'Proportion')
title(ax(6),'Proportion of head angle (allocentric) tuned units')

totalUnits = NaN(1,numel(area_names));
signUnits_abs_ego = NaN(1,numel(area_names));
signUnits_abs_allo = NaN(1,numel(area_names));

% Save one mean value per area per individual
signUnits_rel_anim_ego = NaN(numel(indiAnimals),numel(area_names));
signUnits_rel_anim_allo = NaN(numel(indiAnimals),numel(area_names));
for ar = 1:numel(area_names)
    % Plot the amount of tuned units per area
    totalUnits(ar) = sum(contains(unitTuning_concat.area,area_names{ar}));

    % EGOCENTRIC
    signUnits = contains(unitTuning_concat.area,area_names{ar}) & unitTuning_concat.modulationSign_ego;
    signUnits_abs_ego(ar) = sum(signUnits);
    signUnits_rel = sum(signUnits)/totalUnits(ar);

    hold(ax(1),'on')
    % Plot significant proportion
    bar(ax(1),ar, signUnits_rel, 'FaceColor', area_colors{ar}, 'EdgeColor', 'none');
    hold(ax(1),'off')

    % ALLOCENTRIC
    signUnits = contains(unitTuning_concat.area,area_names{ar}) & unitTuning_concat.modulationSign_allo;
    signUnits_abs_allo(ar) = sum(signUnits);
    signUnits_rel = sum(signUnits)/totalUnits(ar);

    hold(ax(2),'on')
    % Plot significant proportion
    bar(ax(2),ar, signUnits_rel, 'FaceColor', area_colors{ar}, 'EdgeColor', 'none');
    hold(ax(2),'off')


    % Plot modulated units as mean with std of each session
    for anim = 1:numel(indiAnimals)
        animalIdx = ismember(animalNum,indiAnimals(anim));
        signUnits_rel_ego = NaN(sum(animalIdx),1);
        signUnits_rel_allo = NaN(sum(animalIdx),1);
        count = 1;
        for ses = find(animalIdx)'
            totalUnits_ses = sum(contains(unitTuning{ses}.area,area_names{ar}));
            
            % EGOCENTRIC
            signUnits_ses = contains(unitTuning{ses}.area,area_names{ar}) & unitTuning{ses}.modulationSign_ego;
            signUnits_rel_ego(count) = sum(signUnits_ses)/totalUnits_ses;
            
            % ALLOCENTRIC
            signUnits_ses = contains(unitTuning{ses}.area,area_names{ar}) & unitTuning{ses}.modulationSign_allo;
            signUnits_rel_allo(count) = sum(signUnits_ses)/totalUnits_ses;
            count = count + 1;
        end
        signUnits_rel_anim_ego(anim,ar) = mean(signUnits_rel_ego,'omitmissing');
        signUnits_rel_anim_allo(anim,ar) = mean(signUnits_rel_allo,'omitmissing');
    end

    hold(ax(5),'on')
    plot(ax(5),ar * ones(1,height(signUnits_rel_anim_ego)), signUnits_rel_anim_ego(:,ar), 'o', ...
        'MarkerEdgeColor', [0.5 0.5 0.5], 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 4);
    errorbar(ax(5), ar, mean(signUnits_rel_anim_ego(:,ar),'omitmissing'), std(signUnits_rel_anim_ego(:,ar),'omitmissing'),...
        'o','LineWidth',3,'CapSize',10,'MarkerSize',10,'Color',area_colors{ar},'MarkerFaceColor',area_colors{ar});
    hold(ax(5),'off')

    hold(ax(6),'on')
    plot(ax(6),ar * ones(1,height(signUnits_rel_anim_allo)), signUnits_rel_anim_allo(:,ar), 'o', ...
        'MarkerEdgeColor', [0.5 0.5 0.5], 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 4);
    errorbar(ax(6), ar, mean(signUnits_rel_anim_allo(:,ar),'omitmissing'), std(signUnits_rel_anim_allo(:,ar),'omitmissing'),...
        'o','LineWidth',3,'CapSize',10,'MarkerSize',10,'Color',area_colors{ar},'MarkerFaceColor',area_colors{ar});
    hold(ax(6),'off')
end

fig(1).UserData = struct('totalUnits', {totalUnits}, ...
    'signUnits', {signUnits_abs_ego}, ...
    'statTest', 'Bootstrap 100 shuffles');

fig(2).UserData = struct('totalUnits', {totalUnits}, ...
    'signUnits', {signUnits_abs_allo}, ...
    'statTest', 'Bootstrap 100 shuffles');

%% Whisking-angle

% Framerate in Hz
video_fr = 240;
% Define bin size and edges
binSize = 5; % Size in deg
bin_edges = 0:binSize:180;
refVals = bin_edges(1:end-1)+binSize/2;

% Define window size for touch tracking
windSize = 0.2; % Size in sec
framesIdx = round(video_fr*windSize/2)-1;
% Define window for spike exclusion after touch event
spikeExclusion = 0.1; % in sec

% Tuning arrays per session with n x 5 dimensions, n being the number of
% units, and the columns being unitID, area, modulationIndex, modulationMax, modulationSign
unitTuning = cell(1,numel(fileSelection));
unitTuningAnalyzed = {};
fileSelectionAnalyzed = {};

count = 1; % For progress bar (without parallel processing)
plotUnits = ones(2,numel(area_names)); % For plotting three sign (first row) and three insign (second row) units
clear analysisFlag
for ses = 1:numel(fileSelection)
    if ismember(fileSelection{ses}, fileSelectionAnalyzed) && ~exist('analysisFlag','var')
        answer = questdlg('The whisking-angles for this session and potentially others have already been analyzed. Analyze again?',...
            'Analysis repetition','Yes (for all sessions)','No (for all sessions)','No (for all sessions)');
        if isequal(answer,'No (for all sessions)')
            analysisFlag = 0;
            unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
            continue
        else
            analysisFlag = 1;
        end
    elseif ismember(fileSelection{ses}, fileSelectionAnalyzed) && exist('analysisFlag','var') && ~analysisFlag
        unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
        continue
    end
    % Load spike times of that session
    dataInfo = dir(fullfile(fileSelection{ses},'*all_channels.mat'));
    loadData = load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs');
    sortedData = loadData.sortedData;
    sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);
    clInfo = getClusterInfo(fullfile(fileSelection{ses},'cluster_info.tsv'));

    str_idx = regexp(fileSelection{ses},'#\d*','end');
    animalPath = fileSelection{ses}(1:str_idx);

    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')
    include = ismember(cell2mat(sortedData(:,3)), [1,2]) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for i = 1:size(sortedData,1)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{i,1})));
        switch depth
            case 1
                sortedData{i,4} = 'BC';
            case 1400
                sortedData{i,4} = 'POm';
            case 1700
                sortedData{i,4} = 'VPM';
            case 2400
                sortedData{i,4} = 'ZIv';
        end
    end

    WaveformInfo = dir(fullfile(dataInfo(1).folder, '*waveforms_all.mat'));
    try load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')
    catch
        fprintf('Couldn''t find waveforms_all.mat file for loading the clWaveforms variable.')
    end

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(clWaveforms),1);
        for ii = 1:height(sortedData)
            unitOrder(ii) = find(ismember(clWaveforms(:,1),sortedData{ii,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the sortedData.')
    end

    loadData = load(fullfile(fileparts(fileparts(fileSelection{ses})),'videos\HispeedTrials.mat'),'HispeedTrials');
    HispeedTrials = loadData.HispeedTrials;

    rhdFile = dir(fullfile(fileparts(fileSelection{ses}),'*.rhd'));
    [sampleNum,sampleRate] = Intan_sampleNum(fullfile(rhdFile(1).folder,rhdFile(1).name));
    totalDuration = sampleNum/sampleRate; % In sec

    modulationIndex = NaN(height(sortedData),1);
    modulationMax = NaN(height(sortedData),1);
    modulationSign = false(height(sortedData),1);
    % Calculate tuning index of each unit
    for unit = 1:height(sortedData)
        binCounts = zeros(1,numel(bin_edges)-1);
        durPerBin = zeros(1,numel(bin_edges)-1);
        spikesPerBin = zeros(1,numel(bin_edges)-1);

        % For statistical testing
        spikesPerBin_shuffled = zeros(100,numel(bin_edges)-1);
        rng("default")

        spikeTimes = sortedData{unit,2}; % In sec
        spikeTimes_shuffled = NaN(numel(sortedData{unit,2}),100);
        for shuff = 1:100
            spikeTimes_shuffled(:,shuff) = spikeTimes+rand*totalDuration;
        end
        spikeTimes_shuffled(spikeTimes_shuffled>totalDuration) = spikeTimes_shuffled(spikeTimes_shuffled>totalDuration)-totalDuration;

        for sec = 1:height(HispeedTrials)
            % Calculate number of spikes for the respective length of occurrence (in sec to get firing rates in Hz)

            % Subtract from 180 deg to invert it (protraction = bigger angle)
            whiskerAngles = 180 - movmean(mean(HispeedTrials.WhiskerAngle{sec},2,'omitnan'),10);
            touchLogical = ismember(HispeedTrials.Timestamps{sec},HispeedTrials.ContactLeft{sec}) | ismember(HispeedTrials.Timestamps{sec},HispeedTrials.ContactRight{sec});

            for frame = 1:numel(HispeedTrials.Timestamps{sec})
                ts = HispeedTrials.Timestamps{sec}(frame)/1000; % Timestamp in sec
                angle = whiskerAngles(frame); % Angle in deg

                % Only track angles, if there is no touch event within
                % a window of spikeExclusion (e.g., 100 msec) after touch
                touchWind = touchLogical(max([1, frame-round(video_fr*spikeExclusion)]):frame); % Window after touch event
                angleWind = whiskerAngles(max([1, frame+1-framesIdx]):min([numel(whiskerAngles), frame+framesIdx])); % Angle in deg

                if ~any(touchWind) && max(diff(angleWind)) < 30 && mean(angleWind,'omitmissing') > 40
                    % Assign degree value to the appropriate bin
                    binCounts = binCounts+histcounts(angle, bin_edges);

                    % Define time windows accurately to avoid double counts of spikes
                    if frame==1
                        timeWind = [ts-1/video_fr, (ts+HispeedTrials.Timestamps{sec}(frame+1)/1000)/2];
                    elseif frame==numel(HispeedTrials.Timestamps{sec})
                        timeWind = [(ts+HispeedTrials.Timestamps{sec}(frame-1)/1000)/2, ts+1/video_fr];
                    else
                        timeWind = [(ts+HispeedTrials.Timestamps{sec}(frame-1)/1000)/2, ...
                            (ts+HispeedTrials.Timestamps{sec}(frame+1)/1000)/2];
                    end

                    % Add time window to the respective bin (in sec)
                    durPerBin = durPerBin+histcounts(angle, bin_edges).*diff(timeWind);

                    % Add spike counts
                    spikesPerBin = spikesPerBin+histcounts(angle, bin_edges).*sum(spikeTimes>=timeWind(1) & spikeTimes<timeWind(2));
                    spikesPerBin_shuffled = spikesPerBin_shuffled+histcounts(angle, bin_edges).*...
                        sum(spikeTimes_shuffled>=timeWind(1) & spikeTimes_shuffled<timeWind(2))';
                end
            end
        end
        % For stability, remove bin counts lower than 10
        includeBins = binCounts>=10;

        if any(includeBins)
            % Modulation index defined as: (Rmax - Rmin)/Rmean,
            % where Rmax, Rmin, and Rmean are the maximal, minimal and mean firing rate of the tuning curve, respectively.
            modulationIndex(unit) = (max(spikesPerBin(includeBins)./durPerBin(includeBins))-min(spikesPerBin(includeBins)./durPerBin(includeBins)))/...
                mean(spikesPerBin(includeBins)./durPerBin(includeBins),'omitmissing');
            [~,binIdx] = max(spikesPerBin(includeBins)./durPerBin(includeBins));
            binIdx = find(includeBins,binIdx);
            modulationMax(unit) = bin_edges(binIdx(end))+binSize/2;

            modulationIndex_shuffled = (max(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins),[],2)-min(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins),[],2))./...
                mean(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins),2,'omitmissing');

            % Statistical testing against shuffled data set (see Oram et al. Ahissar 2024)
            ar = find(contains(area_names,sortedData{unit,4}));
            if modulationIndex(unit) >= prctile(modulationIndex_shuffled,95)
                modulationSign(unit) = true;
                if plotUnits(1,ar)<=3 % Plot 3 sign units per area
                    meanRates = mean(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 1, 'omitmissing');
                    stdRates = std(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 0, 1, 'omitmissing');

                    curve1 = meanRates + stdRates;
                    curve2 = meanRates - stdRates;
                    x = refVals(includeBins);
                    x = x(~isnan(curve1));
                    curve1 = curve1(~isnan(curve1));
                    curve2 = curve2(~isnan(curve2));

                    fig = figure;
                    hold on
                    fill([x fliplr(x)], [curve1 fliplr(curve2)], [0 0 0.85], ...
                        'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
                    plot(x, meanRates, 'Color',[.3 .3 .3], 'LineWidth', 2);
                    plot(x, spikesPerBin(includeBins)./durPerBin(includeBins),'Color',area_colors{ar},'LineWidth',2)
                    hold off
                    ylabel('Firing rate [Hz]')
                    xlabel('Whisker angle [deg]')
                    xlim tight
                    title(sprintf('Tuned unit of %s (#%s)',area_names{ar},sortedData{unit,1}))
                    plotUnits(1,ar) = plotUnits(1,ar)+1;
                    destfile = fullfile(destinationDir,sprintf('ExampleUnit_Tuned_%s#%s.fig',area_names{ar},sortedData{unit,1}));
                    savefig(fig, destfile);
                end
            elseif plotUnits(2,ar)<=3 % Plot 3 insign units per area
                meanRates = mean(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 1, 'omitmissing');
                stdRates = std(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 0, 1, 'omitmissing');

                curve1 = meanRates + stdRates;
                curve2 = meanRates - stdRates;
                x = refVals(includeBins);
                x = x(~isnan(curve1));
                curve1 = curve1(~isnan(curve1));
                curve2 = curve2(~isnan(curve2));

                fig = figure;
                hold on
                fill([x fliplr(x)], [curve1 fliplr(curve2)], [0 0 0.85], ...
                    'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
                plot(x, meanRates, 'Color',[.3 .3 .3], 'LineWidth', 2);
                plot(x, spikesPerBin(includeBins)./durPerBin(includeBins),'Color',area_colors{ar},'LineWidth',2)
                hold off
                ylabel('Firing rate [Hz]')
                xlabel('Whisker angle [deg]')
                xlim tight
                title(sprintf('Not tuned unit of %s (#%s)',area_names{ar},sortedData{unit,1}))
                plotUnits(2,ar) = plotUnits(2,ar)+1;
                destfile = fullfile(destinationDir,sprintf('ExampleUnit_NotTuned_%s#%s.fig',area_names{ar},sortedData{unit,1}));
                savefig(fig, destfile);
            end
        end

    end
    unitTuning{ses} = cell2table([sortedData(:,1), sortedData(:,4), num2cell(modulationIndex), ...
        num2cell(modulationMax), num2cell(modulationSign)],...
        "VariableNames",{'unitID','area','modulationIndex','modulationMax','modulationSign'});

    % Progress bar (without parallel processing)
    if ses==numel(fileSelection)
        fprintf('100%% of sessions analyzed.\n')
    elseif ses/numel(fileSelection)>=0.05*count
        fprintf('%i%% of sessions analyzed.\n',5*count)
        count = count+1;
    end
end

unitTuning_concat = vertcat(unitTuning{:});

clear fig

fig(4) = figure('Name',sprintf('WhiskerAngle_MeanStdGraph_%imsExclusion_perAnimal',round(spikeExclusion*1000)));
ax4 = axes(fig(4));
xticks(ax4,(1:numel(area_names)))
xticklabels(ax4,area_names)
xlim(ax4, [0.5 numel(area_names)+0.5])
ylabel(ax4,'Proportion')
title(ax4,'Proportion of whisker angle tuned units')

totalUnits = NaN(1,numel(area_names));
signUnits_abs = NaN(1,numel(area_names));
signUnits_rel_ses = cell(1,numel(area_names));

% Save one mean value per area per individual
signUnits_rel_anim = NaN(numel(indiAnimals),numel(area_names));
for ar = 1:numel(area_names)
    % Plot the amount of tuned units per area
    totalUnits(ar) = sum(contains(unitTuning_concat.area,area_names{ar}));
    signUnits = contains(unitTuning_concat.area,area_names{ar}) & unitTuning_concat.modulationSign;
    signUnits_abs(ar) = sum(signUnits);
    signUnits_rel = sum(signUnits)/totalUnits(ar);

    % Plot modulated units as mean with std of each session
    signUnits_rel_ses{ar} = NaN(numel(unitTuning),1);
    for ses = 1:numel(unitTuning)
        totalUnits_ses = sum(contains(unitTuning{ses}.area,area_names{ar}));
        signUnits_ses = contains(unitTuning{ses}.area,area_names{ar}) & unitTuning{ses}.modulationSign;
        signUnits_rel_ses{ar}(ses) = sum(signUnits_ses)/totalUnits_ses;        
    end
 
    % Plot modulated units as mean with std of each session
    for anim = 1:numel(indiAnimals)
        animalIdx = ismember(animalNum,indiAnimals(anim));
        signUnits_rel = NaN(sum(animalIdx),1);
        count = 1;
        for ses = find(animalIdx)'
            totalUnits_ses = sum(contains(unitTuning{ses}.area,area_names{ar}));
            signUnits_ses = contains(unitTuning{ses}.area,area_names{ar}) & unitTuning{ses}.modulationSign;
            signUnits_rel(count) = sum(signUnits_ses)/totalUnits_ses;
            count = count + 1;
        end
        signUnits_rel_anim(anim,ar) = mean(signUnits_rel,'omitmissing');
    end

    hold(ax4,'on')
    plot(ax4,ar * ones(1,height(signUnits_rel_anim)), signUnits_rel_anim(:,ar), 'o', ...
        'MarkerEdgeColor', [0.5 0.5 0.5], 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 4);
    errorbar(ax4, ar, mean(signUnits_rel_anim(:,ar),'omitmissing'), std(signUnits_rel_anim(:,ar),'omitmissing'),...
        'o','LineWidth',3,'CapSize',10,'MarkerSize',10,'Color',area_colors{ar},'MarkerFaceColor',area_colors{ar});
    hold(ax4,'off')
end

%% Whisking-phase

% Framerate in Hz
video_fr = 240;
% Band-pass filtering (see Mitchinson et al., 2011: 2 - 30 Hz)
bpFilter = [2 30];

% Define bin size and edges
binSize = pi/16; % Size in rad
bin_edges = 0:binSize:2*pi;
refVals = bin_edges(1:end-1)+binSize/2;

% Tuning arrays per session with n x 5 dimensions, n being the number of
% units, and the columns being unitID, area, modulationIndex, modulationMax, modulationSign
unitTuning = cell(1,numel(fileSelection));

% Define window size for excluding spikes that occur
% within that window after a touch event
spikeExclusion = 0.1; % in sec

unitTuningAnalyzed = {};
fileSelectionAnalyzed = {};

% Fit for characterizing the modulation of each unit (see Moore et al., 2015)
ft = fittype('mean_r + amp*cos(phase-pref_phase)', 'dependent',{'lam'},'independent',{'phase'},'coefficients',{'mean_r','amp','pref_phase'});
fo = fitoptions(ft);

count = 1;
clear analysisFlag
for ses = 1:numel(fileSelection) % Use parfor for parallel computing
    if ismember(fileSelection{ses}, fileSelectionAnalyzed) && ~exist('analysisFlag','var')
        answer = questdlg('The whisking-angles for this session and potentially others have already been analyzed. Analyze again?',...
            'Analysis repetition','Yes (for all sessions)','No (for all sessions)','No (for all sessions)');
        if isequal(answer,'No (for all sessions)')
            analysisFlag = 0;
            unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
            continue
        else
            analysisFlag = 1;
        end
    elseif ismember(fileSelection{ses}, fileSelectionAnalyzed) && exist('analysisFlag','var') && ~analysisFlag
        unitTuning{ses} = unitTuningAnalyzed{ismember(fileSelectionAnalyzed, fileSelection{ses})};
        continue
    end
    % Load spike times of that session
    dataInfo = dir(fullfile(fileSelection{ses},'*all_channels.mat'));
    loadData = load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs');
    sortedData = loadData.sortedData;
    sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);
    clInfo = getClusterInfo(fullfile(fileSelection{ses},'cluster_info.tsv'));

    str_idx = regexp(fileSelection{ses},'#\d*','end');
    animalPath = fileSelection{ses}(1:str_idx);

    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')
    include = ismember(cell2mat(sortedData(:,3)), [1,2]) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for i = 1:size(sortedData,1)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{i,1})));
        switch depth
            case 1
                sortedData{i,4} = 'BC';
            case 1400
                sortedData{i,4} = 'POm';
            case 1700
                sortedData{i,4} = 'VPM';
            case 2400
                sortedData{i,4} = 'ZIv';
        end
    end

    WaveformInfo = dir(fullfile(dataInfo(1).folder, '*waveforms_all.mat'));
    try load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')
    catch
        fprintf('Couldn''t find waveforms_all.mat file for loading the clWaveforms variable.')
    end

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(clWaveforms),1);
        for ii = 1:height(sortedData)
            unitOrder(ii) = find(ismember(clWaveforms(:,1),sortedData{ii,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        sortedData = getWaveformDistribution(clWaveforms,sortedData);
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the sortedData.')
    end

    loadData = load(fullfile(fileparts(fileparts(fileSelection{ses})),'videos\HispeedTrials.mat'),'HispeedTrials');
    HispeedTrials = loadData.HispeedTrials;

    rhdFile = dir(fullfile(fileparts(fileSelection{ses}),'*.rhd'));
    [sampleNum,sampleRate] = Intan_sampleNum(fullfile(rhdFile(1).folder,rhdFile(1).name));
    totalDuration = sampleNum/sampleRate; % In sec

    modulationMax = NaN(height(sortedData),1);
    p_value = NaN(height(sortedData),1);
    modulationSign = zeros(height(sortedData),1);
    preferredPhase = NaN(height(sortedData),1);
    modulationDepth = NaN(height(sortedData),1);
    SNR = NaN(height(sortedData),1);
    % Calculate tuning index of each unit
    for unit = 1:height(sortedData)
        binCounts = zeros(1,numel(bin_edges)-1);
        spikesPerBin = zeros(1,numel(bin_edges)-1);

        spikeTimes = sortedData{unit,2}; % In sec

        for sec = 1:height(HispeedTrials)
            % Calculate number of spikes for the respective length of occurrence (in sec to get firing rates in Hz)

            % Subtract from 180 deg to invert it (protraction = bigger angle)
            whiskerAngles = 180 - movmean(mean(HispeedTrials.WhiskerAngle{sec},2,'omitnan'),10);
            ts = HispeedTrials.Timestamps{sec}/1000; % Timestamp in sec
            [~,uniqueVals,~]=unique(ts);
            ts = ts(uniqueVals); whiskerAngles = whiskerAngles(uniqueVals);
            meanFrameDur = mean(diff(ts));

            % Have to remove missing values, otherwise bandpass filtering doesn't work
            ts = ts(~isnan(whiskerAngles));
            whiskerAngles = whiskerAngles(~isnan(whiskerAngles));
            TT_angles = array2timetable(whiskerAngles,'RowTimes',seconds(ts));

            if ~isempty(TT_angles) && numel(TT_angles.whiskerAngles)>1 % In order to bandpass filter
                % Fill in timestamp gaps (necessary for bandpass filtering)
                TT_angles = retime(TT_angles,'regular','linear','SampleRate',video_fr);
                filteredAngles = bandpass(TT_angles.whiskerAngles,bpFilter,video_fr);
            else
                continue
            end

            % Hilbert transform to get the analytic signal
            analytic_signal = hilbert(filteredAngles);

            % Extract the instantaneous phase
            inst_phase = angle(analytic_signal); % Phase in radians [-pi, pi]

            % Normalize the phase to [0, 2pi]
            normalized_phase = mod(inst_phase, 2 * pi);

            % Calculate the duration spent per bin to calculate firing rates
            binCounts = binCounts+histcounts(normalized_phase, bin_edges);

            section_spikeTimes = spikeTimes(spikeTimes >= (ts(1)-meanFrameDur/2) & spikeTimes < (ts(end)+meanFrameDur/2));
            touchEvents = HispeedTrials.ContactLeft{sec}/1000; % in sec
            % Exclude all spikes that occur within a pre-defined time
            % window to get rid of unspecific touch evoked activity
            timeDiffs = arrayfun(@(x) min(x-touchEvents(touchEvents<=x)), section_spikeTimes, 'UniformOutput', false);
            section_spikeTimes = section_spikeTimes(cellfun(@(x) isempty(x) || x>=spikeExclusion,timeDiffs));
            % Interpolate the phase for each spike time
            spike_phases = interp1(TT_angles.Time, normalized_phase, seconds(section_spikeTimes), 'linear', 'extrap');
            spikesPerBin = spikesPerBin+histcounts(spike_phases, bin_edges);
        end

        % Overall duration per bin
        durPerBin = meanFrameDur.*binCounts;

        % For stability, remove bin counts lower than 10
        spikesPerBin(binCounts<10) = 0;

        % We characterized the modulation of each unit by fitting a sine wave
        % with a period 2π to the rate versus phase in the whisk cycle with
        % standard linear least-squares regression techniques.

        fo.StartPoint = [mean(spikesPerBin./durPerBin,'omitmissing') range(spikesPerBin./durPerBin)/2 pi];
        fo.Lower = [0 0 0];
        fo.Upper = [inf inf 2*pi];

        PhaseMod = fit(refVals', spikesPerBin'./durPerBin', ft, fo);
        preferredPhase(unit) = PhaseMod.pref_phase;
        modulationDepth(unit) = 2*PhaseMod.amp/PhaseMod.mean_r;
        SNR(unit) = modulationDepth(unit)*sqrt(PhaseMod.mean_r * .111);

        % Create the array where each value occurs as specified
        indiWhiskBinCounts = [];
        indiSpikeBinCounts = [];
        for i = 1:length(binCounts)
            indiWhiskBinCounts = [indiWhiskBinCounts, repmat(refVals(i), 1, binCounts(i))]; %#ok<AGROW>
            indiSpikeBinCounts = [indiSpikeBinCounts, repmat(refVals(i), 1, spikesPerBin(i))]; %#ok<AGROW>
        end
        if ~isempty(indiSpikeBinCounts) && numel(indiSpikeBinCounts)>=5
            pVal_temp = circ_kuipertest(indiWhiskBinCounts, indiSpikeBinCounts, 200);
        else
            pVal_temp = NaN;
        end
        p_value(unit) = pVal_temp;

        if p_value(unit)<=0.05
            modulationSign(unit) = true;
        end
    end

    unitTuning{ses} = cell2table([sortedData(:,1), sortedData(:,4), num2cell(modulationSign), ...
        num2cell(p_value), num2cell(modulationDepth), num2cell(SNR), num2cell(preferredPhase)],...
        "VariableNames",{'unitID','area','modulationSign','p_value','modulationDepth','SNR','preferredPhase'});

    % Progress bar (without parallel processing)
    if ses==numel(fileSelection)
        fprintf('100%% of sessions analyzed.\n')
    elseif ses/numel(fileSelection)>=0.05*count
        fprintf('%i%% of sessions analyzed.\n',5*count)
        count = count+1;
    end
end

unitTuning_concat = vertcat(unitTuning{:});

clear fig
fig(2) = figure('Name',sprintf('WhiskerPhase_PolarPlots%s',figSuffix));

fig(3) = figure('Name',sprintf('WhiskerPhase_MeanStdGraph%s_perAnimal',figSuffix));
ax3 = axes(fig(3));
xticks(ax3,(1:numel(area_names)))
xticklabels(ax3,area_names)
xlim(ax3, [0.5 numel(area_names)+0.5])
ylim(ax3,[0 1])
ylabel(ax3,'Proportion')
title(ax3,'Proportion of whisker phase tuned units')

totalUnits = NaN(1,numel(area_names));
signUnits_abs = NaN(1,numel(area_names));

% Save one mean value per area per individual
signUnits_rel_anim = NaN(numel(indiAnimals),numel(area_names));
for ar = 1:numel(area_names)
    % Plot the amount of tuned units per area
    totalUnits(ar) = sum(contains(unitTuning_concat.area,area_names{ar}));
    signUnits = contains(unitTuning_concat.area,area_names{ar}) & unitTuning_concat.modulationSign;
    signUnits_abs(ar) = sum(signUnits);
    signUnits_rel = sum(signUnits)/totalUnits(ar);

    % Plot the average tuning direction of all significant units
    signUnits_dir = unitTuning_concat.preferredPhase(signUnits);

    % Set radii to a constant of 1
    radii = unitTuning_concat.SNR(signUnits);

    % Create polar plot
    ax_sp = subplot(2, 2, ar, polaraxes, 'Parent', fig(2));
    compassplot(ax_sp, signUnits_dir, radii, 'Color', [0.7 0.7 0.7]); % Initial polar plot
    hold(ax_sp, 'on')

    % Compute mean angle
    mean_angle = angle(mean(exp(1i * signUnits_dir )));
    mean_rho = mean(radii);
    compassplot(ax_sp, mean_angle, mean_rho,'Color', area_colors{ar},'LineWidth', 2);

    axis(ax_sp, 'tight')
    title(ax_sp, area_names{ar})
    hold(ax_sp, 'off')
    if ar==numel(area_names)
        sgtitle(fig(2), 'Polar plots of tuned units with mean vector')
    end

    % Plot modulated units as mean with std of each session
    for anim = 1:numel(indiAnimals)
        animalIdx = ismember(animalNum,indiAnimals(anim));
        signUnits_rel = NaN(sum(animalIdx),1);
        count = 1;
        for ses = find(animalIdx)'
            totalUnits_ses = sum(contains(unitTuning{ses}.area,area_names{ar}));
            signUnits_ses = contains(unitTuning{ses}.area,area_names{ar}) & unitTuning{ses}.modulationSign;
            signUnits_rel(count) = sum(signUnits_ses)/totalUnits_ses;
            count = count + 1;
        end

        signUnits_rel_anim(anim,ar) = mean(signUnits_rel,'omitmissing');
    end

    % Plot individual animals
    hold(ax3,'on')
    plot(ax3,ar * ones(1,height(signUnits_rel_anim)), signUnits_rel_anim(:,ar), 'o', ...
        'MarkerEdgeColor', [0.5 0.5 0.5], 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 4);
    errorbar(ax3, ar, mean(signUnits_rel_anim(:,ar),'omitmissing'), std(signUnits_rel_anim(:,ar),'omitmissing'),...
        'o','LineWidth',3,'CapSize',10,'MarkerSize',10,'Color',area_colors{ar},'MarkerFaceColor',area_colors{ar});
    hold(ax3,'off')
end

%% Helper functions

function [modulationIndex, modulationMax, modulationSign, plotUnits] = getModulationIndex...
    (modulationIndex,modulationMax,modulationSign,unit,spikesPerBin,durPerBin,...
    spikesPerBin_shuffled,plotUnits,includeBins,bin_edges,binSize,sortedData,destinationDir,angleType)

area_names = {'BC','VPM','POm','ZIv'};
area_colors = {'#377eb8','#4daf4a','#984ea3','#ff7f00'};
refVals = bin_edges(1:end-1)+binSize/2;

modulationIndex(unit) = (max(spikesPerBin(includeBins)./durPerBin(includeBins))-min(spikesPerBin(includeBins)./durPerBin(includeBins)))/...
    mean(spikesPerBin(includeBins)./durPerBin(includeBins),'omitmissing');
[~,binIdx] = max(spikesPerBin(includeBins)./durPerBin(includeBins));
binIdx = find(includeBins,binIdx);
modulationMax(unit) = bin_edges(binIdx(end))+binSize/2;

modulationIndex_shuffled = (max(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins),[],2)-min(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins),[],2))./...
    mean(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins),2,'omitmissing');

% Statistical testing against shuffled data set (see Oram et al. Ahissar 2024)
ar = find(contains(area_names,sortedData{unit,4}));
if modulationIndex(unit) >= prctile(modulationIndex_shuffled,95)
    modulationSign(unit) = true;
    if plotUnits(1,ar)<=3 % Plot 3 sign units per area
        meanRates = mean(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 1, 'omitmissing');
        stdRates = std(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 0, 1, 'omitmissing');

        curve1 = meanRates + stdRates;
        curve2 = meanRates - stdRates;
        x = refVals(includeBins);
        x = x(~isnan(curve1));
        curve1 = curve1(~isnan(curve1));
        curve2 = curve2(~isnan(curve2));

        fig = figure;
        hold on
        fill([x fliplr(x)], [curve1 fliplr(curve2)], [0 0 0.85], ...
            'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
        plot(x, meanRates, 'Color',[.3 .3 .3], 'LineWidth', 2);
        plot(x, spikesPerBin(includeBins)./durPerBin(includeBins),'Color',area_colors{ar},'LineWidth',2)
        hold off
        ylabel('Firing rate [Hz]')
        xlabel(sprintf('Head angle (%s) [deg]',angleType))
        xlim tight
        title(sprintf('Tuned unit of %s (#%s)',area_names{ar},sortedData{unit,1}))
        plotUnits(1,ar) = plotUnits(1,ar)+1;
        destfile = fullfile(destinationDir,sprintf('ExampleUnit_Tuned_%s_%s#%s.fig',angleType,area_names{ar},sortedData{unit,1}));
        savefig(fig, destfile);
    end
elseif plotUnits(2,ar)<=3 % Plot 3 insign units per area
    meanRates = mean(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 1, 'omitmissing');
    stdRates = std(spikesPerBin_shuffled(:,includeBins)./durPerBin(includeBins), 0, 1, 'omitmissing');

    curve1 = meanRates + stdRates;
    curve2 = meanRates - stdRates;
    x = refVals(includeBins);
    x = x(~isnan(curve1));
    curve1 = curve1(~isnan(curve1));
    curve2 = curve2(~isnan(curve2));

    fig = figure;
    hold on
    fill([x fliplr(x)], [curve1 fliplr(curve2)], [0 0 0.85], ...
        'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
    plot(x, meanRates, 'Color',[.3 .3 .3], 'LineWidth', 2);
    plot(x, spikesPerBin(includeBins)./durPerBin(includeBins),'Color',area_colors{ar},'LineWidth',2)
    hold off
    ylabel('Firing rate [Hz]')
    xlabel(sprintf('Head angle (%s) [deg]',angleType))
    xlim tight
    title(sprintf('Not tuned unit of %s (#%s)',area_names{ar},sortedData{unit,1}))
    plotUnits(2,ar) = plotUnits(2,ar)+1;
    destfile = fullfile(destinationDir,sprintf('ExampleUnit_NotTuned_%s_%s#%s.fig',angleType,area_names{ar},sortedData{unit,1}));
    savefig(fig, destfile);
end
end


function sortedData = getWaveformDistribution(clWaveforms,sortedData)
trough2peak_dur = nan(1,size(clWaveforms,1));
for unit = 1:size(clWaveforms,1)
    mean_waveform = mean(clWaveforms{unit,2},2);
    [~,troughs_loc,~,~] = findpeaks(-mean_waveform,'SortStr','descend','NPeaks',1);
    [~,peak_loc,~,~] = findpeaks(mean_waveform);
    if ~isempty(find(peak_loc > troughs_loc,1))
        peak_loc = peak_loc(find(peak_loc > troughs_loc,1));
        trough2peak_dur(unit) = abs(diff([peak_loc,troughs_loc]));
    else
        try
            peak_loc = peak_loc(find(peak_loc < troughs_loc,1,'last'));
            trough2peak_dur(unit) = abs(diff([peak_loc,troughs_loc]));
        catch
            trough2peak_dur(unit) = nan;
        end
    end
end

% Widths are given in data points. Calculate in usecs
framerate = 30000; % in Hz
trough2peak_usec = (trough2peak_dur/framerate)*1000000;

put_ex_idx = false(height(clWaveforms),1);

% Choose trough to peak cutoff of 300 µs for thalamic nuclei
idx = find(cellfun(@(x) ismember(x, {'VPM','POm'}),sortedData(:,4)));
put_ex_idx(idx) = trough2peak_usec(idx) >= 300;

% Choose trough to peak cutoff of 350 µs for cortex and ZI
idx = find(cellfun(@(x) ismember(x, {'BC','ZIv'}),sortedData(:,4)));
put_ex_idx(idx) = trough2peak_usec(idx) >= 350;

% Filter putative excitatory units for BC, VPM, and POm, and keep all units of ZIv
filterIdx = (cellfun(@(x) ismember(x, {'BC','VPM','POm'}),sortedData(:,4)) & put_ex_idx) | ...
    (cellfun(@(x) ismember(x, {'ZIv'}),sortedData(:,4)));

sortedData = sortedData(filterIdx,:);

end