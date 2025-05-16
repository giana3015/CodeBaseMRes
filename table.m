% === Set up ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% Load the main table
T = readtable(csvFile);

% Initialize columns
morningCorr = nan(height(T),1);
afternoonCorr = nan(height(T),1);

% Loop through each mouse-date entry
for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = num2str(T.Date(i));  % Ensure it's string format
    
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);
    
    % Build file paths
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontail', 'meanAfternoonCorr.mat');

    % === Load morning ===
    if exist(morningFile, 'file')
        s = load(morningFile);  % Load struct
        val = struct2cell(s);   % Convert to cell
        scalarVal = val{1};     % Extract scalar
        if isscalar(scalarVal)
            morningCorr(i) = scalarVal;
        else
            warning('Non-scalar value in: %s', morningFile);
        end
    else
        warning('Missing morning file: %s', morningFile);
    end

    % === Load afternoon ===
    if exist(afternoonFile, 'file')
        s = load(afternoonFile);
        val = struct2cell(s);
        scalarVal = val{1};
        if isscalar(scalarVal)
            afternoonCorr(i) = scalarVal;
        else
            warning('Non-scalar value in: %s', afternoonFile);
        end
    else
        warning('Missing afternoon file: %s', afternoonFile);
    end
end

% Append
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

% Save result
writetable(T, fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv'));
disp('✅ Done! Final table saved with morning and afternoon correlation values.');

clc;                % Clear Command Window
clearvars;          % Clear all variables
close all;          % Close all figure windows
