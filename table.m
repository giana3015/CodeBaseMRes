% === Set up paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% Load CSV
T = readtable(csvFile);

% Init result columns
morningCorr = nan(height(T),1);
afternoonCorr = nan(height(T),1);

for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = num2str(T.Date(i));

    % Build correct paths based on screenshot
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontrail', 'meanAfternoonCorr.mat');

    fprintf('\n[%d] Mouse: %s | Date: %s\n', i, mouseID, dateStr);

    % === Morning ===
    if exist(morningFile, 'file')
        m = load(morningFile);
        val = struct2cell(m);
        scalar = val{1};
        if isscalar(scalar)
            morningCorr(i) = scalar;
            fprintf('✓ Morning: %.4f\n', scalar);
        else
            fprintf('⚠️ Non-scalar in: %s\n', morningFile);
        end
    else
        fprintf('❌ Missing morning: %s\n', morningFile);
    end

    % === Afternoon ===
    if exist(afternoonFile, 'file')
        a = load(afternoonFile);
        val = struct2cell(a);
        scalar = val{1};
        if isscalar(scalar)
            afternoonCorr(i) = scalar;
            fprintf('✓ Afternoon: %.4f\n', scalar);
        else
            fprintf('⚠️ Non-scalar in: %s\n', afternoonFile);
        end
    else
        fprintf('❌ Missing afternoon: %s\n', afternoonFile);
    end
end

% Append and save
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

outputFile = fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv');
writetable(T, outputFile);

uniqueMice = unique(T.MouseID);
figure; hold on;

for i = 1:length(uniqueMice)
    mouse = uniqueMice{i};
    subT = T(strcmp(T.MouseID, mouse), :);
    subT = sortrows(subT, 'Date');
    
    plot(subT.Date, subT.MorningCorr, '-o', 'DisplayName', [mouse ' morning']);
    plot(subT.Date, subT.AfternoonCorr, '-x', 'DisplayName', [mouse ' afternoon']);
end

xlabel('Date')
ylabel('Correlation')
title('Time-course of Corr (Morning & Afternoon)')
legend('show', 'Location', 'bestoutside')
grid on

% Save current figure as PNG
saveas(gcf, fullfile(rootFolder, 'place_cell_stability_boxplot.png'));

fprintf('\n✅ DONE! Final saved to: %s\n', outputFile);
clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows


% Load your data
T = readtable('/home/barrylab/Documents/Giana/Data/all_corr_values_with_morning_afternoon.csv');
T.MouseID = string(T.MouseID);
mice = unique(T.MouseID);

% Compute mean per mouse
meanMorning = zeros(numel(mice),1);
meanAfternoon = zeros(numel(mice),1);
meanFullDay = zeros(numel(mice),1);

for i = 1:numel(mice)
    idx = T.MouseID == mice(i);
    meanMorning(i) = mean(T.MorningCorr(idx), 'omitnan');
    meanAfternoon(i) = mean(T.AfternoonCorr(idx), 'omitnan');
    meanFullDay(i) = mean(T.MeanCorrValue(idx), 'omitnan');
end

% Stack into long format
y = [meanMorning; meanAfternoon; meanFullDay];
group = [repmat("Morning", numel(mice), 1);
         repmat("Afternoon", numel(mice), 1);
         repmat("Full Day", numel(mice), 1)];

% === Plot boxplot with scatter ===
figure;
boxplot(y, group);
hold on;
scatter(double(categorical(group)), y, 30, 'filled', 'MarkerFaceAlpha', 0.4)
hold off;

ylabel('Mean Correlation per Mouse')
title('Place Cell Stability Across Morning, Afternoon, and Full-Day Sessions')
grid on

% === Set paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
outputMorning = fullfile(rootFolder, 'grouped morning trail png');
outputAfternoon = fullfile(rootFolder, 'grouped afternoon trail png');

% === Create folders if they don't exist ===
if ~exist(outputMorning, 'dir')
    mkdir(outputMorning);
end
if ~exist(outputAfternoon, 'dir')
    mkdir(outputAfternoon);
end

% === Get all m**** mouse folders ===
mouseFolders = dir(fullfile(rootFolder, 'correlation matrix', 'm*'));

% === Loop through each mouse folder ===
for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(mouseFolders(i).folder, mouseID);
    
    % Get all date folders under this mouse
    dateFolders = dir(fullfile(mousePath, '2020*'));
    
    for j = 1:length(dateFolders)
        dateStr = dateFolders(j).name;
        datePath = fullfile(dateFolders(j).folder, dateStr);
        
        % === Build expected PNG paths ===
        morningPNG = fullfile(datePath, 'grouped morningtrail', 'groupMorningCorrMatrix.png');
        afternoonPNG = fullfile(datePath, 'grouped afternoontail', 'groupAfternoonCorrMatrix.png');

        % === Copy if exists ===
        if exist(morningPNG, 'file')
            newName = sprintf('%s_%s_grouped_morning.png', mouseID, dateStr);
            copyfile(morningPNG, fullfile(outputMorning, newName));
        end

        if exist(afternoonPNG, 'file')
            newName = sprintf('%s_%s_grouped_afternoon.png', mouseID, dateStr);
            copyfile(afternoonPNG, fullfile(outputAfternoon, newName));
        end
    end
end

disp('✅ All PNGs copied and renamed!');

% Load the data
T = readtable('/home/barrylab/Documents/Giana/Data/all_corr_values_with_morning_afternoon.csv');
T.MouseID = string(T.MouseID);
uniqueMice = unique(T.MouseID);

% Initialize figure
figure;
hold on;

% For each mouse, compute mean Morning and Afternoon
for i = 1:numel(uniqueMice)
    mouse = uniqueMice(i);
    idx = T.MouseID == mouse;

    % Get per-mouse mean
    m = mean(T.MorningCorr(idx), 'omitnan');
    a = mean(T.AfternoonCorr(idx), 'omitnan');

    % Plot the line for this mouse
    plot([1, 2], [m, a], '-o', 'Color', [0.4 0.4 0.8 0.4], 'MarkerSize', 5);
end

% Format the plot
xlim([0.8 2.2])
xticks([1 2])
xticklabels({'Morning', 'Afternoon'})
ylabel('Mean Correlation')
title('Per-Mouse Correlation Trend: Morning to Afternoon')
grid on
