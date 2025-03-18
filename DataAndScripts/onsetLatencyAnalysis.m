%% Visualize onset latencies of first tonic/burst response

% Choose a cohort and stage
close all; clearvars; clc
currentFolder = pwd;
fileName = fullfile(currentFolder,'\RawData\animalData.mat');
load(fileName,'animalData')

% Define brain areas
area_names = {'BC','VPM','POm','ZIv'};
area_colors = {'#377eb8','#4daf4a','#984ea3','#ff7f00'};

% Pick sessions to analyze
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

%% Define conditions

close all
spikeType = {'All','Tonic','Burst'};

% Define the trial type to plot (if only one spike condition was picked,
% multiple trial types can be selected)
trialType = {'All', 'Wide', 'Wide&lick', 'Wide&no-lick',...
    'Narrow', 'Narrow&lick', 'Narrow&no-lick',...
    'Intermediate', 'Intermediate&lick', 'Intermediate&no-lick'};

[trialPick, tf] = listdlg('ListString',trialType,...
    'PromptString','Which trial type(s) do you want to analyze (max. 3)?',...
    'SelectionMode','multiple','ListSize', [250 250]);
if tf==0
    return
end
assert(numel(trialPick)<=3,...
    'onsetLatencyAnalysis:selectInputNumber',...
    'Max. number of trial types is 3.')
trialType = trialType(trialPick);

%% Extract latency information
% Get the mean initial spike latency for each cell and save it in an array

LatencyTables = cell(1,height(fileSelection));
for file = 1:height(fileSelection)
    currFile = fileSelection{file};
    % For first burst consider the BurstStarts variable from BurstinessData.mat
    % For first tonic consider the sortedData variable from *all_channels.mat
    % Get burst data from file
    load(fullfile(currFile,'BurstinessData.mat'),'BurstStarts','unitIDs')

    dataInfo = dir(fullfile(currFile,'*all_channels.mat'));
    try
        load(fullfile(dataInfo(1).folder,dataInfo(1).name),'sortedData','fs')
        sortedData = sortedData(all(~cellfun(@isempty, sortedData),2),:);
        clInfo = getClusterInfo(fullfile(currFile,'cluster_info.tsv'));
    catch
        fprintf('\nCould not gather sortedData and clInfo.\n')
        return
    end

    str_idx = regexp(currFile,'#\d*','end');
    animalPath = currFile(1:str_idx);
    % Include only those units, which tetrodes were within the recording area
    load(fullfile(animalPath,'targetHit.mat'),'targetHit')

    clInfo.group(cell2mat(sortedData(:,3))==1) = deal({'good'});
    clInfo.group(cell2mat(sortedData(:,3))==2) = deal({'mua'});
    clInfo.group(cell2mat(sortedData(:,3))==3) = deal({'noise'});

    include = ismember(clInfo.group,{'good','mua'}) & clInfo.isolation_distance > 15 & clInfo.isi_viol < 3 & ismember(clInfo.ch,targetHit);
    sortedData = sortedData(include,:);

    assert(all(cellfun(@isequal,unitIDs,sortedData(:,1))), ...
        'onsetLatencyAnalysis:unitIDmismatch',...
        'The unitIDs of the sortedData and the BurstinessData must match.')

    % Label units with their respective area as subscripts
    sortedData(:,4) = deal({'NaN'});
    for unit = 1:height(sortedData)
        depth = clInfo.depth(strcmp(clInfo.id,char(sortedData{unit,1})));
        switch depth
            case 1
                sortedData{unit,4} = 'BC';
            case 1400
                sortedData{unit,4} = 'POm';
            case 1700
                sortedData{unit,4} = 'VPM';
            case 2400
                sortedData{unit,4} = 'ZIv';
        end
    end

    % Filter for correct waveform, i.e.,
    % BC-RS, VPM-RS, POm-RS, ZIv-All
    WaveformInfo = dir(fullfile(currFile, '*waveforms_all.mat'));
    load(fullfile(WaveformInfo.folder,WaveformInfo.name),'clWaveforms')

    if all(cellfun(@(x,y) isequal(x,y), sortedData(:,1),clWaveforms(:,1)))
        [~, put_ex_idx] = getWaveformDistribution(clWaveforms,ClusterBurstiness.area);
    elseif all(cellfun(@(x) any(ismember(sortedData(:,1),x)), clWaveforms(:,1)))
        % Order the units according to the ClusterBurstiness table
        unitOrder = nan(height(sortedData),1);
        for cl = 1:height(sortedData)
            unitOrder(cl) = find(ismember(clWaveforms(:,1),sortedData{cl,1}));
        end
        clWaveforms = clWaveforms(unitOrder,:);

        [~, put_ex_idx] = getWaveformDistribution(clWaveforms,sortedData(:,4));
    else
        error('burstUponTrigger:waveformUnitsError','Units in the clWaveforms variable do not match the ones from the ClusterBurstiness table.')
    end
    
    % Filter putative excitatory units for BC, VPM, and POm, and keep all units of ZIv
    idx = false(height(sortedData),1);
    for ar = 1:numel(area_names)
        if ismember(area_names{ar}, {'BC','VPM','POm'})
            idx = idx | (put_ex_idx' & contains(sortedData(:,4),area_names{ar}));
        else
            idx = idx | contains(sortedData(:,4),area_names{ar});
        end
    end
    cellSelect = idx;
    
    sortedData = sortedData(cellSelect,:);
    BurstStarts = BurstStarts(cellSelect);

    % Get the touch events from the file
    load(fullfile(fileparts(fileparts(currFile)),'videos\HispeedTrials.mat'),'HispeedTrials');

    % Create table with unitID, area, trialType, latencyBurst,
    % latencyTonic, latencyAll
    LatencyTables{file} = table('Size',[height(sortedData)*numel(trialType), 6],'VariableTypes',...
        [repmat({'cell'},1,3),repmat({'double'},1,3)],'VariableNames',...
        {'unitID', 'area', 'trialType', 'latencyBurst', ...
        'latencyTonic', 'latencyAll'});

    count = 1;
    for unit = 1:height(sortedData)
        for i = 1:numel(trialType)
            if ~isequal(trialType{i},'All')
                if contains(trialType{i},'Wide')
                    logApert = HispeedTrials.Go_NoGo_Neutral_settingBased==1;
                elseif contains(trialType{i},'Narrow')
                    logApert = HispeedTrials.Go_NoGo_Neutral_settingBased==2;
                elseif contains(trialType{i},'Intermediate')
                    logApert = HispeedTrials.Go_NoGo_Neutral_settingBased==3;
                else
                    logApert = true(height(HispeedTrials),1);
                end

                if contains(trialType{i},'no-lick')
                    logLick = HispeedTrials.Lick==0;
                elseif contains(trialType{i},'lick')
                    logLick = HispeedTrials.Lick==1;
                else
                    logLick = true(height(HispeedTrials),1);
                end
                logicalFlag = logApert & logLick;
            else
                logicalFlag = true(height(HispeedTrials),1);
            end
            HispeedTrials_temp = HispeedTrials(logicalFlag,:);

            tempLatencyBurst = NaN(height(HispeedTrials_temp),1);
            tempLatencyTonic = NaN(height(HispeedTrials_temp),1);
            for trial = 1:height(HispeedTrials_temp)
                if ~isempty(HispeedTrials_temp.ContactLeft{trial})
                    touchEvent = HispeedTrials_temp.ContactLeft{trial}(1); % First touch in msec
                else
                    touchEvent = NaN;
                end

                % Latency to lick event in msec with a max latency of 200 msec in order to not
                % skew the mean when cells are e.g. not bursting
                if ~isnan(HispeedTrials_temp.Event_Index(trial))
                    cutoff = min([200, ...
                        HispeedTrials_temp.Timestamps{trial}(HispeedTrials_temp.Event_Index(trial))-touchEvent]);
                else
                    cutoff = min([200, ...
                        HispeedTrials_temp.Timestamps{trial}(end)-touchEvent]);
                end

                firstBurstIdx = find(BurstStarts{unit}-touchEvent>0,1);

                if ~isempty(firstBurstIdx) && BurstStarts{unit}(firstBurstIdx)-touchEvent <= cutoff
                    tempLatencyBurst(trial) = BurstStarts{unit}(firstBurstIdx)-touchEvent;
                end
                
                firstTonicIdx = find(sortedData{unit,2}.*1000-touchEvent>0,1);
                if ~isempty(firstTonicIdx) && sortedData{unit,2}(firstTonicIdx)*1000-touchEvent <= cutoff
                    tempLatencyTonic(trial) = sortedData{unit,2}(firstTonicIdx)*1000-touchEvent;
                end
            end

            % Access PSTHs to estimate first bin with significant firing rate
            binSz = 0.001;
            fileName = fullfile(currFile,sprintf('allResponses_WhiskerContact_left_on_%sbz_-1.6_0.8timeLapse_0_0.2respWind_-0.8_-0.6spontWind_%s.mat',...
                num2str(binSz), lower(trialType{i})));
            if ~exist(fileName,'file')
                adjCond = strsplit(lower(trialType{i}),'&');
                DE_Salience_function(currFile,'binSz',binSz,'timeLapse',[-1.6 0.8],'adjustConditions',adjCond,'getWaveFlag','none');
                close all;
            end
            load(fileName,'PSTH_all','timeLapse')

            assert(timeLapse(1)<0)
            baselineBins = abs(timeLapse(1))/binSz;

            % Compute lambda as the mean of pre trigger bins
            lambda = mean(PSTH_all(unit, 1:baselineBins-1));

            % Iterate over columns untill observed spike count is significant
            tempLatencyAll = NaN;
            for col = baselineBins:length(PSTH_all)
                observedCount = PSTH_all(unit, col);

                % Compute lower and upper tail probabilities
                pLower = poisscdf(observedCount, lambda);
                % Subtract 1 in order to get the probability for >= observedCount
                pUpper = poisscdf(observedCount-1, lambda,'upper');

                % Compute two-tailed p-value
                % pValue = 2 * min(pLower, pUpper);
                pValue = pUpper;

                % Check if the p-value is below alpha
                if pValue <= 0.05 && (col-baselineBins+0.5) * binSz*1000 <= cutoff
                    tempLatencyAll = (col-baselineBins+0.5) * binSz*1000; % Convert sec into msec
                    break; % Exit loop after finding the first significant column
                end
            end

            LatencyTables{file}(count,:) = table(sortedData(unit,1),sortedData(unit,4),trialType(i), ...
                median(tempLatencyBurst,'omitnan'), median(tempLatencyTonic,'omitnan'), ...
                median(tempLatencyAll,'omitnan'));
            count = count + 1;
        end
    end
end

LatencyConcat = vertcat(LatencyTables{:});

%% Plot results
% Plot combined scatter and violin plot for each area
% Each dot represents the mean onset latency of a cell

for i = 1:numel(trialType)
    BoxGroups = cell(1,numel(area_names));
    for ar = 1:numel(area_names)
        idx = cellfun(@(x) isequal(x, area_names{ar}), LatencyConcat.area) & cellfun(@(x) isequal(x, trialType{i}), LatencyConcat.trialType);
        BoxGroups{ar} = [LatencyConcat.latencyAll(idx),LatencyConcat.latencyTonic(idx),LatencyConcat.latencyBurst(idx)];
    end
    
    figure('Name',sprintf('ViolinPlots_%s',trialType{i}));
    boxResults = cellfun(@(x) x(:,1), BoxGroups, 'UniformOutput', false);

    catdata = categorical([repmat({'BC'},height(BoxGroups{1}),1); repmat({'VPM'},height(BoxGroups{2}),1); ...
        repmat({'POm'},height(BoxGroups{3}),1); repmat({'ZIv'},height(BoxGroups{4}),1)], ...
        area_names, 'Ordinal', true);
    v = violinplot(vertcat(boxResults{:}),catdata,'ShowMean',true,'ShowBox',...
        false,'ShowMedian',false,'ShowWhiskers',false,'ViolinAlpha',{[0.1,0.2]},...
        'MeanLineWidth',4);
    for ar = 1:numel(area_names)
        v(ar).ViolinColor{:} = hex2rgb(area_colors{ar});
    end

    figure('Name',sprintf('GroupBoxPlots_%s',trialType{i}))
    bp = boxplotGroup(BoxGroups,'Symbol','.','Notch','on','primaryLabels', ...
        area_names,'secondaryLabels',spikeType,'groupLabelType','vertical', ...
        'Colors',cell2mat(cellfun(@hex2rgb, area_colors, 'UniformOutput', false)'));
    ylabel('Onset latency [ms]')
    title(sprintf('Onset latencies upon aperture touch (%s trials)',lower(trialType{i})),'Interpreter','none')
    axis auto
end

%% Helper functions

function [put_in_idx, put_ex_idx] = getWaveformDistribution(clWaveforms,areaCell)
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

% Choose trough to peak cutoff of 300 µs for thalamic nuclei
idx = find(cellfun(@(x) ismember(x, {'VPM','POm'}),areaCell));
put_in_idx(idx) = trough2peak_usec(idx) < 300;
put_ex_idx(idx) = trough2peak_usec(idx) >= 300;

% Choose trough to peak cutoff of 350 µs for cortex and ZI
idx = find(cellfun(@(x) ismember(x, {'BC','ZIv'}),areaCell));
put_in_idx(idx) = trough2peak_usec(idx) < 350;
put_ex_idx(idx) = trough2peak_usec(idx) >= 350;
end