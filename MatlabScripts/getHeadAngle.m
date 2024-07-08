function HeadAngle = getHeadAngle(coordinate_table, certainty)
% This function calculates the rotational angle of the mouse head at any
% given timepoint.
% A proper table with all the coordinates from the DLC csv file is
% necessary (see "Z:\Filippo\Scripts\MatlabScripts\getBehavioralMetrics.m").
% The certainty variable defines the cutoff, after which certain values
% with low certainty are dismissed.

% You need at least the position of the nose and two opposing coordinates 
% of the whisker pads.
% With more data points (i.e., coordinates of whisker pads), the mean of
% all resulting angles will be calculated for robustness.

% Later the rotational angles will be smoothed for robustness.

HeadAngle = nan(height(coordinate_table),1);

for row = 1:height(coordinate_table)
    if coordinate_table.nosetip_2(row) >= certainty
        P0 = [coordinate_table.nosetip(row),coordinate_table.nosetip_1(row)];
        % Check for each pair of the whisker pad, if points are visible and
        % calculate repective orientation angles, if they are.
        if coordinate_table.leftside1_2(row) >= certainty && coordinate_table.rightside1_2(row) >= certainty
            P1 = [coordinate_table.leftside1(row),coordinate_table.leftside1_1(row)];
            P2 = [coordinate_table.rightside1(row),coordinate_table.rightside1_1(row)];
            
            % Create equilateral triangle with P1, P0 and P3 
            % and generate a line going through the midpoint. 
            P3 = P0 + (P2-P0)*(pdist([P1;P0])/pdist([P2;P0]));
            M = P1 + (P3-P1)/2;
            slope = P0 - M;
            slope = slope(2)/slope(1);
            slope_deg = atan(slope)/pi*180;
            
            % rot_deg > 0° means clockwise rotation
            % rot_deg < 0° means counter-clockwise rotation
            if P0(2)>M(2)
                if slope_deg < 0
                    rot_deg(1) = -90-slope_deg;
                else
                    rot_deg(1) = 90-slope_deg;
                end
            else % if P0(2) < M(2) that means that the head is oriented away from the lickport
                if slope_deg > 0
                    rot_deg(1) = -90-slope_deg;
                else
                    rot_deg(1) = 90-slope_deg;
                end
            end
        else
            rot_deg(1) = NaN;
        end

        if coordinate_table.leftside2_2(row) >= certainty && coordinate_table.rightside2_2(row) >= certainty
            P1 = [coordinate_table.leftside2(row),coordinate_table.leftside2_1(row)];
            P2 = [coordinate_table.rightside2(row),coordinate_table.rightside2_1(row)];
            
            % Create equilateral triangle with P1, P0 and P3 
            % and generate a line going through the midpoint. 
            P3 = P0 + (P2-P0)*(pdist([P1;P0])/pdist([P2;P0]));
            M = P1 + (P3-P1)/2;
            slope = P0 - M;
            slope = slope(2)/slope(1);
            slope_deg = atan(slope)/pi*180;
            
            % rot_deg > 0° means clockwise rotation
            % rot_deg < 0° means counter-clockwise rotation
            if P0(2)>M(2)
                if slope_deg < 0
                    rot_deg(2) = -90-slope_deg;
                else
                    rot_deg(2) = 90-slope_deg;
                end
            else % if P0(2) < M(2) that means that the head is oriented away from the lickport
                if slope_deg > 0
                    rot_deg(2) = -90-slope_deg;
                else
                    rot_deg(2) = 90-slope_deg;
                end
            end
        else
            rot_deg(2) = NaN;
        end

        if coordinate_table.leftside3_2(row) >= certainty && coordinate_table.rightside3_2(row) >= certainty
            P1 = [coordinate_table.leftside3(row),coordinate_table.leftside3_1(row)];
            P2 = [coordinate_table.rightside3(row),coordinate_table.rightside3_1(row)];
            
            % Create equilateral triangle with P1, P0 and P3 
            % and generate a line going through the midpoint. 
            P3 = P0 + (P2-P0)*(pdist([P1;P0])/pdist([P2;P0]));
            M = P1 + (P3-P1)/2;
            slope = P0 - M;
            slope = slope(2)/slope(1);
            slope_deg = atan(slope)/pi*180;
            
            % rot_deg > 0° means clockwise rotation
            % rot_deg < 0° means counter-clockwise rotation
            if P0(2)>M(2)
                if slope_deg < 0
                    rot_deg(3) = -90-slope_deg;
                else
                    rot_deg(3) = 90-slope_deg;
                end
            else % if P0(2) < M(2) that means that the head is oriented away from the lickport
                if slope_deg > 0
                    rot_deg(3) = -90-slope_deg;
                else
                    rot_deg(3) = 90-slope_deg;
                end
            end
        else
            rot_deg(3) = NaN;
        end
        
        HeadAngle(row) = mean(rot_deg,'omitnan');

    end
end

HeadAngle = single(HeadAngle);
HeadAngle = movmean(HeadAngle,5,'omitnan');

