function [CohortTable] = create_cohort_table (Cohort_Data)
% thanks Nadine for the inspiration (:
% creates a table (CohortTable) containing mouse_ID, stage, session_num and d_prime

flag = 0;
for m = 1:size(Cohort_Data,2)
    session_folders = Cohort_Data(m).session_names;
    for s = 1:length(session_folders)
        if flag == 0
            folder_parts = split(session_folders{s},'\');
            mouse_ID = folder_parts(contains(folder_parts,'#'));
            session_name = folder_parts(contains(folder_parts,'session'));
            session_name_parts = split(session_name,'_');
            stage = session_name_parts(1);
            session_num = session_name_parts(end);
            CohortTable(s,1) = mouse_ID;
            CohortTable(s,2) = stage;
            CohortTable(s,3) = session_num;
            d_prime = Cohort_Data(m).dvalues_sessions;
            d_prime = num2cell(d_prime);
            CohortTable(s,4) = d_prime(s,1);
        else
            folder_parts = split(session_folders{s},'\');
            mouse_ID = folder_parts(contains(folder_parts,'#'));
            session_name = folder_parts(contains(folder_parts,'session'));
            session_name_parts = split(session_name,'_');
            stage = session_name_parts(1);
            session_num = session_name_parts(end);
            indexcount = flag + s;
            CohortTable(indexcount,1) = mouse_ID;
            CohortTable(indexcount,2) = stage;
            CohortTable(indexcount,3) = session_num;
            d_prime = Cohort_Data(m).dvalues_sessions;
            d_prime = num2cell(d_prime);
            CohortTable(indexcount,4) = d_prime(s,1);
        end
    end
    flag = size(CohortTable,1);
end
end