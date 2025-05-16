rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% Load CSV
T = readtable(csvFile);
morningCorr = nan(height(T), 1);
afternoonCorr = nan(height(T), 1);

for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = num2str(T.Date(i));
    
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontail', 'meanAfternoonCorr.mat');

    % === Morning ===
    fprintf('\n[%d] Mouse: %s | Date: %s\n', i, mouseID, dateStr);
    fprintf('Checking: %s\n', morningFile);
    
    if exist(morningFile, 'file')
        s = load(morningFile);
        varNames = fieldnames(s);
        fprintf(' → Found variable: %s\n', varNames{1});
        val = s.(varNames{1});
        if isscalar(val)
            morningCorr(i) = val;
            fprintf(' ✓ Value: %.4f\n', val);
        else
            fprintf(' ✗ Non-scalar value inside: %s\n', morningFile);
        end
    else
        fprintf(' ✗ Missing file: %s\n', morningFile);
    end

    % === Afternoon ===
    fprintf('Checking: %s\n', afternoonFile);
    
    if exist(afternoonFile, 'file')
        s = load(afternoonFile);
        varNames = fieldnames(s);
        fprintf(' → Found variable: %s\n', varNames{1});
        val = s.(varNames{1});
        if isscalar(val)
            afternoonCorr(i) = val;
            fprintf(' ✓ Value: %.4f\n', val);
        else
            fprintf(' ✗ Non-scalar value inside: %s\n', afternoonFile);
        end
    else
        fprintf(' ✗ Missing file: %s\n', afternoonFile);
    end
end

% Attach to table and save
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;
outputPath = fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv');
writetable(T, outputPath);

fprintf('\n✅ DONE: Saved to %s\n', outputPath);
clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows
