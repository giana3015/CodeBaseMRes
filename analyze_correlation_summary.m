% === Step 1: Extract correlation values per session ===

rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
mouseFolders = dir(fullfile(rootFolder, 'm*'));

results = [];

for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(rootFolder, mouseID);
    
    if ~isfolder(mousePath), continue; end
    
    files = dir(fullfile(mousePath, '*.groupCorrMatrix.mat'));
    
    for j = 1:length(files)
        fileName = files(j).name;
        fullPath = fullfile(mousePath, fileName);
        data = load(fullPath);
        
        % Assume only one variable inside
        f = fieldnames(data);
        corrMat = data.(f{1});
        
        % Check matrix size
        if size(corrMat,1) ~= 10 || size(corrMat,2) ~= 10
            warning("File %s is not 10x10. Skipped.", fileName);
            continue;
        end
        
        % Morning vs Morning (1–5)
        m = corrMat(1:5,1:5);
        maskM = triu(true(5),1);
        meanMorning = mean(m(maskM));
        
        % Afternoon vs Afternoon (6–10)
        a = corrMat(6:10,6:10);
        maskA = triu(true(5),1);
        meanAfternoon = mean(a(maskA));
        
        % Morning vs Afternoon (1–5 vs 6–10)
        ma = corrMat(1:5,6:10);
        meanMorningAfternoon = mean(ma(:));
        
        % Extract date from filename
        tokens = regexp(fileName, '\.(\d{8})\.', 'tokens');
        if isempty(tokens), continue; end
        dateStr = tokens{1}{1};
        
        % Store result
        results = [results; {mouseID, dateStr, meanMorning, meanAfternoon, meanMorningAfternoon}];
    end
end

% Create and save table
T = cell2table(results, ...
    'VariableNames', {'MouseID', 'Date', 'MorningCorr', 'AfternoonCorr', 'MorningAfternoonCorr'});
disp(T);

writetable(T, fullfile(rootFolder, 'summary_correlation_values.csv'));

% === Step 2: ANOVA and Boxplot across all mice ===

% Stack data
allCorrs = [T.MorningCorr; T.AfternoonCorr; T.MorningAfternoonCorr];
labels = [repmat({'Morning'}, height(T), 1); 
          repmat({'Afternoon'}, height(T), 1);
          repmat({'Morning-Afternoon'}, height(T), 1)];

% One-way ANOVA
figure;
[p_all, tbl_all, stats_all] = anova1(allCorrs, labels);
title('ANOVA: All Mice Combined');

% Optional post-hoc
figure;
multcompare(stats_all);
title('Post-hoc Comparison: All Mice');

% Boxplot for all mice
figure;
boxplot(allCorrs, labels);
title('Boxplot: Correlation Comparison Across All Mice');
ylabel('Mean Correlation');

% === Step 3: Per-Mouse ANOVA and Boxplots ===

uniqueMice = unique(T.MouseID);

for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    mouseData = T(strcmp(T.MouseID, mouse), :);
    
    vals = [mouseData.MorningCorr; mouseData.AfternoonCorr; mouseData.MorningAfternoonCorr];
    labs = [repmat({'Morning'}, height(mouseData), 1); 
            repmat({'Afternoon'}, height(mouseData), 1); 
            repmat({'Morning-Afternoon'}, height(mouseData), 1)];
    
    % ANOVA per mouse
    figure;
    [p_mouse, tbl_mouse, stats_mouse] = anova1(vals, labs);
    title(['ANOVA for ' mouse]);

    % Boxplot per mouse
    figure;
    boxplot(vals, labs);
    title(['Boxplot for ' mouse]);
    ylabel('Mean Correlation');
end
