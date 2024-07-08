function WhiskerAngle = getBaseAngle(coordinate_table, certainty)
% This function assesses the angle of the whiskers at the base at any
% given timepoint.
% A proper table with all the coordinates from the DLC csv file is
% necessary (see "Z:\Filippo\Scripts\MatlabScripts\getBehavioralMetrics.m").
% The certainty variable defines the cutoff, after which certain values
% with low certainty are dismissed.

% You need all three coordinates of the respective whisker pad and the
% first two points of the six whisker mark points.

% Later the angles will be smoothed for robustness.

% The output will be a matrix (single) n x 4 (n = number of timestamps)
% The columns will be: whiskerLeft1, whiskerLeft2, whiskerRight1, whiskerRight2

WhiskerAngle = nan(height(coordinate_table),4);

% Extracting all the frames, where first and second whisker label,
% as well as the whisker pads are reliably detected.

% First whisker left
safe_frames = find(coordinate_table.whisker1_left1_2 > certainty & coordinate_table.whisker1_left2_2 > certainty & ...
    coordinate_table.leftside1_2 > certainty & coordinate_table.leftside2_2 > certainty & coordinate_table.leftside3_2 > certainty);

for frame = safe_frames'
    xvals = [coordinate_table.leftside1(frame), coordinate_table.leftside2(frame), coordinate_table.leftside3(frame)];
    yvals = [coordinate_table.leftside1_1(frame), coordinate_table.leftside2_1(frame), coordinate_table.leftside3_1(frame)];

    [x_pad, y_pad, rad_pad] = circle_fit(xvals,yvals);

    if coordinate_table.whisker1_left3_2(frame) > certainty
        % If present, fit a linear regression to the first three labels
        x = [coordinate_table.whisker1_left1(frame),coordinate_table.whisker1_left2(frame),coordinate_table.whisker1_left3(frame)];
        y = [coordinate_table.whisker1_left1_1(frame),coordinate_table.whisker1_left2_1(frame),coordinate_table.whisker1_left3_1(frame)];
        coeffs = polyfit(x, y, 1);
    else
        % Create line between the first two whisker labels
        x = [coordinate_table.whisker1_left1(frame),coordinate_table.whisker1_left2(frame)];
        y = [coordinate_table.whisker1_left1_1(frame),coordinate_table.whisker1_left2_1(frame)];
        coeffs = polyfit(x, y, 1);
    end

    % Calculate the intercept with the whisker-pad-circle
    [xout,yout] = linecirc(coeffs(1),coeffs(2),x_pad, y_pad, rad_pad);
    if numel(xout)==2 && norm([xout(1),yout(1)]-[x(1),y(1)]) < norm([xout(2),yout(2)]-[x(1),y(1)])
        xout = xout(1);
        yout = yout(1);
    else
        xout = xout(2);
        yout = yout(2);
    end

    % Find the tangent of the intercept
    tang_vec = [-(yout-y_pad), xout-x_pad];
    whisk_vec = [1, coeffs(1)];

    % Get the angle between tangent and whisker-fit
    angle = acosd(dot(tang_vec,whisk_vec)/(norm(tang_vec)*norm(whisk_vec)));
    WhiskerAngle(frame,1) = angle;
end

% Second whisker left
safe_frames = find(coordinate_table.whisker2_left1_2 > certainty & coordinate_table.whisker2_left2_2 > certainty & ...
    coordinate_table.leftside1_2 > certainty & coordinate_table.leftside2_2 > certainty & coordinate_table.leftside3_2 > certainty);

for frame = safe_frames'
    xvals = [coordinate_table.leftside1(frame), coordinate_table.leftside2(frame), coordinate_table.leftside3(frame)];
    yvals = [coordinate_table.leftside1_1(frame), coordinate_table.leftside2_1(frame), coordinate_table.leftside3_1(frame)];

    [x_pad, y_pad, rad_pad] = circle_fit(xvals,yvals);

    if coordinate_table.whisker2_left3_2(frame) > certainty
        % If present, fit a linear regression to the first three labels
        x = [coordinate_table.whisker2_left1(frame),coordinate_table.whisker2_left2(frame),coordinate_table.whisker2_left3(frame)];
        y = [coordinate_table.whisker2_left1_1(frame),coordinate_table.whisker2_left2_1(frame),coordinate_table.whisker2_left3_1(frame)];
        coeffs = polyfit(x, y, 1);
    else
        % Create line between the first two whisker labels
        x = [coordinate_table.whisker2_left1(frame),coordinate_table.whisker2_left2(frame)];
        y = [coordinate_table.whisker2_left1_1(frame),coordinate_table.whisker2_left2_1(frame)];
        coeffs = polyfit(x, y, 1);
    end

    % Calculate the intercept with the whisker-pad-circle
    [xout,yout] = linecirc(coeffs(1),coeffs(2),x_pad, y_pad, rad_pad);
    if numel(xout)==2 && norm([xout(1),yout(1)]-[x(1),y(1)]) < norm([xout(2),yout(2)]-[x(1),y(1)])
        xout = xout(1);
        yout = yout(1);
    else
        xout = xout(2);
        yout = yout(2);
    end

    % Find the tangent of the intercept
    tang_vec = [-(yout-y_pad), xout-x_pad];
    whisk_vec = [1, coeffs(1)];

    % Get the angle between tangent and whisker-fit
    angle = acosd(dot(tang_vec,whisk_vec)/(norm(tang_vec)*norm(whisk_vec)));
    WhiskerAngle(frame,2) = angle;
end

% First whisker right
safe_frames = find(coordinate_table.whisker1_right1_2 > certainty & coordinate_table.whisker1_right2_2 > certainty & ...
    coordinate_table.rightside1_2 > certainty & coordinate_table.rightside2_2 > certainty & coordinate_table.rightside3_2 > certainty);

for frame = safe_frames'
    xvals = [coordinate_table.rightside1(frame), coordinate_table.rightside2(frame), coordinate_table.rightside3(frame)];
    yvals = [coordinate_table.rightside1_1(frame), coordinate_table.rightside2_1(frame), coordinate_table.rightside3_1(frame)];

    [x_pad, y_pad, rad_pad] = circle_fit(xvals,yvals);

    if coordinate_table.whisker1_right3_2(frame) > certainty
        % If present, fit a linear regression to the first three labels
        x = [coordinate_table.whisker1_right1(frame),coordinate_table.whisker1_right2(frame),coordinate_table.whisker1_right3(frame)];
        y = [coordinate_table.whisker1_right1_1(frame),coordinate_table.whisker1_right2_1(frame),coordinate_table.whisker1_right3_1(frame)];
        coeffs = polyfit(x, y, 1);
    else
        % Create line between the first two whisker labels
        x = [coordinate_table.whisker1_right1(frame),coordinate_table.whisker1_right2(frame)];
        y = [coordinate_table.whisker1_right1_1(frame),coordinate_table.whisker1_right2_1(frame)];
        coeffs = polyfit(x, y, 1);
    end

    % Calculate the intercept with the whisker-pad-circle
    [xout,yout] = linecirc(coeffs(1),coeffs(2),x_pad, y_pad, rad_pad);
    if numel(xout)==2 && norm([xout(1),yout(1)]-[x(1),y(1)]) < norm([xout(2),yout(2)]-[x(1),y(1)])
        xout = xout(1);
        yout = yout(1);
    else
        xout = xout(2);
        yout = yout(2);
    end

    % Find the tangent of the intercept
    tang_vec = [-(yout-y_pad), xout-x_pad];
    whisk_vec = [1, coeffs(1)];

    % Get the angle between tangent and whisker-fit
    angle = acosd(dot(tang_vec,whisk_vec)/(norm(tang_vec)*norm(whisk_vec)));
    WhiskerAngle(frame,3) = angle;
end

% Second whisker right
safe_frames = find(coordinate_table.whisker2_right1_2 > certainty & coordinate_table.whisker2_right2_2 > certainty & ...
    coordinate_table.rightside1_2 > certainty & coordinate_table.rightside2_2 > certainty & coordinate_table.rightside3_2 > certainty);

for frame = safe_frames'
    xvals = [coordinate_table.rightside1(frame), coordinate_table.rightside2(frame), coordinate_table.rightside3(frame)];
    yvals = [coordinate_table.rightside1_1(frame), coordinate_table.rightside2_1(frame), coordinate_table.rightside3_1(frame)];

    [x_pad, y_pad, rad_pad] = circle_fit(xvals,yvals);

    if coordinate_table.whisker2_right3_2(frame) > certainty
        % If present, fit a linear regression to the first three labels
        x = [coordinate_table.whisker2_right1(frame),coordinate_table.whisker2_right2(frame),coordinate_table.whisker2_right3(frame)];
        y = [coordinate_table.whisker2_right1_1(frame),coordinate_table.whisker2_right2_1(frame),coordinate_table.whisker2_right3_1(frame)];
        coeffs = polyfit(x, y, 1);
    else
        % Create line between the first two whisker labels
        x = [coordinate_table.whisker2_right1(frame),coordinate_table.whisker2_right2(frame)];
        y = [coordinate_table.whisker2_right1_1(frame),coordinate_table.whisker2_right2_1(frame)];
        coeffs = polyfit(x, y, 1);
    end

    % Calculate the intercept with the whisker-pad-circle
    [xout,yout] = linecirc(coeffs(1),coeffs(2),x_pad, y_pad, rad_pad);
    if numel(xout)==2 && norm([xout(1),yout(1)]-[x(1),y(1)]) < norm([xout(2),yout(2)]-[x(1),y(1)])
        xout = xout(1);
        yout = yout(1);
    else
        xout = xout(2);
        yout = yout(2);
    end

    % Find the tangent of the intercept
    tang_vec = [-(yout-y_pad), xout-x_pad];
    whisk_vec = [1, coeffs(1)];

    % Get the angle between tangent and whisker-fit
    angle = acosd(dot(tang_vec,whisk_vec)/(norm(tang_vec)*norm(whisk_vec)));
    WhiskerAngle(frame,4) = angle;
end

WhiskerAngle = single(WhiskerAngle);
WhiskerAngle = movmean(WhiskerAngle,5,'omitnan');
