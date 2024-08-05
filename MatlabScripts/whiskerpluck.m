%% Performance before and after whiskerpluck
% only works if animalData.m is loaded
currentFolder = pwd;
load(fullfile(currentFolder,'/RawData/animalData'))

%% create whiskerpluck table
animalSelection = [11 17]; %only cohorts with whiskerpluck
[dvalues, sessNames] = findSessions(animalData,animalSelection);
numMice = sum(arrayfun(@(c) length(dvalues{c}), 1:length(dvalues)));
whiskerpluck_table = NaN(6*numMice,3);

dvaluestemp = cellfun(@(c) cat(1, c{:}),dvalues,'UniformOutput',false);
dvalues = cat(1,dvaluestemp{:});
whiskerpluck_table(1:end,1) = dvalues;

whiskerpluck_table(1:end,2) = repmat(setdiff((-3:3)',0),numMice,1);
for i = 1:length(whiskerpluck_table)
    if whiskerpluck_table(i,2)<0
        whiskerpluck_table(i,3) = 1;
    elseif whiskerpluck_table(i,2)>0
        whiskerpluck_table(i,3) = 2;
    end
end

%% some statistics
prepluckFlag = whiskerpluck_table(:, 2) == -1;
postpluckFlag = whiskerpluck_table(:, 2) == 1;

[~,p_paired] = ttest(whiskerpluck_table(prepluckFlag,1),whiskerpluck_table(postpluckFlag,1));
if p_paired < 0.05
    fprintf('The d prime is significantly different before and after the whiskerpluck. p =  %.3f\n', p_paired)
else
    fprintf('The d prime is not significantly different before and after the whiskerpluck for a contrast of %dmm, p =  %.3f\n', p_paired)
end

%% Plot Data
% first session before and first session after pluck
sesFlagbefore = (whiskerpluck_table(1:end,2) == -1);
sesFlagafter = (whiskerpluck_table(1:end,2) == 1);
plotFlag = sesFlagbefore+sesFlagafter;
figure; hold on; title('Population performance before and after whisker pluck')
boxchart(whiskerpluck_table(plotFlag == 1,3), whiskerpluck_table(plotFlag == 1,1),'BoxFaceColor','k','MarkerColor','k')
scatter(whiskerpluck_table(plotFlag == 1,3),whiskerpluck_table(plotFlag == 1,1),'Marker','.','MarkerEdgeColor','k','Jitter','on')
xticks([1,2]); xticklabels({'Pre whisker pluck','Post whisker pluck'})
ylabel('d prime')
yline([1.65, 1.65],'Color','black','LineStyle','--')
yline([0, 0],'Color',[.7 .7 .7],'LineStyle','--')

dprime_max = max(arrayfun(@(s) max(whiskerpluck_table(whiskerpluck_table(:,2) == s, 1)), [-1 1]));
plotStatistics(p_paired,max(dprime_max),1,2)
