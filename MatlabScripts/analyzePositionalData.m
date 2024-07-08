%% Display overview video with underlay velocity plot 
% Reference the file
close all; clearvars; clc
% Setup VideoReader object with overview video
video_path = 'Z:\Filippo\Animals\Cohort12_33-38\#38\2021-11-16\P3.2_50pctReward_session16\videos\tis-camera\fd5a98-videoDLC_effnet_b0_BodytrackEIBNov10shuffle1_350000_labeled.mp4';
curationPath = fullfile(fileparts(fileparts(fileparts(video_path))),'intan-signals\automatedCuration');

% Read the video
v = VideoReader(video_path);
nFrames = v.NumFrames; % Number of frames
frameRate = v.FrameRate; % Frame rate

if ~exist(fullfile(curationPath,'FrameInfo.mat'),'file')
    answer = questdlg('Overview video metrics haven''t been analyzed for this file. Analyze now?', ...
        'Analyze behavioral metrics', ...
        'Yes','No','Yes');
    if isequal(answer,'Yes')
        LocomotionModulation(curationPath)
    else
        return
    end
end
load(fullfile(curationPath,'FrameInfo.mat'),'FrameInfo')

cohortNum = regexp(video_path,'Cohort(\d+)','tokens','once');
animalNum = regexp(video_path,'#(\d+)','match');
stageNum = regexp(video_path,'P3\.(\d+\.\d+|\d+)','tokens','once');
sessionNum = regexp(video_path,'ses\D*(\d+)','tokens','once');

positionOnMaze = cell2mat(FrameInfo.position);
Xposition = positionOnMaze(:,1);

%% Create moving mean over positional data
% From -300 to 300 mm
% Step size 10 mm
% Sort array by normalized x-vals
entireFrame = [-300,300]; % Expansion in mm
windSize = 25; % Size to average over in mm
windStep = 5; % Step for next window (smaller than windSize will result in a moving mean)

movMeanVelocity = NaN(1,range(entireFrame)/windStep+1);
movSTDVelocity = NaN(1,range(entireFrame)/windStep+1);
percentiles = NaN(2,range(entireFrame)/windStep+1);
xvals = entireFrame(1):windStep:entireFrame(2);
count = 1;
for i = xvals
    idx = Xposition>=i-windSize/2 & Xposition<=i+windSize/2;
    if any(idx)
        movMeanVelocity(count) = mean(FrameInfo.velocity(idx),'omitnan');
        movSTDVelocity(count) = std(FrameInfo.velocity(idx),'omitnan');
        percentiles(:,count) = prctile(FrameInfo.velocity(idx), [10, 90])';
    else
       movMeanVelocity(count) = NaN;
       movMeanVelocity(count) = NaN;
    end
    count = count + 1;
end

figure
hold on
curve1 = movMeanVelocity + movSTDVelocity;
curve2 = movMeanVelocity - movSTDVelocity;
plot(xvals, curve1,'-','Color','#cccccc');
plot(xvals, curve2,'-','Color','#cccccc');
x = xvals(~isnan(curve1));
curve1 = curve1(~isnan(curve1));
curve2 = curve2(~isnan(curve2));
fill([x fliplr(x)], [curve1 fliplr(curve2)],[0 0 .85],...
    'FaceColor','#cccccc','EdgeColor','none','FaceAlpha',0.2);
plot(xvals,movMeanVelocity,'Color','#000000','LineWidth',1.5);

title('Mean velocity across maze')
xlabel('Position on maze [mm]')
ylabel('Velocity [mm/sec]')
hold off

%% Create heat map of positional data

Xedges = (-300:10:300); % X dimensions from -300 to 300 mm
Yedges = (-30:1:30); % Y dimensions from -30 to 30 mm
histogram2D = histcounts2(positionOnMaze(:,1),positionOnMaze(:,2),Xedges,Yedges);

% Define the structuring element for dilation
se = strel('disk', 1);  % Adjust the disk size as needed

% Smooth the matrix over avg_bins x avg_bins
avg_bins = 5;
avg_matrix = ones(avg_bins,avg_bins)/avg_bins^2;
histogram2D = conv2(histogram2D,avg_matrix,'same');

% Turning the histogram values (number of frames) into seconds, spent in
% that square
histogram2D = histogram2D./frameRate;

% Calculate the 90th percentile value and replace values for better
% visualisation
p90 = prctile(histogram2D(:), 90);
histogram2D(histogram2D > p90) = p90;

% Replace 0 values in order to better visualize it
histogram2D(histogram2D == 0) = NaN;
cmap = flip(magma);
cmap(1,:) = [1, 1, 1];  % Set the first color to white

% Plot the dilated image as a heat map
figure
%     s = scatter(x,y,'o','MarkerEdgeColor',area_colors{area_idx(i)});
imvals_X = (-300+10/2:10:300-10/2);
imvals_Y = (-30+1/2:1:30-1/2);
im = imagesc(imvals_X, imvals_Y, histogram2D');
xlim([-310 310]);
ylim([-100 100]);
box off
colormap(cmap);
c = colorbar;
c.Label.String = 'Seconds spent per square';
c.Ticks = [c.Ticks, p90];
c.TickLabels{end} = sprintf('\\geq %.3f',p90);

title('Heat map of positional data')
xlabel('X position [mm]')
ylabel('Y position [mm]')

% Plot the dilated image as a heat map
figure
plot(positionOnMaze(:,1),positionOnMaze(:,2),'Color','#1a1a1a');
xlim([-310 310]);
ylim([-100 100]);
box off

title('Positional mouse traces')
xlabel('X position [mm]')
ylabel('Y position [mm]')
