% === Set up paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% === Step 1: Load and split raw CSV ===
raw = readtable(csvFile, 'ReadVariableNames', false);  % Comes in as 1 col: allcorrvalues
splitData = split(raw{:,1}, ',');  % Split by comma
flatData = vertcat(splitData{:});  % Flatten nested cells into clean rows

% === Step 2: Build proper table ===
T = table(flatData(:,1), flatData(:,2), str2double(flatData(:,3)), ...
    'VariableNames', {'MouseID', 'Date', 'MeanCorrValue'});

% === Step 3: Initialize new columns ===
morningCorr = nan(height(T), 1);
afternoonCorr = nan(height(T), 1);

% === Step 4: Loop through each row ===
for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = T.Date{i};
    
    % Build base path for this entry
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);
    
    % Target .mat file paths
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontrail', 'meanAfternoonCorr.mat');

    % Load morning value
    if exist(morningFile, 'file')
        data = load(morningFile);
        val = struct2array(data);
        if isscalar(val)
            morningCorr(i) = val;
        else
            warning('Non-scalar value in: %s', morningFile);
        end
    else
        warning('Missing morning file: %s', morningFile);
    end

    % Load afternoon value
    if exist(afternoonFile, 'file')
        data = load(afternoonFile);
        val = struct2array(data);
        if isscalar(val)
            afternoonCorr(i) = val;
        else
            warning('Non-scalar value in: %s', afternoonFile);
        end
    else
        warning('Missing afternoon file: %s', afternoonFile);
    end
end

% === Step 5: Append and export ===
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

outputFile = fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv');
writetable(T, outputFile);

disp('✅ DONE! Table saved with morning and afternoon correlation values.');

clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows
