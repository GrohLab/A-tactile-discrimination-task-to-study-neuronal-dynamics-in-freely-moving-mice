function [stages] = getstagenames(cohortData)

stage_names = cell(1,numel(cohortData));
for i = 1:numel(cohortData)
    stage_names{i} = cellfun(@(x) regexp(x,'P3.*_','match'), cohortData(i).session_names);
end
unique_list = cell(1, size(stage_names, 2));
for i = 1:size(stage_names, 2)
    unique_list{i} = unique(stage_names{i});
end
unique_ses = unique(cat(1, unique_list{:}));
unique_ses_split = regexp(unique_ses,'_','split', 'once');
unique_ses_split = vertcat(unique_ses_split{:});
stages = unique_ses_split(:,1);
end
