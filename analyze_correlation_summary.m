% === Step 0: Setup Paths and Folders ===
rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
figureFolder = fullfile(rootFolder, 'figures');
statFolder = fullfile(rootFolder, 'stats');
if ~exist(figureFolder, 'dir'), mkdir(figureFolder); end
if ~exist(statFolder, 'dir'), mkdir(statFolder); end

mouseFolders = dir(fullfile(rootFolder, 'm*'));
results = {};

% === Step 1: Extract correlation values per session ===
for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(rootFolder, mouseID);
    
    if ~isfolder(mousePath), continue; end
    files = dir(fullfile(mousePath, '*.groupCorrMatrix.mat'));
    
    for j = 1:length(files)
        fileName = files(j).name;
        fullPath = fullfile(mousePath, fileName);
        data = load(fullPath);
        
        f = fieldnames(data);
        corrMat = data.(f{1});
        
        if size(corrMat,1) ~= 10 || size(corrMat,2) ~= 10
            warning("File %s is not 10x10. Skipped.", fileName);
            continue;
        end
        
        m = corrMat(1:5,1:5);
        maskM = triu(true(5),1);
        meanMorning = mean(m(maskM));

        a = corrMat(6:10,6:10);
        maskA = triu(true(5),1);
        meanAfternoon = mean(a(maskA));

        ma = corrMat(1:5,6:10);
        meanMorningAfternoon = mean(ma(:));
        
        tokens = regexp(fileName, '\.(\d{8})\.', 'tokens');
        if isempty(tokens), continue; end
        dateStr = tokens{1}{1};
        
        results = [results; {mouseID, dateStr, meanMorning, meanAfternoon, meanMorningAfternoon}];
    end
end

% === Step 2: Save Summary Table ===
T = cell2table(results, ...
    'VariableNames', {'MouseID', 'Date', 'MorningCorr', 'AfternoonCorr', 'MorningAfternoonCorr'});
summaryCSV = fullfile(rootFolder, 'summary_correlation_values.csv');
writetable(T, summaryCSV);
disp('Saved summary table.');

% === Step 3: ANOVA and Boxplot for All Mice Combined ===
allCorrs = [T.MorningCorr; T.AfternoonCorr; T.MorningAfternoonCorr];
labels = [repmat({'Morning'}, height(T), 1); 
          repmat({'Afternoon'}, height(T), 1);
          repmat({'Morning-Afternoon'}, height(T), 1)];

% ANOVA
[~, tbl_all, stats_all] = anova1(allCorrs, labels, 'off');

% Save boxplot
figAll = figure;
boxplot(allCorrs, labels);
title('All Mice - Correlation Type Comparison');
ylabel('Mean Correlation');
saveas(figAll, fullfile(figureFolder, 'boxplot_all_mice.png'));

% Save ANOVA stats as CSV
tbl_all_csv = cell2table(tbl_all(2:end,:), 'VariableNames', ...
    {'Source','SS','df','MS','F','Prob_F'});
writetable(tbl_all_csv, fullfile(statFolder, 'anova_all_mice.csv'));

% Save post-hoc comparison
figPost = figure;
multcompare(stats_all);
title('Post-hoc Comparison - All Mice');
saveas(figPost, fullfile(figureFolder, 'posthoc_all_mice.png'));

% === Step 4: Per-Mouse ANOVA and Plots ===
uniqueMice = unique(T.MouseID);

for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    mouseData = T(strcmp(T.MouseID, mouse), :);

    vals = [mouseData.MorningCorr; mouseData.AfternoonCorr; mouseData.MorningAfternoonCorr];
    labs = [repmat({'Morning'}, height(mouseData), 1); 
            repmat({'Afternoon'}, height(mouseData), 1); 
            repmat({'Morning-Afternoon'}, height(mouseData), 1)];

    % ANOVA (silent)
    [~, tbl_mouse, stats_mouse] = anova1(vals, labs, 'off');
    
    % Save boxplot
    figMouse = figure;
    boxplot(vals, labs);
    title(['Boxplot - ' mouse]);
    ylabel('Mean Correlation');
    saveas(figMouse, fullfile(figureFolder, ['boxplot_' mouse '.png']));

    % Save ANOVA table
    tbl_mouse_csv = cell2table(tbl_mouse(2:end,:), 'VariableNames', ...
        {'Source','SS','df','MS','F','Prob_F'});
    writetable(tbl_mouse_csv, fullfile(statFolder, ['anova_' mouse '.csv']));

    % Save post-hoc
    figPostMouse = figure;
    multcompare(stats_mouse);
    title(['Post-hoc - ' mouse]);
    saveas(figPostMouse, fullfile(figureFolder, ['posthoc_' mouse '.png']));
end

disp('✅ All plots and stats saved.');
