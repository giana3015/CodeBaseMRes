% === Set up paths ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';
csvFile = fullfile(rootFolder, 'all_corr_values.csv');

% Load existing table
T = readtable(csvFile);

% Initialize new columns
morningCorr = nan(height(T), 1);
afternoonCorr = nan(height(T), 1);

% Loop through each mouse-date entry
for i = 1:height(T)
    mouseID = T.MouseID{i};
    dateStr = T.Date{i};

    % Construct base path for this entry
    basePath = fullfile(rootFolder, 'correlation matrix', mouseID, dateStr);

    % Define paths to morning and afternoon files
    morningFile = fullfile(basePath, 'grouped morningtrail', 'meanMorningCorr.mat');
    afternoonFile = fullfile(basePath, 'grouped afternoontrail', 'meanAfternoonCorr.mat');

    % Load and assign morning value
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

    % Load and assign afternoon value
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

% Append to table
T.MorningCorr = morningCorr;
T.AfternoonCorr = afternoonCorr;

% Save updated table
outputFile = fullfile(rootFolder, 'all_corr_values_with_morning_afternoon.csv');
writetable(T, outputFile);

disp('✅ Done! File saved with morning and afternoon correlation values.');
