%% Behavioral Metrics
% Retrieve several information, such as:
% 	1. Head angle [deg]
% 	2. Distance to middle [mm]
%   3. Whisker angle (protraction vs. retraction) [deg]
%   4. Whisker curvature [1/mm]
%   5. Head velocity [mm/s]
%   6. Turning point of the mouse in no-lick trials

function getBehavioralMetrics(sessionDir)

% Load HispeedTrials.mat file if present, else run analysis
videoDir = fullfile(sessionDir,'videos');
if exist(fullfile(videoDir,'HispeedTrials.mat'),'file')
    load(fullfile(videoDir,'HispeedTrials.mat'), 'HispeedTrials')
else
    HispeedTrials = assignTrialsToVideos(videoDir);
end

newVariables = {'HeadAngle','Dist2Middle','WhiskerAngle','WhiskerCurv','HeadVel','TurningPoint'};

if all(contains(newVariables,HispeedTrials.Properties.VariableNames))
    return
else
    % First remove any existing variables
    for i = find(contains(newVariables,HispeedTrials.Properties.VariableNames))
        HispeedTrials = removevars(HispeedTrials,newVariables{i});
    end
    % Then add new ones
    HispeedTrials = addvars(HispeedTrials,cell(height(HispeedTrials),1),...
        cell(height(HispeedTrials),1),cell(height(HispeedTrials),1),...
        cell(height(HispeedTrials),1),cell(height(HispeedTrials),1),...
        cell(height(HispeedTrials),1),'NewVariableNames',newVariables);
end

%% Loop through sections
for i = 1:2
    fprintf('Analyzing behavioral metrics of %d. high-speed camera...\n',i)
    HispeedTrials_temp = HispeedTrials(HispeedTrials.Hispeed==i,:);
    list = strtrim(string(ls(fullfile(videoDir,['hispeed',num2str(i)])))); % List of all files in the respective hispeed directory
    dirc = dir(fullfile(videoDir,['hispeed',num2str(i)]));

    attributes = read(fullfile(videoDir,['hispeed',num2str(i)],'attributes.toml'));
    frame_dimensions(1) = attributes.video.frame_width;  % X-Coord
    frame_dimensions(2) = attributes.video.frame_height; % Y-Coord

    % Reinitiate the comparison table parameters
    compCount = ones(1,max(HispeedTrials.Go_NoGo_Neutral_settingBased));
    compTable = cell(1,max(HispeedTrials.Go_NoGo_Neutral_settingBased));
    % Load DLC data points of both nose- and whiskertrack modules
    for k = 1:size(HispeedTrials_temp,1)
        [~,videoName,~] = fileparts(HispeedTrials_temp.VideoPath{k});
        csvFile_nose = list(startsWith(list,[videoName,'DLC']) & endsWith(list,'filtered.csv') & contains(list,'Nosetrack'));
        % If there is more than one filtered video, chose the latest one
        if numel(csvFile_nose) > 1
            idx = find(ismember({dirc.name}, csvFile_nose));
            [~,latest] = max([dirc(idx).datenum]);
            csvFile_nose = dirc(idx(latest)).name;
            csvFile_nose = fullfile(videoDir,['hispeed',num2str(i)],csvFile_nose);
        else
            csvFile_nose = fullfile(videoDir,['hispeed',num2str(i)],csvFile_nose);
        end

        raw_table_nose = readtable(csvFile_nose,'Range','A2','VariableNamingRule','preserve');
        raw_table_nose = raw_table_nose(:,2:end); % Excludes the first column of indices
        headers = raw_table_nose.Properties.VariableNames;
        headers = strrep(headers,'-',''); % DLC was trained with '-' assignments, which are not supported in Matlab
        raw_table_nose.Properties.VariableNames = headers;

        csvFile_whisker = list(startsWith(list,[videoName,'DLC']) & endsWith(list,'filtered.csv') & contains(list,'Whiskertrack'));
        % If there is more than one filtered video, chose the latest one
        if numel(csvFile_whisker) > 1
            idx = find(ismember({dirc.name}, csvFile_whisker));
            [~,latest] = max([dirc(idx).datenum]);
            csvFile_whisker = dirc(idx(latest)).name;
            csvFile_whisker = fullfile(videoDir,['hispeed',num2str(i)],csvFile_whisker);
        else
            csvFile_whisker = fullfile(videoDir,['hispeed',num2str(i)],csvFile_whisker);
        end

        raw_table_whisker = readtable(csvFile_whisker,'Range','A2','VariableNamingRule','preserve');
        raw_table_whisker = raw_table_whisker(:,2:end); % Excludes the first column of indices
        headers = raw_table_whisker.Properties.VariableNames;
        headers = strrep(headers,'-',''); % DLC was trained with '-' assignments, which are not supported in Matlab
        raw_table_whisker.Properties.VariableNames = headers;

        % Convert table into tilted metrics [mm] table
        % Flip Y Coordinate
        raw_table_nose{:,2:3:end} = frame_dimensions(2) - raw_table_nose{:,2:3:end};
        raw_table_whisker{:,2:3:end} = frame_dimensions(2) - raw_table_whisker{:,2:3:end};

        % Calculate the median positions of all stationary points
        median_table = table('Size',[2, 13],'VariableTypes',...
            repmat({'double'},1,13),'VariableNames',...
            {'wing_left_corner','wing_left_base_1','wing_left_base_2',...
            'wing_left_edge_1','wing_left_edge_2','wing_right_corner',...
            'wing_right_base_1','wing_right_base_2','wing_right_edge_1',...
            'wing_right_edge_2','lickport','lp_edge_left','lp_edge_right'},'RowNames',{'X','Y'});

        certainty = 0.7; % to only retrieve high accuracy data points

        median_table.wing_left_corner(:) = [median(raw_table_nose.wing_left_corner(raw_table_nose.wing_left_corner_2>certainty)),...
            median(raw_table_nose.wing_left_corner_1(raw_table_nose.wing_left_corner_2>certainty))];
        median_table.wing_left_base_1(:) = [median(raw_table_nose.wing_left_base_1(raw_table_nose.wing_left_base_1_2>certainty)),...
            median(raw_table_nose.wing_left_base_1_1(raw_table_nose.wing_left_base_1_2>certainty))];
        median_table.wing_left_base_2(:) = [median(raw_table_nose.wing_left_base_2(raw_table_nose.wing_left_base_2_2>certainty)),...
            median(raw_table_nose.wing_left_base_2_1(raw_table_nose.wing_left_base_2_2>certainty))];
        median_table.wing_left_edge_1(:) = [median(raw_table_nose.wing_left_edge_1(raw_table_nose.wing_left_edge_1_2>certainty)),...
            median(raw_table_nose.wing_left_edge_1_1(raw_table_nose.wing_left_edge_1_2>certainty))];
        median_table.wing_left_edge_2(:) = [median(raw_table_nose.wing_left_edge_2(raw_table_nose.wing_left_edge_2_2>certainty)),...
            median(raw_table_nose.wing_left_edge_2_1(raw_table_nose.wing_left_edge_2_2>certainty))];

        median_table.wing_right_corner(:) = [median(raw_table_nose.wing_right_corner(raw_table_nose.wing_right_corner_2>certainty)),...
            median(raw_table_nose.wing_right_corner_1(raw_table_nose.wing_right_corner_2>certainty))];
        median_table.wing_right_base_1(:) = [median(raw_table_nose.wing_right_base_1(raw_table_nose.wing_right_base_1_2>certainty)),...
            median(raw_table_nose.wing_right_base_1_1(raw_table_nose.wing_right_base_1_2>certainty))];
        median_table.wing_right_base_2(:) = [median(raw_table_nose.wing_right_base_2(raw_table_nose.wing_right_base_2_2>certainty)),...
            median(raw_table_nose.wing_right_base_2_1(raw_table_nose.wing_right_base_2_2>certainty))];
        median_table.wing_right_edge_1(:) = [median(raw_table_nose.wing_right_edge_1(raw_table_nose.wing_right_edge_1_2>certainty)),...
            median(raw_table_nose.wing_right_edge_1_1(raw_table_nose.wing_right_edge_1_2>certainty))];
        median_table.wing_right_edge_2(:) = [median(raw_table_nose.wing_right_edge_2(raw_table_nose.wing_right_edge_2_2>certainty)),...
            median(raw_table_nose.wing_right_edge_2_1(raw_table_nose.wing_right_edge_2_2>certainty))];

        median_table.lickport(:) = [median(raw_table_nose.lickport(raw_table_nose.lickport_2>certainty)),...
            median(raw_table_nose.lickport_1(raw_table_nose.lickport_2>certainty))];
        median_table.lp_edge_left(:) = [median(raw_table_nose.lp_edge_left(raw_table_nose.lp_edge_left_2>certainty)),...
            median(raw_table_nose.lp_edge_left_1(raw_table_nose.lp_edge_left_2>certainty))];
        median_table.lp_edge_right(:) = [median(raw_table_nose.lp_edge_right(raw_table_nose.lp_edge_right_2>certainty)),...
            median(raw_table_nose.lp_edge_right_1(raw_table_nose.lp_edge_right_2>certainty))];
        
        % Make an average estimation of the fixed points for the respective
        % aperture setting
        apertureSet = HispeedTrials_temp.Go_NoGo_Neutral_settingBased(k);
        if compCount(apertureSet)==1 
            compTable{apertureSet} = median_table;
            compCount(apertureSet) = 2;
        else
            % Calculate weighted mean for each element
            for val = 1:numel(median_table)
                [row, col] = ind2sub(size(median_table), val);
                if isnan(median_table{row, col}) && isnan(compTable{apertureSet}{row, col})
                    % Both elements are NaN, result is NaN
                    compTable{apertureSet}{row, col} = NaN;
                elseif isnan(compTable{apertureSet}{row, col})
                    % Only compTable element is NaN, take median_table element
                    compTable{apertureSet}{row, col} = median_table{row, col};
                elseif ~isnan(median_table{row, col}) && ~isnan(compTable{apertureSet}{row, col})
                    % Both elements are not NaN, calculate weighted mean
                    compTable{apertureSet}{row, col} = (compCount(apertureSet)-1)/compCount(apertureSet) * compTable{apertureSet}{row, col} + (1/compCount(apertureSet)) * median_table{row, col};
                end
            end
            compCount(apertureSet) = compCount(apertureSet) + 1;
        end

        % If there are NaN values in the median table, substitute them with
        % previously estimated values.
        if any(isnan(table2array(median_table)),'all')
            for nanIdx = find(isnan(table2array(median_table)))'
                [row, col] = ind2sub(size(median_table), nanIdx);
                median_table{row, col} = compTable{apertureSet}{row, col};
            end
        end

        % Plot the linear fit of the apertures' base points and find the
        % bisecting angle of their intersection, in order to define the "straight"
        % axis.

        % NaN values have to be excluded, otherwise the polyfit will
        % only return NaNs
        flag = false;
        xvals = [median_table.wing_left_base_2(1),median_table.wing_left_base_1(1),median_table.wing_left_corner(1)];
        xvals = xvals(~isnan(xvals));
        yvals = [median_table.wing_left_base_2(2),median_table.wing_left_base_1(2),median_table.wing_left_corner(2)];
        yvals = yvals(~isnan(yvals));
        if isscalar(yvals)
            flag = true;
        else
            p_left = polyfit(xvals,yvals,1);
        end

        xvals = [median_table.wing_right_base_2(1),median_table.wing_right_base_1(1),median_table.wing_right_corner(1)];
        xvals = xvals(~isnan(xvals));
        yvals = [median_table.wing_right_base_2(2),median_table.wing_right_base_1(2),median_table.wing_right_corner(2)];
        yvals = yvals(~isnan(yvals));
        if isscalar(yvals)
            flag = true;
        else
            p_right = polyfit(xvals,yvals,1);
        end

        if flag
            xvals = [median_table.wing_left_base_2(1),median_table.wing_left_base_1(1),median_table.wing_left_corner(1),...
                median_table.wing_right_base_2(1),median_table.wing_right_base_1(1),median_table.wing_right_corner(1)];
            xvals = xvals(~isnan(xvals));
            yvals = [median_table.wing_left_base_2(2),median_table.wing_left_base_1(2),median_table.wing_left_corner(2),...
                median_table.wing_right_base_2(2),median_table.wing_right_base_1(2),median_table.wing_right_corner(2)];
            yvals = yvals(~isnan(yvals));
            
            p_fit = polyfit(xvals,yvals,1);
            angle = -atan(p_fit(1));
        else
            theta_left = atan(p_left(1));
            theta_right = atan(p_right(1));
            angle = (theta_left - theta_right)/2;
        end

        % Turn the table, so that the bisecting angle becomes a straight line

        % Rotation (anti-clockwise!) along a given rotation point(x1|y1),
        % in this case the middle point between wing corners.
        x_transformation = @(x,y,x1,y1,theta) cos(theta)*(x - x1)-sin(theta)*(y - y1);
        y_transformation = @(x,y,x1,y1,theta) sin(theta)*(x - x1)+cos(theta)*(y - y1);

        x1 = median_table.wing_left_corner(1)+0.5*(median_table.wing_right_corner(1)-median_table.wing_left_corner(1));
        y1 = median_table.wing_left_corner(2)+0.5*(median_table.wing_right_corner(2)-median_table.wing_left_corner(2));

        metric_table_nose = raw_table_nose;
        metric_table_whisker = raw_table_whisker;

        metric_table_nose{:,1:3:end} = x_transformation(raw_table_nose{:,1:3:end},raw_table_nose{:,2:3:end},...
            x1,y1,angle); % X-coordinates
        metric_table_nose{:,2:3:end} = y_transformation(raw_table_nose{:,1:3:end},raw_table_nose{:,2:3:end},...
            x1,y1,angle); % Y-coordinates

        metric_table_whisker{:,1:3:end} = x_transformation(raw_table_whisker{:,1:3:end},raw_table_whisker{:,2:3:end},...
            x1,y1,angle); % X-coordinates
        metric_table_whisker{:,2:3:end} = y_transformation(raw_table_whisker{:,1:3:end},raw_table_whisker{:,2:3:end},...
            x1,y1,angle); % Y-coordinates

        median_table{1,:} = x_transformation(median_table{1,:},median_table{2,:},...
            x1,y1,angle);
        median_table{2,:} = y_transformation(median_table{1,:},median_table{2,:},...
            x1,y1,angle);

        % Calculate the metric from the known distance of the lick-port

        % Conversion of pixel values into metric millimeters
        % The distance between the left and the right lickport edge is 30mm

        conversion_fac = 30/(sqrt((median_table.lp_edge_left(1)-median_table.lp_edge_right(1))^2+(median_table.lp_edge_left(2)-median_table.lp_edge_right(2))^2));

        metric_table_nose{:,1:3:end} = conversion_fac*metric_table_nose{:,1:3:end}; % X-coordinates
        metric_table_nose{:,2:3:end} = conversion_fac*metric_table_nose{:,2:3:end}; % Y-coordinates

        metric_table_whisker{:,1:3:end} = conversion_fac*metric_table_whisker{:,1:3:end}; % X-coordinates
        metric_table_whisker{:,2:3:end} = conversion_fac*metric_table_whisker{:,2:3:end}; % Y-coordinates

        % Input metric table to functions

        % 1. Calculate HeadAngle with regards to the vertical --> Nosetrack
        HeadAngle = getHeadAngle(metric_table_nose, 0.8);

        % 2. Calculate Dist2Middle --> Nosetrack
        % Since the metric tables are already rotated with regards to the
        % middle point between the wings, the distance results from the x
        % values.
        % Note that midpoint between the wings doesn't necessarily have to
        % be in line with the lick spout.
        Dist2Middle = nan(height(metric_table_nose),1);
        Dist2Middle(metric_table_nose.nosetip_2 >= 0.8) = metric_table_nose.nosetip(metric_table_nose.nosetip_2 >= 0.8);        
        Dist2Middle = single(Dist2Middle);
        
        % 3. Calculate WhiskerAngle --> Whiskertrack
        % The output will be a matrix (single) n x 4 (n = number of timestamps)
        % The columns will be: whiskerLeft1, whiskerLeft2, whiskerRight1, whiskerRight2
        % No need to transform the raw_table, as we are not interested in spatial features.

        % 180 deg means that the whiskers are maximally retracted
        % 0 deg means that the whiskers are maximally protracted
        WhiskerAngle = getBaseAngle(raw_table_whisker, 0.7);
        % One could lowpass the signals, in order to get an idea for the 
        % number of whisking cycles, performed before and after
        % whisker-touch.

        % 4. Calculate WhiskerCurv --> Whiskertrack
        % The output will be a Table with 4 variables
        % (whiskerLeft1, whiskerLeft2, whiskerRight1, whiskerRight2)
        % and n x 4 rows each (single)
        % see whiskerCurvature.m (not used in other scripts, rename "getWhiskerCurvature.m")
        WhiskerCurv = getWhiskerCurvature(metric_table_whisker, 0.7);

        % 5. Calculate HeadVel --> Nosetrack
        % The velocity is solely derived by the nose coordinates
        % This includes also angular momentum of head rotations, even when
        % the head's center is not moving. However, for estimating the
        % effect on potential sampling speed, this seemed more adequate.
        nose_grad = nan(height(metric_table_nose),1);
        grad_temp = [diff(metric_table_nose.nosetip(metric_table_nose.nosetip_2>=0.8)),diff(metric_table_nose.nosetip_1(metric_table_nose.nosetip_2>=0.8))];
        grad_temp = num2cell(grad_temp, 2);
        grad_temp = cellfun(@norm, grad_temp);
        % Since the diff function dismisses one element, you have to add a
        % NaN value up front.
        grad_temp = [NaN; grad_temp]; %#ok<AGROW> 
        nose_grad(metric_table_nose.nosetip_2>=0.8) = grad_temp;

        time_grad = nan(height(metric_table_nose),1);
        grad_temp = diff(HispeedTrials_temp.Timestamps{k,1}(metric_table_nose.nosetip_2>=0.8));
        % Since the diff function dismisses one element, you have to add a
        % NaN value up front.
        grad_temp = [NaN; grad_temp]; %#ok<AGROW> 
        time_grad(metric_table_nose.nosetip_2>=0.8) = grad_temp;
        HeadVel = nose_grad./time_grad*1000; % Velocity in mm/sec
        HeadVel = single(HeadVel);
        % Add new values to HispeedTrials table
        idx = find(HispeedTrials.Hispeed==i,k,'first');
        HispeedTrials.HeadAngle{idx(end)} = HeadAngle;
        HispeedTrials.Dist2Middle{idx(end)} = Dist2Middle;
        HispeedTrials.WhiskerAngle{idx(end)} = WhiskerAngle;
        HispeedTrials.WhiskerCurv{idx(end)} = WhiskerCurv;
        HispeedTrials.HeadVel{idx(end)} = HeadVel;
        
        % 6. For no-lick trials extract the point where the mouse reaches
        % it turning point (i.e., max y value).
        if HispeedTrials_temp.Lick(k)==0
            saveFrames = find(metric_table_nose.nosetip_2>=0.8);
            saveXvals = metric_table_nose.nosetip(saveFrames);
            saveYvals = metric_table_nose.nosetip_1(saveFrames);

            % Check with diff if the preceeding and follwoing points are
            % continuous, and don't occur towards the end,
            % to exclude labeling errors as false max values.
            % Try this 10 times, then consider the section as too noisy.
            count = 1;
            while count <=10 && ~isempty(saveYvals)
                [maxY, maxIdx] = maxk(saveYvals,count);
                maxX = saveXvals(maxIdx(end));
                if maxIdx(end) >= numel(saveYvals)-20 || maxIdx(end) <= 10
                    count = count + 1;
                    continue
                elseif ~any(diff(saveYvals(maxIdx(end)-5:maxIdx(end)+5))>2) && ~isnan(maxY(end))
                    HispeedTrials.TurningPoint{idx(end)} = [saveFrames(maxIdx(end)),maxX,maxY(end)];
                    break
                end
            count = count + 1;
            end
        end
    end
end

