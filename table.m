% === Set up paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% === Fix CSV loading ===
raw = readtable(csvFile, 'ReadVariableNames', false);  % one-column table
data = split(raw{:,1}, ',');  % split single string column into actual values

% === Create proper table ===
T = table(data(:,1), data(:,2), str2double(data(:,3)), ...
    'VariableNames', {'MouseID', 'Date', 'MeanCorrValue'});

% === Initialize new columns ===
morningCorr = nan(height(T), 1);
afternoonCorr = nan(height(T), 1);

% === Loop through each row ===
for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = T.Date{i};
    
    % Path to the day's folder
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);
    
    % File paths
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontrail', 'meanAfternoonCorr.mat');
    
    % Load morning
    if exist(morningFile, 'file')
        data = load(morningFile);
        val = struct2array(data);
        if isscalar(val)
            morningCorr(i) = val;
        else
            warning('Non-scalar value in: %s', morningFile);
        end
    else
        warning('Missing file: %s', morningFile);
    end
    
    % Load afternoon
    if exist(afternoonFile, 'file')
        data = load(afternoonFile);
        val = struct2array(data);
        if isscalar(val)
            afternoonCorr(i) = val;
        else
            warning('Non-scalar value in: %s', afternoonFile);
        end
    else
        warning('Missing file: %s', afternoonFile);
    end
end

% === Append new columns ===
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

% === Save the final table ===
outputFile = fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv');
writetable(T, outputFile);
disp('✅ Done! Final table saved with morning and afternoon correlation values.');

clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows
