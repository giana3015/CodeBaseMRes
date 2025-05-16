% === Set up paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% === Step 1: Read CSV properly ===
T = readtable(csvFile);

% Confirm expected variables exist
if ~all(ismember({'MouseID', 'Date', 'MeanCorrValue'}, T.Properties.VariableNames))
    error('CSV file does not have required columns: MouseID, Date, MeanCorrValue');
end

% === Step 2: Initialize result columns ===
morningCorr = nan(height(T), 1);
afternoonCorr = nan(height(T), 1);

% === Step 3: Loop through rows and extract values ===
for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = num2str(T.Date(i));  % ensure string format

    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);

    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontail', 'meanAfternoonCorr.mat');

    % Load morning if available
    if exist(morningFile, 'file')
        mData = load(morningFile);
        val = struct2array(mData);
        if isscalar(val)
            morningCorr(i) = val;
        else
            warning('Non-scalar in %s', morningFile);
        end
    else
        warning('Missing file: %s', morningFile);
    end

    % Load afternoon if available
    if exist(afternoonFile, 'file')
        aData = load(afternoonFile);
        val = struct2array(aData);
        if isscalar(val)
            afternoonCorr(i) = val;
        else
            warning('Non-scalar in %s', afternoonFile);
        end
    else
        warning('Missing file: %s', afternoonFile);
    end
end

% === Step 4: Append columns and export ===
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

% Save
outputPath = fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv');
writetable(T, outputPath);
disp('✅ DONE — correlation values updated and saved.');

clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows
