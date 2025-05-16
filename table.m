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

fprintf('\n✅ DONE! Final saved to: %s\n', outputFile);
clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows

% Load table
T = readtable('/home/barrylab/Documents/Giana/Data/all_corr_values_with_morning_afternoon.csv');

% Ensure consistent formatting
T.MouseID = string(T.MouseID);

% Get unique mice
mice = unique(T.MouseID);

% Preallocate
meanMorning = zeros(numel(mice), 1);
meanAfternoon = zeros(numel(mice), 1);
meanFullDay = zeros(numel(mice), 1);

% Calculate mean per mouse
for i = 1:numel(mice)
    mouse = mice(i);
    rows = T.MouseID == mouse;

    meanMorning(i) = mean(T.MorningCorr(rows), 'omitnan');
    meanAfternoon(i) = mean(T.AfternoonCorr(rows), 'omitnan');
    meanFullDay(i) = mean(T.MeanCorrValue(rows), 'omitnan');
end

% Stack into long format
x = [repmat(1, numel(mice), 1); repmat(2, numel(mice), 1); repmat(3, numel(mice), 1)];
y = [meanMorning; meanAfternoon; meanFullDay];

% Plot
figure;
scatter(x, y, 40, 'filled', 'MarkerFaceAlpha', 0.7)
xticks([1 2 3])
xticklabels({'Morning', 'Afternoon', 'Full Day'})
xlabel('Session Type')
ylabel('Mean Correlation per Mouse')
title('Each Dot = One Mouse''s Mean Correlation')
grid on

% Load table
T = readtable('/home/barrylab/Documents/Giana/Data/all_corr_values_with_morning_afternoon.csv');
T.MouseID = string(T.MouseID);
mice = unique(T.MouseID);

% Collect mean correlations
meanMorning = zeros(numel(mice), 1);
meanAfternoon = zeros(numel(mice), 1);
meanFullDay = zeros(numel(mice), 1);

for i = 1:numel(mice)
    mouse = mice(i);
    rows = T.MouseID == mouse;

    meanMorning(i) = mean(T.MorningCorr(rows), 'omitnan');
    meanAfternoon(i) = mean(T.AfternoonCorr(rows), 'omitnan');
    meanFullDay(i) = mean(T.MeanCorrValue(rows), 'omitnan');
end

% Stack into long format
y = [meanMorning; meanAfternoon; meanFullDay];
session = [repmat("Morning", numel(mice), 1);
           repmat("Afternoon", numel(mice), 1);
           repmat("Full Day", numel(mice), 1)];

% Plot violin + scatter
figure;
violinplot(y, session);
hold on;
scatter(double(session), y, 30, 'filled', 'MarkerFaceAlpha', 0.5)
hold off;

ylabel('Mean Correlation per Mouse')
title('Distribution of Place Cell Stability Across Morning, Afternoon, and Full-Day Sessions')
grid on
