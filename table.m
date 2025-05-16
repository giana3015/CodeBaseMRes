% Load existing table
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');
T = readtable(csvFile);

% Initialize new columns
morningCorr = nan(height(T), 1);
afternoonCorr = nan(height(T), 1);

% Loop over rows to fill in morning and afternoon values
for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = T.Date{i};
    
    % Construct path to the day's folder
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);
    
    % Paths to morning and afternoon mat files
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontrail', 'meanAfternoonCorr.mat');
    
    % Load if file exists and assign
    if exist(morningFile, 'file')
        data = load(morningFile);
        morningCorr(i) = data.(fieldnames(data){1});
    end
    if exist(afternoonFile, 'file')
        data = load(afternoonFile);
        afternoonCorr(i) = data.(fieldnames(data){1});
    end
end

% Append columns to table
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

% Save updated table
writetable(T, fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv'));
disp('Done! File saved with morning and afternoon correlation values.');
