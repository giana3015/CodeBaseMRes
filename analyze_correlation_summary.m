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
disp('✅ Saved summary table.');

% === Step 3: ANOVA and Boxplot for All Mice Combined ===
allCorrs = [T.MorningCorr; T.AfternoonCorr; T.MorningAfternoonCorr];
labels = [repmat({'Morning'}, height(T), 1); 
          repmat({'Afternoon'}, height(T), 1);
          repmat({'Morning-Afternoon'}, height(T), 1)];

% ANOVA (silent)
[~, tbl_all, stats_all] = anova1(allCorrs, labels, 'off');

% Boxplot
figAll = figure('Visible', 'off');
boxplot(allCorrs, labels);
title('All Mice - Correlation Type Comparison');
ylabel('Mean Correlation');
saveas(figAll, fullfile(figureFolder, 'boxplot_all_mice.png'));
close(figAll);

% Post-hoc plot
figPost = figure('Visible', 'off');
multcompare(stats_all);
title('Post-hoc Comparison - All Mice');
saveas(figPost, fullfile(figureFolder, 'posthoc_all_mice.png'));
close(figPost);

% Save ANOVA stats to CSV
tbl_all_csv = cell2table(tbl_all(2:end,:), 'VariableNames', ...
    {'Source','SS','df','MS','F','Prob_F'});
writetable(tbl_all_csv, fullfile(statFolder, 'anova_all_mice.csv'));

% === Step 4: Per-Mouse ANOVA and Boxplots ===
uniqueMice = unique(T.MouseID);

for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    mouseData = T(strcmp(T.MouseID, mouse), :);

    if height(mouseData) < 2
        fprintf('⚠️ Skipping %s (not enough sessions for ANOVA)\n', mouse);
        continue;
    end

    vals = [mouseData.MorningCorr; mouseData.AfternoonCorr; mouseData.MorningAfternoonCorr];
    labs = [repmat({'Morning'}, height(mouseData), 1); 
            repmat({'Afternoon'}, height(mouseData), 1); 
            repmat({'Morning-Afternoon'}, height(mouseData), 1)];

    % ANOVA
    [~, tbl_mouse, stats_mouse] = anova1(vals, labs, 'off');

    % Boxplot
    figMouse = figure('Visible', 'off');
    boxplot(vals, labs);
    title(['Boxplot - ' mouse]);
    ylabel('Mean Correlation');
    saveas(figMouse, fullfile(figureFolder, ['boxplot_' mouse '.png']));
    close(figMouse);

    % Save ANOVA stats
    tbl_mouse_csv = cell2table(tbl_mouse(2:end,:), 'VariableNames', ...
        {'Source','SS','df','MS','F','Prob_F'});
    writetable(tbl_mouse_csv, fullfile(statFolder, ['anova_' mouse '.csv']));

    % Try post-hoc
    try
        figPostMouse = figure('Visible', 'off');
        multcompare(stats_mouse);
        title(['Post-hoc - ' mouse]);
        saveas(figPostMouse, fullfile(figureFolder, ['posthoc_' mouse '.png']));
        close(figPostMouse);
    catch ME
        warning("Skipping post-hoc for %s: %s", mouse, ME.message);
    end
end

disp('✅ All plots and stats saved. Skipped mice were printed in terminal.');

rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
T = readtable(fullfile(rootFolder, 'summary_correlation_values.csv'));

% === Boxplots with ANOVA p-values annotated ===
boxFolder = fullfile(rootFolder, 'box plot with anova');
if ~exist(boxFolder, 'dir'), mkdir(boxFolder); end

% All mice combined
allCorrs = [T.MorningCorr; T.AfternoonCorr; T.MorningAfternoonCorr];
labels = [repmat({'Morning'}, height(T), 1); 
          repmat({'Afternoon'}, height(T), 1);
          repmat({'Morning-Afternoon'}, height(T), 1)];

[p_all, ~, ~] = anova1(allCorrs, labels, 'off');
fig = figure('Visible', 'off');
boxplot(allCorrs, labels);
title(sprintf('All Mice — ANOVA p = %.3g', p_all));
ylabel('Mean Correlation');
saveas(fig, fullfile(boxFolder, 'boxplot_all_mice_with_anova.png'));
close(fig);

% Each mouse individually
uniqueMice = unique(T.MouseID);
for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    mouseData = T(strcmp(T.MouseID, mouse), :);

    if height(mouseData) < 2
        fprintf('⚠️ Skipping boxplot+ANOVA for %s (not enough sessions)\n', mouse);
        continue;
    end

    vals = [mouseData.MorningCorr; mouseData.AfternoonCorr; mouseData.MorningAfternoonCorr];
    labs = [repmat({'Morning'}, height(mouseData), 1); 
            repmat({'Afternoon'}, height(mouseData), 1); 
            repmat({'Morning-Afternoon'}, height(mouseData), 1)];

    [p_mouse, ~, ~] = anova1(vals, labs, 'off');
    fig = figure('Visible', 'off');
    boxplot(vals, labs);
    title(sprintf('%s — ANOVA p = %.3g', mouse, p_mouse));
    ylabel('Mean Correlation');
    saveas(fig, fullfile(boxFolder, ['boxplot_' mouse '_with_anova.png']));
    close(fig);
end


% Set root folder
rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
boxFolder = fullfile(rootFolder, 'boxplot_with_anova_posthoc');
if ~exist(boxFolder, 'dir'), mkdir(boxFolder); end

% Function to extract labels from multcompare output
getLabelPair = @(i,j) [sprintf('%s vs %s', i, j)];

% Function to run ANOVA + post-hoc and make annotated boxplot
function create_boxplot_with_stats(dataTable, subjectID, outFolder)
    if height(dataTable) < 2
        fprintf('⚠️ Skipping %s (not enough sessions)\n', subjectID);
        return;
    end

    vals = [dataTable.MorningCorr; dataTable.AfternoonCorr; dataTable.MorningAfternoonCorr];
    labs = [repmat({'Morning'}, height(dataTable), 1); 
            repmat({'Afternoon'}, height(dataTable), 1); 
            repmat({'Morning-Afternoon'}, height(dataTable), 1)];

    % Run ANOVA
    [p_anova, tbl, stats] = anova1(vals, labs, 'off');

    % Run Tukey post-hoc
    try
        [c, m] = multcompare(stats, 'Display', 'off');
    catch
        fprintf('⚠️ Tukey post-hoc failed for %s\n', subjectID);
        return;
    end

    % Create annotated boxplot
    fig = figure('Visible', 'off');
    boxplot(vals, labs);
    title(sprintf('%s — ANOVA p = %.3g', subjectID, p_anova));
    ylabel('Mean Correlation');

    % Overlay Tukey p-values on plot
    xOffsets = [1, 1, 2];
    yOffsets = [1.02, 1.07, 1.12];
    comparisons = {'Morning vs Afternoon', ...
                   'Morning vs Morning-Afternoon', ...
                   'Afternoon vs Morning-Afternoon'};
    for k = 1:3
        txt = sprintf('%s\np = %.3g', comparisons{k}, c(k,6));
        text(xOffsets(k), yOffsets(k) * max(vals), txt, ...
             'HorizontalAlignment', 'center', 'FontSize', 8);
    end

    % Save figure
    saveas(fig, fullfile(outFolder, sprintf('boxplot_%s.png', subjectID)));
    close(fig);

    % Save stats to CSV
    compTable = table(comparisons', c(:,6), 'VariableNames', {'Comparison', 'Tukey_p'});
    compTable.ANOVA_p = repmat(p_anova, 3, 1);
    writetable(compTable, fullfile(outFolder, sprintf('stats_%s.csv', subjectID)));
end

% === Run for all mice combined ===
T_all = T;
create_boxplot_with_stats(T_all, 'all_mice', boxFolder);

% === Run for each mouse ===
uniqueMice = unique(T.MouseID);
for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    mouseData = T(strcmp(T.MouseID, mouse), :);
    create_boxplot_with_stats(mouseData, mouse, boxFolder);
end

% === Set root and output folder ===
rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
boxFolder = fullfile(rootFolder, 'boxplot_with_anova_posthoc');
if ~exist(boxFolder, 'dir'), mkdir(boxFolder); end

% === Load data table ===
T = readtable(fullfile(rootFolder, 'summary_correlation_values.csv'));

% === Run for all mice combined ===
T_all = T;
create_boxplot_with_stats(T_all, 'all_mice', boxFolder);

% === Run for each mouse ===
uniqueMice = unique(T.MouseID);
for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    mouseData = T(strcmp(T.MouseID, mouse), :);
    create_boxplot_with_stats(mouseData, mouse, boxFolder);
end

disp('✅ Boxplots with ANOVA and Tukey post-hoc saved to "boxplot_with_anova_posthoc".');



% === Function: create_boxplot_with_stats with significance stars ===
function create_boxplot_with_stats(dataTable, subjectID, outFolder)
    if height(dataTable) < 2
        fprintf('⚠️ Skipping %s (not enough sessions)\n', subjectID);
        return;
    end

    % Combine values and labels
    vals = [dataTable.MorningCorr; dataTable.AfternoonCorr; dataTable.MorningAfternoonCorr];
    labs = [repmat({'Morning'}, height(dataTable), 1); 
            repmat({'Afternoon'}, height(dataTable), 1); 
            repmat({'Morning-Afternoon'}, height(dataTable), 1)];

    % Run ANOVA
    [p_anova, ~, stats] = anova1(vals, labs, 'off');

    % Run Tukey post-hoc comparison
    try
        [c, ~] = multcompare(stats, 'Display', 'off');
    catch
        fprintf('⚠️ Tukey post-hoc failed for %s\n', subjectID);
        return;
    end

    % Significance label function
    sig_label = @(p) ...
        ternary(p < 0.001, '***', ...
        ternary(p < 0.01, '**', ...
        ternary(p < 0.05, '*', 'ns')));

    % Create nicely formatted figure
    fig = figure('Visible', 'off', 'Position', [100 100 800 600]);
    boxplot(vals, labs, 'Colors', 'k', 'Widths', 0.5, 'Symbol', '');
    ylabel('Mean Correlation', 'FontSize', 12);
    title(sprintf('%s — ANOVA p = %.4g', subjectID, p_anova), ...
          'FontSize', 14, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    grid on;
    box on;

    % Annotate Tukey post-hoc comparisons with stars
    comparisons = {'Morning vs Afternoon', ...
                   'Morning vs Morning-Afternoon', ...
                   'Afternoon vs Morning-Afternoon'};
    xPairs = [1 2; 1 3; 2 3];
    yMax = max(vals) * 1.1;
    yMin = min(vals);
    sigStars = cell(3,1);

    for k = 1:3
        x = mean(xPairs(k,:));
        y = yMax + (k-1)*0.05 * yMax;
        pval = c(k,6);
        label = sig_label(pval);
        sigStars{k} = label;
        text(x, y, sprintf('%s\n%s', comparisons{k}, label), ...
            'HorizontalAlignment', 'center', 'FontSize', 10);
    end

    ylim([yMin*0.9, yMax + 0.2*yMax]);

    % Save figure
    saveas(fig, fullfile(outFolder, sprintf('boxplot_%s.png', subjectID)));
    close(fig);

    % Save stats as CSV
    compTable = table(comparisons', c(:,6), sigStars, ...
        'VariableNames', {'Comparison', 'Tukey_p', 'Significance'});
    compTable.ANOVA_p = repmat(p_anova, 3, 1);
    writetable(compTable, fullfile(outFolder, sprintf('stats_%s.csv', subjectID)));
end

% === Inline ternary helper function ===
function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end

disp('✅ Boxplots with ANOVA and Tukey post-hoc saved.');

disp('✅ Boxplots with ANOVA p-values saved to "box plot with anova" folder.');

% === Load both datasets ===
rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
corrData = readtable(fullfile(rootFolder, 'summary_correlation_values.csv'));
genoList = readtable(fullfile(rootFolder, 'Exp1_sessionList.csv'));

% === Reshape the genotype table into long format ===
AD_sessions = genoList{:, 1};
WT_sessions = genoList{:, 2};

% Remove empty cells and tag genotype
AD_sessions = AD_sessions(~cellfun(@(x) any(isnan(x)), AD_sessions));
WT_sessions = WT_sessions(~cellfun(@(x) any(isnan(x)), WT_sessions));

genoLabels = [repmat({'AD'}, numel(AD_sessions), 1); repmat({'WT'}, numel(WT_sessions), 1)];
sessionStrings = [AD_sessions; WT_sessions];

% Split 'mXXXX_yyyy-mm-dd' into MouseID and Date
splitData = split(sessionStrings, '_');
genoTable = table;
genoTable.MouseID = splitData(:,1);
genoTable.Date = splitData(:,2);
genoTable.Genotype = genoLabels;

% === Merge with correlation summary table ===
% Convert date format if needed
corrData.Date = string(corrData.Date);
genoTable.Date = string(genoTable.Date);

% Merge based on MouseID and Date
mergedData = innerjoin(corrData, genoTable, 'Keys', {'MouseID', 'Date'});

% Save merged data
writetable(mergedData, fullfile(rootFolder, 'merged_correlation_with_genotype.csv'));
disp('✅ Merged table with genotype saved.');

% === Set up paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
inFile = fullfile(rootFolder, 'merged_summary_correlation_values.csv');
outFolder = fullfile(rootFolder, 'ad_vs_wt_correlation');
plotFolder = fullfile(outFolder, 'boxplots_with_stars');

if ~exist(outFolder, 'dir'), mkdir(outFolder); end
if ~exist(plotFolder, 'dir'), mkdir(plotFolder); end

% === Load data ===
T = readtable(inFile);

% === Metrics to test ===
metrics = {'MorningCorr', 'AfternoonCorr', 'MorningAfternoonCorr'};
results = [];

% === Loop through each metric ===
for i = 1:length(metrics)
    metric = metrics{i};
    ad_vals = T{strcmp(T.Genotype, 'AD'), metric};
    wt_vals = T{strcmp(T.Genotype, 'WT'), metric};
    
    [~, p, ~, stats] = ttest2(ad_vals, wt_vals);

    % Get significance label
    if p < 0.001
        sig = '***';
    elseif p < 0.01
        sig = '**';
    elseif p < 0.05
        sig = '*';
    else
        sig = 'ns';
    end

    % Store stats
    results = [results; 
        {metric, mean(wt_vals), mean(ad_vals), stats.tstat, p, sig}];

    % === Generate boxplot with star ===
    figure('Visible', 'off');
    boxplot(T.(metric), T.Genotype);
    title(sprintf('%s by Genotype (p = %.4f)', metric, p), 'FontSize', 12);
    ylabel(metric);
    set(gca, 'FontSize', 11);

    % Add significance line and star
    y = max(T.(metric)) * 1.05;
    line([1 1 2 2], [y y+0.02 y+0.02 y], 'Color', 'k');
    text(1.5, y+0.03, sig, 'HorizontalAlignment', 'center', 'FontSize', 14);

    saveas(gcf, fullfile(plotFolder, ['boxplot_' metric '.png']));
    close(gcf);
end

% === Save results table ===
statsTable = cell2table(results, ...
    'VariableNames', {'Metric', 'WT_Mean', 'AD_Mean', 't_stat', 'p_value', 'Significance'});
writetable(statsTable, fullfile(outFolder, 'ad_vs_wt_ttest_results.csv'));

disp('✅ T-tests and boxplots saved to "ad_vs_wt_correlation" folder.');
