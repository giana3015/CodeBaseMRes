% === Root directory ===
rootFolder = '/home/barrylab/Documents/Giana/Data/';

% Get list of mouse folders
mouseFolders = dir(fullfile(rootFolder, 'correlation matrix', '*'));
mouseFolders = mouseFolders([mouseFolders.isdir] & ~startsWith({mouseFolders.name}, '.'));

% Initialize storage
mouseIDs = {};
dates = {};
corrValues = [];

% Loop through each mouse folder
for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    folderPath = fullfile(rootFolder, 'correlation matrix', mouseID);
    
    % Get all *.meanCorrValue.mat files
    corrFiles = dir(fullfile(folderPath, '*.meanCorrValue.mat'));
    
    for j = 1:length(corrFiles)
        fileName = corrFiles(j).name;
        filePath = fullfile(folderPath, fileName);
        
        % Load the .mat file
        data = load(filePath);
        fieldNames = fieldnames(data);
        value = data.(fieldNames{1});  % assumes only one variable inside
        
        % Parse date from filename
        parts = split(fileName, '.');
        dateStr = parts{2};  % e.g., 20200924
        
        % Store data
        mouseIDs{end+1} = mouseID;
        dates{end+1} = dateStr;
        corrValues(end+1) = value;
    end
end

% Convert to table
T = table(mouseIDs', dates', corrValues', ...
    'VariableNames', {'MouseID', 'Date', 'MeanCorrValue'});

% Save to .csv
writetable(T, fullfile(rootFolder, 'all_corr_values.csv'));

disp('Done! Correlation values saved to all_corr_values.csv');
