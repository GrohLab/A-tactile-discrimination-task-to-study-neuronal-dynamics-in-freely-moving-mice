%% Burst decoding
% Calculate the accuracy for the aperture encoding of burst spikes
close all; clearvars; clc

figDir = 'Z:\Filippo\Animals\Cohort12_33-38';
% Choose sessions to merge together
try
    load('Z:\Filippo\Animals\animalData.mat')
    load(fullfile(figDir,'allFiles.mat'),'FileInfo')
catch
end

prompt = {'Choose individual sessions',...
    'Stage 1','Stage 2','Stage 3','Stage 4','Stage 5','Stage 6',...
    'Stage 7','Stage 8','Stage 9'};
filePick = listdlg('PromptString',{'Which sessions do you want to analyze?';'Possible to refine stage sessions afterwards.'}, ...
    'ListString',prompt,...
    'ListSize',[300 200],'InitialValue',1,'SelectionMode','single');

if filePick==1
    fileSelection = cellfun(@(x) fullfile(fileparts(x),'intan-signals\automatedCuration'), {FileInfo.folder}, 'UniformOutput', false)';
    answer = listdlg('ListString',fileSelection,...
        'PromptString','Choose sessions to plot.',...
        'ListSize',[600 350]);
    fileSelection = fileSelection(answer,:);
else
    stageNum = str2double(regexp(prompt{filePick},'\d*','match','once'));

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

    prompt = {'d'' -Inf to -1.65', 'd'' -1.65 to -0.5',...
        'd'' -0.5 to 0.5','d'' 0.5 to 1.65',...
        'd'' 1.65 to Inf','First two sessions',...
        'Last two sessions','All sessions of that stage'};
    performancePick = listdlg('PromptString',{'Which sessions from that stage do you want to analyze?';'Possible to refine stage sessions afterwards.'}, ...
        'ListString',prompt,...
        'ListSize',[300 200],'InitialValue',5,'SelectionMode','single');

    if ismember(performancePick,(1:5))
        all_dprimes = vertcat(all_dprimes{:});
        all_sesNames = vertcat(all_sesNames{:});
        [~,~,group] = histcounts(all_dprimes,'BinEdges',[-Inf,-1.65,-0.5,0.5,1.65,Inf]);
        fileSelection = fullfile(fileparts(fileparts(all_sesNames(group==performancePick))),'intan-signals\automatedCuration');
    elseif performancePick==6
        all_sesNames = cellfun(@(x) x(1:2),all_sesNames,'UniformOutput',false);
        all_sesNames = vertcat(all_sesNames{:});
        fileSelection = fullfile(fileparts(fileparts(all_sesNames)),'intan-signals\automatedCuration');
    elseif performancePick==7
        all_sesNames = cellfun(@(x) x(end-1:end),all_sesNames,'UniformOutput',false);
        all_sesNames = vertcat(all_sesNames{:});
        fileSelection = fullfile(fileparts(fileparts(all_sesNames)),'intan-signals\automatedCuration');
    elseif performancePick==8
        all_sesNames = vertcat(all_sesNames{:});
        fileSelection = fullfile(fileparts(fileparts(all_sesNames)),'intan-signals\automatedCuration');
    end
end

% Exclude this file, since it is corrupted
fileSelection = fileSelection(~contains(fileSelection, 'Z:\Filippo\Animals\Cohort12_33-38\#35\2021-11-11\P3.2_50pctReward_session12\intan-signals\automatedCuration'));
fileSelection = fileSelection(~contains(fileSelection, 'Z:\Filippo\Animals\Cohort12_33-38\#37\2021-12-01\P3.5_ruleswitch_lidocaine_session02\intan-signals\automatedCuration'));

if exist('stageNum','var')
    if contains(prompt{performancePick},'two')
        suffix = lower(strrep(prompt{performancePick},' two ','2'));
    elseif contains(prompt{performancePick},'All')
        suffix = 'allSessions';
    else
        suffix = regexp(prompt{performancePick},'[-+]?(\d+\.?\d*|\.\d+)|[-+]?Inf','match');
        suffix = ['dprime',cell2mat(join(suffix,'_'))];
    end
    definput = sprintf('stage%i-%s',stageNum,suffix);
    sessionDescription = inputdlg('Enter a session description for saving the files:','Output Folder',[1 100],{definput});
else
    sessionDescription = inputdlg('Enter a session description for saving the files:','Output Folder',[1 100]);
end
raster_data_dir = fullfile(figDir,'NeuralDecoding',sessionDescription{:});

% Choose condition to analyze
% Available conditions: 'Reward', 'Punishment', 'Lick','onlyFirstLick',
% 'WhiskerContact_left', 'WhiskerContact_right',
% 'WhiskerContact_onlyLeftFirst','WhiskerContact_onlyRightFirst'
chCond = 'WhiskerContact_left';

% Specify which trial types you want to analyze
trialType = {'allTrials','onlyGo','onlyNoGo','onlyNeutral','onlyNarrow','onlyWide','onlyIntermediate','onlyLick','onlyNoLick'};
[trial_idx,tf] = listdlg('PromptString',{'Specify trial type'},...
    'ListSize',[300 200],...
    'ListString',trialType);
if tf == 0
    % If nothing is picked, move on with unfiltered trial analysis
    trial_idx = 1;
end
trialType = trialType{trial_idx};

% Create raster_data.mat files
create_raster_data_files(fileSelection, raster_data_dir, chCond, trialType);

%% Run the decoder
% Define brain areas
area_names = {'BC','VPM','POm','ZIv'};
area_colors = {'#377eb8','#4daf4a','#984ea3','#ff7f00'};

f = figure('Name','Waveform type');
set(gcf,'Position',[1000 600 420 300])
ui_field = gobjects(numel(area_names),1);
ui_text = gobjects(numel(area_names)+1,1);

ui_text(1) = uicontrol(f,'Style','text','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.1 0.85 0.8 0.1],...
    'FontSize',10,'String','Choose the desired subpopulation for each area.');

for i = 1:numel(area_names)
    ui_text(i+1) = uicontrol(f,'Style','text','Units','normalized',...
        'HorizontalAlignment','left','Position',[0.1 0.85-0.1*i 0.1 0.05],...
        'FontSize',10,'String',area_names{i});
    
    if isequal(area_names{i},'ZIv')
        initVal = 3;
    else
        initVal = 2;
    end
    ui_field(i) = uicontrol(f,'Style','popupmenu','Units','normalized',...
        'HorizontalAlignment','left','Position',[0.2 0.85-0.1*i 0.2 0.05],...
        'FontSize',10,'String',{'all','RS units','FS units'},'Value', initVal);
end

doneButton = uicontrol(f,'Style','pushbutton','units','normalized',...
    'Position',[0.8 0.1 0.1 0.05],'String','Done',...
    'Callback',{@doneExe,f,ui_field,area_names});

waitfor(doneButton)

answer = questdlg('What do you want to decode?','Decoding object',...
    'Go - No-go - Neutral','Wide - Narrow - Interm.','Lick - No-lick','Wide - Narrow - Interm.');
if isequal(answer, 'Go - No-go - Neutral')
    classifier_labels = 'Go_NoGo_Neutral';
elseif isequal(answer, 'Wide - Narrow - Interm.')
    classifier_labels = 'Wide_Narrow_Intermediate';
elseif isequal(answer, 'Lick - No-lick')
    classifier_labels = 'Lick';
end

% Define the classifier to use
% 'max_correlation_coefficient_CL','poisson_naive_bayes_CL','libsvm_CL'
classifierName = 'libsvm_CL';

% Set a desired number of splits. A split of 10 means that 9 repetitions of
% each event are used for training and 1 example is used for testing.
% To get reasonable results you usually need at least 5 repetitions of each
% event (i.e., at least 5 splits)
splitNumber = inputdlg(sprintf('Enter the desired number of splits\n(NaN if you want to estimate it\nbased on the unit and event count):'),'Split number',[1 50],{'NaN'});
splitNumber = str2double(splitNumber);
%% Plot results

switch classifier_labels
    case 'Go_NoGo_Neutral'
        prefix = 'Trial type';
    case 'Lick'
        prefix = 'Lick';
    case 'Wide_Narrow_Intermediate'
        prefix = 'Aperture';
end

% Compare area-specific decoding accuracies
areaDecoding = cell(numel(area_names),1);

% Plot decoding accuracies with selective spike types
for ar = 1:numel(area_names)
    boxData = cell(3,1);
    % Define the window, in which you want to extract the prediction
    % accuracies for the box plots [msec]
    boxStart = 0;
    boxEnd = 400;

    % Create overview figure with subplots
    overview = figure;
    sgtitle(sprintf('%s prediction accuracy based on %s',prefix,chCond),'Interpreter','none')
    ax1 = subplot(2,2,1,'parent',overview);
    ax2 = subplot(2,2,2,'parent',overview);
    ax3 = subplot(2,2,3,'parent',overview);
    ax4 = subplot(2,2,4,'parent',overview);

    % Run neural decoding toolbox on respective spike types
    % All spikes together
    unitType = 'allUnits';
    spikeType = 'allSpikes';
    [RastFig, DecodeFig, splits_all, units_all] = runNeuralDecodingToolbox(raster_data_dir,area_names{ar},chCond,spikeType, ...
        unitType,trialType,classifier_labels,classifierName,'num_cv_splits',splitNumber);
    close(RastFig)

    title(DecodeFig.Children,sprintf('%s - all spikes',area_names{ar}))
    idx = DecodeFig.Children.Children(end).XData>=boxStart & DecodeFig.Children.Children(end).XData<boxEnd;
    boxData{1} = DecodeFig.Children.Children(end).YData(idx);
    areaDecoding{ar} = DecodeFig.Children.Children(end).YData(idx);
    axcp = copyobj(DecodeFig.Children, overview);
    set(axcp,'Position',get(ax1,'position'));
    delete(ax1);
    close(DecodeFig)

    % Burst spikes only
    spikeType = 'burstSpikes';
    [RastFig, DecodeFig, splits_bursts, units_bursts] = runNeuralDecodingToolbox(raster_data_dir,area_names{ar},chCond,spikeType, ...
        unitType,trialType,classifier_labels,classifierName,'num_cv_splits',splitNumber);
    close(RastFig)

    title(DecodeFig.Children,sprintf('%s - burst spikes',area_names{ar}))
    idx = DecodeFig.Children.Children(end).XData>=boxStart & DecodeFig.Children.Children(end).XData<boxEnd;
    boxData{2} = DecodeFig.Children.Children(end).YData(idx);
    axcp = copyobj(DecodeFig.Children, overview);
    set(axcp,'Position',get(ax3,'position'));
    delete(ax3);
    close(DecodeFig)

    % Tonic spikes only
    spikeType = 'tonicSpikes';
    [RastFig, DecodeFig, splits_tonic, units_tonic] = runNeuralDecodingToolbox(raster_data_dir,area_names{ar},chCond,spikeType, ...
        unitType,trialType,classifier_labels,classifierName,'num_cv_splits',splitNumber);
    close(RastFig)

    title(DecodeFig.Children,sprintf('%s - tonic spikes',area_names{ar}))
    idx = DecodeFig.Children.Children(end).XData>=boxStart & DecodeFig.Children.Children(end).XData<boxEnd;
    boxData{3} = DecodeFig.Children.Children(end).YData(idx);
    axcp = copyobj(DecodeFig.Children, overview);
    set(axcp,'Position',get(ax4,'position'));
    delete(ax4);
    close(DecodeFig)

    % Create box plot from the decoding accuracies of the response window
    boxData = cell2mat(boxData);
    hold(ax2,'on')
    boxchart(ax2, boxData','BoxFaceColor',area_colors{ar},'MarkerColor',area_colors{ar})
    xticklabels(ax2,{'all','burst','tonic'})
    ylabel(ax2,{'Accuracy after', 'trigger onset [%]'})

    p = signrank(boxData(2,:),boxData(3,:));
    ylims = ylim(ax2);
    if p <= 0.001
        plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, '***','HorizontalAlignment','center')
    elseif p <= 0.01
        plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, '**','HorizontalAlignment','center')
    elseif p <= 0.05
        plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, '*','HorizontalAlignment','center')
    else
        plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, 'n.s.','HorizontalAlignment','center')
    end
    ylim(ax2,[ylims(1)-10 ylims(2)])

    overview.UserData = struct('boxData_msec', [boxStart boxEnd],...
        'targetEstimate',true,...
        'splits_all',splits_all,...
        'units_all',units_all,...
        'splits_bursts',splits_bursts,...
        'units_bursts',units_bursts,...
        'splits_tonic',splits_tonic,...
        'units_tonic',units_tonic, ...
        'pVal_tonicVSburst',p);
    if isequal(splits_all, splits_bursts, splits_tonic)
        overview.Name = sprintf('%s_spikeSelection_%isplits',area_names{ar},splits_all);
    else
        minSplits = min([splits_all, splits_bursts, splits_tonic]);
        overview.Name = sprintf('%s_spikeSelection_%isplits',area_names{ar},minSplits);
    end
end

% Plot area-specific decoding accuracies (all spikes included)
fig = figure;
hold on
areaDecoding = cell2mat(areaDecoding)';
for ar = 1:numel(area_names)
    boxchart(ones(height(areaDecoding),1)*ar,areaDecoding(:,ar),'BoxFaceColor',area_colors{ar},'MarkerColor',area_colors{ar})
end
xticks(1:numel(area_names))
xticklabels(area_names)
ylabel({'Accuracy after', 'trigger onset [%]'})
title('Comparison of decoding accuracies')
ylim([30 100])
% Currently the default split number in runNeuralDecodingToolbox is 10, so
% if no splitNumber is defined previously, assume 10 as split count
if isnan(splitNumber)
    fig.Name = sprintf('DecodingComparison_%isplits',splits_all);
else
    fig.Name = sprintf('DecodingComparison_%isplits',splitNumber);
end

% Statistical test on each area
pvals_UserData = cell(factorial(numel(area_names)-1),2);
count = 1;
for ar = 1:numel(area_names)
    for comp = ar+1:numel(area_names)
        p = ranksum(areaDecoding(:,ar),areaDecoding(:,comp));
        xvals = [ar+0.1 comp-0.1];
        if comp-ar==3
            yval = 39;
        else
            yval = 48-3*(comp-ar-1)*ar;
        end

        if p <= 0.001
            plot(xvals, [yval yval], '-k'),  text(mean(xvals), yval-2, '***','HorizontalAlignment','center')
        elseif p <= 0.01
            plot(xvals, [yval yval], '-k'),  text(mean(xvals), yval-2, '**','HorizontalAlignment','center')
        elseif p <= 0.05
            plot(xvals, [yval yval], '-k'),  text(mean(xvals), yval-2, '*','HorizontalAlignment','center')
        else
            plot(xvals, [yval yval], '-k'),  text(mean(xvals), yval-1, 'n.s.','HorizontalAlignment','center')
        end
        pvals_UserData{count,1} = sprintf('%svs%s',area_names{ar}, area_names{comp});
        pvals_UserData{count,2} = p;
        count = count+1;
    end
end

fig.UserData = struct('statTest', 'ranksum',...
        'pVals',{pvals_UserData});

%% Plot decoding accuracies with selective unit subpopulation

for ar = 1:numel(area_names)
    boxData = cell(3,1);
    % Define the window, in which you want to extract the prediction
    % accuracies for the box plots [msec]
    boxStart = 0;
    boxEnd = 400;

    % Create overview figure with subplots
    overview = figure;
    sgtitle(sprintf('%s prediction accuracy based on %s',prefix,chCond),'Interpreter','none')
    ax1 = subplot(2,2,1,'parent',overview);
    ax2 = subplot(2,2,2,'parent',overview);
    ax3 = subplot(2,2,3,'parent',overview);
    ax4 = subplot(2,2,4,'parent',overview);

    % Run neural decoding toolbox on respective spike types
    % All spikes together
    unitType = 'noneUnits';
    spikeType = 'allSpikes';
    [RastFig, DecodeFig, splits_none, units_none] = runNeuralDecodingToolbox(raster_data_dir,area_names{ar},chCond,spikeType, ...
        unitType,trialType,classifier_labels,classifierName,'num_cv_splits',splitNumber);
    close(RastFig)

    title(DecodeFig.Children,sprintf('%s - non-responders',area_names{ar}))
    if isequal(class(DecodeFig.Children.Children(end)), 'matlab.graphics.primitive.Text')
        boxData{1} = NaN;
    else
        idx = DecodeFig.Children.Children(end).XData>=boxStart & DecodeFig.Children.Children(end).XData<boxEnd;
        boxData{1} = DecodeFig.Children.Children(end).YData(idx);
    end
    axcp = copyobj(DecodeFig.Children, overview);
    set(axcp,'Position',get(ax1,'position'));
    delete(ax1);
    close(DecodeFig)

    % Burst spikes only
    unitType = 'burstUnits';
    [RastFig, DecodeFig, splits_bursts, units_bursts] = runNeuralDecodingToolbox(raster_data_dir,area_names{ar},chCond,spikeType, ...
        unitType,trialType,classifier_labels,classifierName,'num_cv_splits',splitNumber);
    close(RastFig)

    title(DecodeFig.Children,sprintf('%s - burst responders',area_names{ar}))
    if isequal(class(DecodeFig.Children.Children(end)), 'matlab.graphics.primitive.Text')
        boxData{2} = NaN;
    else
        idx = DecodeFig.Children.Children(end).XData>=boxStart & DecodeFig.Children.Children(end).XData<boxEnd;
        boxData{2} = DecodeFig.Children.Children(end).YData(idx);
    end
    axcp = copyobj(DecodeFig.Children, overview);
    set(axcp,'Position',get(ax3,'position'));
    delete(ax3);
    close(DecodeFig)

    % Tonic spikes only
    unitType = 'tonicUnits';
    [RastFig, DecodeFig, splits_tonic, units_tonic] = runNeuralDecodingToolbox(raster_data_dir,area_names{ar},chCond,spikeType, ...
        unitType,trialType,classifier_labels,classifierName,'num_cv_splits',splitNumber);
    close(RastFig)

    title(DecodeFig.Children,sprintf('%s - tonic responders',area_names{ar}))
    if isequal(class(DecodeFig.Children.Children(end)), 'matlab.graphics.primitive.Text')
        boxData{3} = NaN;
    else
        idx = DecodeFig.Children.Children(end).XData>=boxStart & DecodeFig.Children.Children(end).XData<boxEnd;
        boxData{3} = DecodeFig.Children.Children(end).YData(idx);
    end
    axcp = copyobj(DecodeFig.Children, overview);
    set(axcp,'Position',get(ax4,'position'));
    delete(ax4);
    close(DecodeFig)

    % Create box plot from the decoding accuracies of the response window
    boxMax = max(cellfun(@numel, boxData));
    boxData = cellfun(@(x) [x, nan(1,boxMax-numel(x))], boxData, 'UniformOutput', false);
    boxData = cell2mat(boxData);
    hold(ax2,'on')
    boxchart(ax2, boxData','BoxFaceColor',area_colors{ar},'MarkerColor',area_colors{ar})
    xticklabels(ax2,{'none','burst','tonic'})
    ylabel(ax2,{'Accuracy after', 'trigger onset [%]'})

    if ~all(isnan(boxData(2,:))) && ~all(isnan(boxData(3,:)))
        p = signrank(boxData(2,:),boxData(3,:));
        ylims = ylim(ax2);
        if p <= 0.001
            plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, '***','HorizontalAlignment','center')
        elseif p <= 0.01
            plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, '**','HorizontalAlignment','center')
        elseif p <= 0.05
            plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, '*','HorizontalAlignment','center')
        else
            plot(ax2,[2.1 2.9], [ylims(1)-3 ylims(1)-3], '-k'),  text(ax2,mean([2.1 2.9]), ylims(1)-6, 'n.s.','HorizontalAlignment','center')
        end
        ylim(ax2,[ylims(1)-10 ylims(2)])
    end

    overview.UserData = struct('boxData_msec', [boxStart boxEnd],...
        'targetEstimate',true,...
        'splits_none',splits_none,...
        'units_none',units_none,...
        'splits_bursts',splits_bursts,...
        'units_bursts',units_bursts,...
        'splits_tonic',splits_tonic,...
        'units_tonic',units_tonic, ...
        'pVal_tonicVSburst',p);
    if isequal(splits_all, splits_bursts, splits_tonic)
        overview.Name = sprintf('%s_unitSelection_%isplits',area_names{ar},splits_all);
    else
        minSplits = min([splits_all, splits_bursts, splits_tonic]);
        overview.Name = sprintf('%s_unitSelection_%isplits',area_names{ar},minSplits);
    end
end

%% Helper functions
% Function executed by the "doneButton" in subpopulation refinement
function doneExe(~,~,f,ui_field,area_names)

for ar = 1:numel(area_names)
    switch ui_field(ar).Value
        case 2
            area_names{ar} = [area_names{ar} '-RS'];
        case 3
            area_names{ar} = [area_names{ar} '-FS'];
    end
end

% Overwrite variables
assignin('caller','area_names',area_names)

close(f)
end
