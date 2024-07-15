%% Extinction
% only works if animalData.m is loaded

%% create dprime-array for sessions 
% -> last four sessions intial rule, reversed rule and first four sessions extinction
% -> animals per row and sessions per column

cohortData = animalData.cohort(12).animal; %only cohort that underwent extinction
numMice = length(cohortData);
numSes = 4;

% extinction phase is stage P3.6 for all animals in cohort 12
% P3.2 is the conditioning phase for all animals
% P3.4 is the reversal phase for all animals
alldprime = NaN (sum(numMice),numSes*3);
for mouseIdx = 1:numMice
    isP6 = contains(cohortData(mouseIdx).session_names,'P3.6');
    isP2 = contains(cohortData(mouseIdx).session_names,'P3.2');
    isP4 = contains(cohortData(mouseIdx).session_names,'P3.4');
    sesFlag_first = find(isP6, 1, 'first');
    sesFlag_last_rev = find(isP4, 1, 'last');
    sesFlag_last_cond = find(isP2, 1, 'last');

    dprime_cond = cohortData(mouseIdx).dvalues_sessions(sesFlag_last_cond-numSes+1:sesFlag_last_cond);
    dprime_before = cohortData(mouseIdx).dvalues_sessions(sesFlag_last_rev-numSes+1:sesFlag_last_rev);
    dprime_after = cohortData(mouseIdx).dvalues_sessions(sesFlag_first:sesFlag_first+numSes-1);

    if isempty(dprime_after)
        continue
    else
        alldprime(mouseIdx, 1:numSes) = dprime_cond;
        alldprime(mouseIdx, numSes+1:numSes*2) = dprime_before;
        alldprime(mouseIdx, numSes*2+1:numSes*3) = dprime_after;
    end
end

% remove NaNs that result from animals not going through the extinction stage
alldprime(isnan(alldprime(:,1)),:) = [];

%% prepare array for plotting
mouseFlag = 1:height(alldprime);
dprime_cond =  cell2mat(arrayfun(@(a) vertcat(alldprime(a,1:numSes)), mouseFlag, 'UniformOutput', false));
dprime_before =  cell2mat(arrayfun(@(a) vertcat(alldprime(a,numSes+1:numSes*2)), mouseFlag, 'UniformOutput', false));
dprime_after =  cell2mat(arrayfun(@(a) vertcat(alldprime(a,numSes*2+1:numSes*3)), mouseFlag, 'UniformOutput', false));

%%
figure; hold on;
boxchart(ones(1,length(dprime_cond)), dprime_cond, 'BoxFaceColor', [0.1294 0.4 0.6745])
scatter(ones(1,length(dprime_cond)), dprime_cond,'Marker','.','Jitter','on','MarkerEdgeColor',[0.1294 0.4 0.6745])
boxchart(ones(1,length(dprime_before))+1, dprime_before, 'BoxFaceColor', [0.9373 0.5412 0.3843])
scatter(ones(1,length(dprime_before))+1, dprime_before,'Marker','.','Jitter','on','MarkerEdgeColor',[0.9373 0.5412 0.3843])
boxchart(ones(1,length(dprime_after))+2, dprime_after, 'BoxFaceColor', 'k', 'MarkerStyle', 'none')
scatter(ones(1,length(dprime_after))+2, dprime_after,'Marker','.','Jitter','on','MarkerEdgeColor','k')

yline([1.65, 1.65],'Color','black','LineStyle','--')
xticks([1 2 3]); xticklabels({'Initial rule','Reversed rule', 'Extinction'})
ylabel('d prime')
title('Population performance before and after extinction')
