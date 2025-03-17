%% CNN decoder for calcium imaging data


%% Get the session indexes for the required sessions

Animals=fieldnames(Cohort);
i=1;
Sessionstosn=[];
for a=3
    Sessions=fieldnames(Cohort.(Animals{a}));
    for s=1:length(Sessions)
        SessionNumber=fieldnames(Cohort.(Animals{a}).(Sessions{s}));
        for sn=1:length(SessionNumber)
            Sessiontosn(i,1)=sn;
            i=i+1;
        end
    end
end

% so the sessions would be 22-25. last 4, i.r. 18-21

%% Match their cellular identities, and get their before after traces.

cellmatching=CellMatchingData.Mouse59.cell_to_index_map(:,22:25);
cellmatching(all(cellmatching == 0, 2), :) = []; %Remove indices for which no cells in these sessions
emptytrace=zeros(1,41);


%% Creating Dataset

SessionNumber=fieldnames(Cohort.Mouse59.s50pctReward);
shorterTable = cellmatching(all(cellmatching(:,:) ~= 0, 2), :); %only cells found in all sessions
i=1;
for sn=18:21 
    this=Cohort.Mouse59.s50pctReward.(SessionNumber{sn}).GvsNG.CellTraceTouchG;

    for wt=1:size(this,3)
        for c=1:17
            dataA(c,:,i)=this(shorterTable(c,sn-17),:,wt);
        end
        i=i+1;

    end
end

i=1;
for sn=18:21
    this=Cohort.Mouse59.s50pctReward.(SessionNumber{sn}).GvsNG.CellTraceTouchNG;

    for wt=1:size(this,3)
        for c=1:17
            dataB(c,:,i)=this(shorterTable(c,sn-17),:,wt);
        end
        i=i+1;

    end
end


%% CNN

% Number of images in each class
numA = size(dataA, 3);
numB = size(dataB, 3);

% Dimensions (assuming both classes share the same image dimensions)
height = size(dataA, 1);
width = size(dataA, 2);

% Preallocate a 4-D array for image data (for grayscale images, channel=1)
X = zeros(height, width, 1, numA + numB);

% Fill in the images: first class A, then class B
X(:,:,1,1:numA) = dataA;
X(:,:,1,numA+1:numA+numB) = dataB;

% Create categorical labels: 'A' for the first numA images, 'B' for the rest
Y = categorical([repmat("A", numA, 1); repmat("B", numB, 1)]);

layers = [
    imageInputLayer([height width 1])
    
    convolution2dLayer(3, 8, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2, 'Stride', 2)
    
    convolution2dLayer(3, 16, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2, 'Stride', 2)
    
    fullyConnectedLayer(2)    % Two classes: A and B
    softmaxLayer
    classificationLayer
];

options = trainingOptions('sgdm', ...
    'MaxEpochs', 200, ...           % Adjust epochs as needed
    'InitialLearnRate', 0.01, ...    % Tune learning rate for your data
    'Verbose', false, ...
    'Plots', 'training-progress');

net = trainNetwork(X, Y, layers, options);

YPred = classify(net, X);
accuracy = sum(YPred == Y) / numel(Y);
fprintf('Training accuracy: %.2f%%\n', accuracy * 100);

%% ROC curve
% Get predicted scores from the trained network
% 'scores' is a numTest-by-2 matrix containing the scores for each class.
% XTest=X(:,:,:,1:3:end);
% YTest=Y(1:3:end);
XTest=X;
YTest=Y;
scores = predict(net, XTest);

% Specify the positive class (adjust as needed)
posClass = "A";

% Identify the index corresponding to the positive class
% The network's classification layer stores the class names.
classes = net.Layers(end).Classes;
posIdx = find(classes == posClass);

% Compute ROC curve using perfcurve:
% perfcurve requires the true labels, scores for the positive class, and the positive class label.
[Xroc, Yroc, T, AUC] = perfcurve(YTest, scores(:, posIdx), posClass);

% Plot the ROC curve
figure;
hold on
plot(Xroc, Yroc, 'LineWidth', 2);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(['ROC Curve for Class ', char(posClass), ' (AUC = ', num2str(AUC, '%.2f'), ')']);
grid on;
scores = predict(net, XTest);

% Specify the positive class (adjust as needed)
posClass = "B";

% Identify the index corresponding to the positive class
% The network's classification layer stores the class names.
classes = net.Layers(end).Classes;
posIdx = find(classes == posClass);

% Compute ROC curve using perfcurve:
% perfcurve requires the true labels, scores for the positive class, and the positive class label.
[Xroc, Yroc, T, AUC] = perfcurve(YTest, scores(:, posIdx), posClass);



plot(Xroc, Yroc, 'LineWidth', 2);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(['ROC Curve for Class ', char(posClass), ' (AUC = ', num2str(AUC, '%.2f'), ')']);
grid on;

x = linspace(0, 1, 100);

% Compute y as equal to x
y = x;

% Plot the line
% figure;
plot(x, y, 'LineWidth', 2);
xlabel('x');
ylabel('y');
title('Plot of y = x over [0, 1]');
grid on;