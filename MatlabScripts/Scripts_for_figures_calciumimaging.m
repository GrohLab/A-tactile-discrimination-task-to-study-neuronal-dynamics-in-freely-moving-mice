%% Scripts for Figure 5 calcium imaging

%% Get MIP for the sample video "Figure 5D"

% Load the video file
videoFile = "Z:\Data\Avi_Data\Salience\ExperimentalCohort\59\2023-11-09\P3.2_50pctReward_session16\videos\miniscope\mscope.mkv"; % Replace with your video file path

videoObj = VideoReader(videoFile);

% Get video properties
numFrames = videoObj.NumFrames;
vidHeight = videoObj.Height;
vidWidth = videoObj.Width;

% Initialize an array to store the maximum intensity projection as uint8
MIP = zeros(vidHeight, vidWidth, 'uint8');

% Loop through each frame of the video
for k = 1:5000
    % Read the current frame
    frame = read(videoObj, k);
    
    % If the frame is colored, convert it to grayscale
    if size(frame, 3) == 3
        frame = rgb2gray(frame);
    end
    
    % Update the MIP
    MIP = max(MIP, frame);
end

% Display the Maximum Intensity Projection
imshow(MIP, []);
title('Maximum Intensity Projection');


%% plot spatial footprints "Figure 5F"

figure
imagesc(sum(AnimalData.Mouse59.s50pctReward.session16.CalciumData.SpatialFootprints,3))


%% plot example whisker tuned cells "Figure 5G"

% The example whisker tuned cells are 14,22,28,29

x = AnimalData.Mouse59.s50pctReward.session16;
d = x.CalciumData.TemporalFootprints';
lineThickness = 0.5;

WhiskerTouch=[x.WhiskerTouch1; x.WhiskerTouch2];

WhiskerTouchTunedCells = [14, 22, 28, 29];

figure
for i = 1:4
    plotWithWhiskerTouch(i, d(WhiskerTouchTunedCells(i),:), WhiskerTouch, lineThickness);
end



%% Align traces over trials "Figure 5H"

% This is only being done for Cell 29

for i = 1:length(WhiskerTouch)
    if WhiskerTouch(i)==1
        WhiskerTouch(i)=31;
    elseif WhiskerTouch(i)+31>size(d,2)
        WhiskerTouch(i)=WhiskerTouch(i)-30;
    end
    TouchCellsFrame(i,:,:)=d(:,WhiskerTouch(i,1)-20:WhiskerTouch(i,1)+40); %Extracting data around a touch
end

figure %Top part
imagesc(squeeze(TouchCellsFrame(:,29,:)))

figure %Bottom part
plot(squeeze(sum(TouchCellsFrame(:,29,:),1)))



%% Functions
function plotWithWhiskerTouch(subplotIndex,data, WhiskerTouch, lineThickness)
    subplot(4,1,subplotIndex);
    area(data);
    hold on;
    for i = 1:length(WhiskerTouch)
        line([WhiskerTouch(i), WhiskerTouch(i)], ylim, 'Color', 'red', 'LineWidth', lineThickness);
    end
    hold off;
    xlim([10000,15000]);
end