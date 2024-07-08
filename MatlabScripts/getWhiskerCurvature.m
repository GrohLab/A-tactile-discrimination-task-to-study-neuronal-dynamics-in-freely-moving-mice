function WhiskerCurv = getWhiskerCurvature(coordinate_table, certainty)
% This function assesses the curvature of the whiskers at any
% given timepoint.
% A proper table with all the coordinates from the DLC csv file is
% necessary (see "Z:\Filippo\Scripts\MatlabScripts\getBehavioralMetrics.m").
% The certainty variable defines the cutoff, after which certain values
% with low certainty are dismissed.

% The curvature is always calculated for three adjacent whisker markers.
% This results in max. four curvature values for each whisker.

% Later the curvature will be smoothed for robustness.

% The output will be a Table with 4 variables
% (whiskerLeft1, whiskerLeft2, whiskerRight1, whiskerRight2)
% and n x 4 rows each (single), for each marker triplet:
% column 1: whiskers 1-3
% column 2: whiskers 2-4
% column 3: whiskers 3-5
% column 4: whiskers 4-6

labels = {'whiskerLeft1', 'whiskerLeft2', 'whiskerRight1', 'whiskerRight2'};
WhiskerCurv = table('Size',[1,4],'VariableTypes',repmat({'cell'},1,4),'VariableNames',labels);
for i=1:4, WhiskerCurv{1,i}{:}=single(nan(height(coordinate_table),4));end

% Extracting all the frames, where all the respective whisker marker
% triplets are tracked reliably.

% First whisker left
safe_frames{1} = find(coordinate_table.whisker1_left1_2 > certainty & coordinate_table.whisker1_left2_2 > certainty & ...
    coordinate_table.whisker1_left3_2 > certainty);
safe_frames{2} = find(coordinate_table.whisker1_left2_2 > certainty & coordinate_table.whisker1_left3_2 > certainty & ...
    coordinate_table.whisker1_left4_2 > certainty);
safe_frames{3} = find(coordinate_table.whisker1_left3_2 > certainty & coordinate_table.whisker1_left4_2 > certainty & ...
    coordinate_table.whisker1_left5_2 > certainty);
safe_frames{4} = find(coordinate_table.whisker1_left4_2 > certainty & coordinate_table.whisker1_left5_2 > certainty & ...
    coordinate_table.whisker1_left6_2 > certainty);

for i = 1:4
    for frame = safe_frames{i}'
        % Calculate the whisker curvature if three labels are reliably detected
        switch i
            case 1
                x_whisk = [coordinate_table.whisker1_left1(frame), coordinate_table.whisker1_left2(frame), ...
                    coordinate_table.whisker1_left3(frame)];
                y_whisk = [coordinate_table.whisker1_left1_1(frame), coordinate_table.whisker1_left2_1(frame), ...
                    coordinate_table.whisker1_left3_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 2
                x_whisk = [coordinate_table.whisker1_left2(frame), coordinate_table.whisker1_left3(frame), ...
                    coordinate_table.whisker1_left4(frame)];
                y_whisk = [coordinate_table.whisker1_left2_1(frame), coordinate_table.whisker1_left3_1(frame), ...
                    coordinate_table.whisker1_left4_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 3
                x_whisk = [coordinate_table.whisker1_left3(frame), coordinate_table.whisker1_left4(frame), ...
                    coordinate_table.whisker1_left5(frame)];
                y_whisk = [coordinate_table.whisker1_left3_1(frame), coordinate_table.whisker1_left4_1(frame), ...
                    coordinate_table.whisker1_left5_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 4
                x_whisk = [coordinate_table.whisker1_left4(frame), coordinate_table.whisker1_left5(frame), ...
                    coordinate_table.whisker1_left6(frame)];
                y_whisk = [coordinate_table.whisker1_left4_1(frame), coordinate_table.whisker1_left5_1(frame), ...
                    coordinate_table.whisker1_left6_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
        end

        WhiskerCurv{1,1}{:}(frame,i) = curv;

    end
    WhiskerCurv{1,1}{:}(i,:) = movmean(WhiskerCurv{1,1}{:}(i,:),5,'omitnan');
end

% Second whisker left
safe_frames{1} = find(coordinate_table.whisker2_left1_2 > certainty & coordinate_table.whisker2_left2_2 > certainty & ...
    coordinate_table.whisker2_left3_2 > certainty);
safe_frames{2} = find(coordinate_table.whisker2_left2_2 > certainty & coordinate_table.whisker2_left3_2 > certainty & ...
    coordinate_table.whisker2_left4_2 > certainty);
safe_frames{3} = find(coordinate_table.whisker2_left3_2 > certainty & coordinate_table.whisker2_left4_2 > certainty & ...
    coordinate_table.whisker2_left5_2 > certainty);
safe_frames{4} = find(coordinate_table.whisker2_left4_2 > certainty & coordinate_table.whisker2_left5_2 > certainty & ...
    coordinate_table.whisker2_left6_2 > certainty);

for i = 1:4
    for frame = safe_frames{i}'
        % Calculate the whisker curvature if three labels are reliably detected
        switch i
            case 1
                x_whisk = [coordinate_table.whisker2_left1(frame), coordinate_table.whisker2_left2(frame), ...
                    coordinate_table.whisker2_left3(frame)];
                y_whisk = [coordinate_table.whisker2_left1_1(frame), coordinate_table.whisker2_left2_1(frame), ...
                    coordinate_table.whisker2_left3_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 2
                x_whisk = [coordinate_table.whisker2_left2(frame), coordinate_table.whisker2_left3(frame), ...
                    coordinate_table.whisker2_left4(frame)];
                y_whisk = [coordinate_table.whisker2_left2_1(frame), coordinate_table.whisker2_left3_1(frame), ...
                    coordinate_table.whisker2_left4_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 3
                x_whisk = [coordinate_table.whisker2_left3(frame), coordinate_table.whisker2_left4(frame), ...
                    coordinate_table.whisker2_left5(frame)];
                y_whisk = [coordinate_table.whisker2_left3_1(frame), coordinate_table.whisker2_left4_1(frame), ...
                    coordinate_table.whisker2_left5_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 4
                x_whisk = [coordinate_table.whisker2_left4(frame), coordinate_table.whisker2_left5(frame), ...
                    coordinate_table.whisker2_left6(frame)];
                y_whisk = [coordinate_table.whisker2_left4_1(frame), coordinate_table.whisker2_left5_1(frame), ...
                    coordinate_table.whisker2_left6_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
        end

        WhiskerCurv{1,2}{:}(frame,i) = curv;

    end
    WhiskerCurv{1,2}{:}(i,:) = movmean(WhiskerCurv{1,2}{:}(i,:),5,'omitnan');
end

% First whisker right
safe_frames{1} = find(coordinate_table.whisker1_right1_2 > certainty & coordinate_table.whisker1_right2_2 > certainty & ...
    coordinate_table.whisker1_right3_2 > certainty);
safe_frames{2} = find(coordinate_table.whisker1_right2_2 > certainty & coordinate_table.whisker1_right3_2 > certainty & ...
    coordinate_table.whisker1_right4_2 > certainty);
safe_frames{3} = find(coordinate_table.whisker1_right3_2 > certainty & coordinate_table.whisker1_right4_2 > certainty & ...
    coordinate_table.whisker1_right5_2 > certainty);
safe_frames{4} = find(coordinate_table.whisker1_right4_2 > certainty & coordinate_table.whisker1_right5_2 > certainty & ...
    coordinate_table.whisker1_right6_2 > certainty);

for i = 1:4
    for frame = safe_frames{i}'
        % Calculate the whisker curvature if three labels are reliably detected
        switch i
            case 1
                x_whisk = [coordinate_table.whisker1_right1(frame), coordinate_table.whisker1_right2(frame), ...
                    coordinate_table.whisker1_right3(frame)];
                y_whisk = [coordinate_table.whisker1_right1_1(frame), coordinate_table.whisker1_right2_1(frame), ...
                    coordinate_table.whisker1_right3_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 2
                x_whisk = [coordinate_table.whisker1_right2(frame), coordinate_table.whisker1_right3(frame), ...
                    coordinate_table.whisker1_right4(frame)];
                y_whisk = [coordinate_table.whisker1_right2_1(frame), coordinate_table.whisker1_right3_1(frame), ...
                    coordinate_table.whisker1_right4_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 3
                x_whisk = [coordinate_table.whisker1_right3(frame), coordinate_table.whisker1_right4(frame), ...
                    coordinate_table.whisker1_right5(frame)];
                y_whisk = [coordinate_table.whisker1_right3_1(frame), coordinate_table.whisker1_right4_1(frame), ...
                    coordinate_table.whisker1_right5_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 4
                x_whisk = [coordinate_table.whisker1_right4(frame), coordinate_table.whisker1_right5(frame), ...
                    coordinate_table.whisker1_right6(frame)];
                y_whisk = [coordinate_table.whisker1_right4_1(frame), coordinate_table.whisker1_right5_1(frame), ...
                    coordinate_table.whisker1_right6_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
        end

        WhiskerCurv{1,3}{:}(frame,i) = curv;

    end
    WhiskerCurv{1,3}{:}(i,:) = movmean(WhiskerCurv{1,3}{:}(i,:),5,'omitnan');
end

% Second whisker right
safe_frames{1} = find(coordinate_table.whisker2_right1_2 > certainty & coordinate_table.whisker2_right2_2 > certainty & ...
    coordinate_table.whisker2_right3_2 > certainty);
safe_frames{2} = find(coordinate_table.whisker2_right2_2 > certainty & coordinate_table.whisker2_right3_2 > certainty & ...
    coordinate_table.whisker2_right4_2 > certainty);
safe_frames{3} = find(coordinate_table.whisker2_right3_2 > certainty & coordinate_table.whisker2_right4_2 > certainty & ...
    coordinate_table.whisker2_right5_2 > certainty);
safe_frames{4} = find(coordinate_table.whisker2_right4_2 > certainty & coordinate_table.whisker2_right5_2 > certainty & ...
    coordinate_table.whisker2_right6_2 > certainty);

for i = 1:4
    for frame = safe_frames{i}'
        % Calculate the whisker curvature if three labels are reliably detected
        switch i
            case 1
                x_whisk = [coordinate_table.whisker2_right1(frame), coordinate_table.whisker2_right2(frame), ...
                    coordinate_table.whisker2_right3(frame)];
                y_whisk = [coordinate_table.whisker2_right1_1(frame), coordinate_table.whisker2_right2_1(frame), ...
                    coordinate_table.whisker2_right3_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 2
                x_whisk = [coordinate_table.whisker2_right2(frame), coordinate_table.whisker2_right3(frame), ...
                    coordinate_table.whisker2_right4(frame)];
                y_whisk = [coordinate_table.whisker2_right2_1(frame), coordinate_table.whisker2_right3_1(frame), ...
                    coordinate_table.whisker2_right4_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 3
                x_whisk = [coordinate_table.whisker2_right3(frame), coordinate_table.whisker2_right4(frame), ...
                    coordinate_table.whisker2_right5(frame)];
                y_whisk = [coordinate_table.whisker2_right3_1(frame), coordinate_table.whisker2_right4_1(frame), ...
                    coordinate_table.whisker2_right5_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
            case 4
                x_whisk = [coordinate_table.whisker2_right4(frame), coordinate_table.whisker2_right5(frame), ...
                    coordinate_table.whisker2_right6(frame)];
                y_whisk = [coordinate_table.whisker2_right4_1(frame), coordinate_table.whisker2_right5_1(frame), ...
                    coordinate_table.whisker2_right6_1(frame)];

                [~, ~, rad_curv] = circle_fit(x_whisk,y_whisk);
                curv = 1/rad_curv;
        end

        WhiskerCurv{1,4}{:}(frame,i) = curv;

    end
    WhiskerCurv{1,4}{:}(i,:) = movmean(WhiskerCurv{1,4}{:}(i,:),5,'omitnan');
end

