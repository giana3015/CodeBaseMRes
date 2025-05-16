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

% === Load your CSV ===
T = readtable('/home/barrylab/Documents/Giana/Data/all_corr_values_with_morning_afternoon.csv');

% === Group by MouseID ===
G = findgroups(T.MouseID);

% === Compute mean values per mouse ===
mice = unique(T.MouseID);
meanMorning = splitapply(@(x) mean(x, 'omitnan'), T.MorningCorr, G);
meanAfternoon = splitapply(@(x) mean(x, 'omitnan'), T.AfternoonCorr, G);
meanFullDay = splitapply(@(x) mean(x, 'omitnan'), T.MeanCorrValue, G);

% === Stack values for scatter ===
% Each mouse gets 3 values: [Morning, Afternoon, FullDay]
xLabels = {'Morning', 'Afternoon', 'Full Day'};
x = repelem(1:3, numel(mice))';  % 1,1,1,2,2,2,...
y = [meanMorning; meanAfternoon; meanFullDay];
y = y(:);

% === Mouse grouping (to color-code) ===
mouseGroup = repelem(1:numel(mice), 3)';

% === Plot ===
figure;
gscatter(x, y, mouseGroup, [], [], 12);
xticks(1:3);
xticklabels(xLabels);
xlabel('Session Type');
ylabel('Mean Correlation');
title('Mouse-wise Mean Correlation per Session Type');
grid on;
