% === Define base directories ===
baseDataPath = '/Users/gianalee/Desktop/sarah''s data/Data/';
sourceBase = fullfile(baseDataPath);  % where all mxxxx folders are
destBase = fullfile(baseDataPath, 'correlation matrix');

% === Get all mouse folders that start with 'm' ===
mouseFolders = dir(sourceBase);
mouseFolders = mouseFolders([mouseFolders.isdir] & startsWith({mouseFolders.name}, 'm'));

for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(sourceBase, mouseID);
    
    % Get all date folders inside this mouse folder
    dayFolders = dir(mousePath);
    dayFolders = dayFolders([dayFolders.isdir] & ~startsWith({dayFolders.name}, '.'));

    for j = 1:length(dayFolders)
        dayName = dayFolders(j).name;
        dayPath = fullfile(mousePath, dayName);
        
        % Define source files
        groupCorrFile = fullfile(dayPath, 'groupCorrMatrix.mat');
        meanCorrFile = fullfile(dayPath, 'meanCorrValue.mat');
        pngFile = fullfile(dayPath, 'groupCorrMatrix.png');
        
        % Define destination folder
        destFolder = fullfile(destBase, mouseID);
        if ~exist(destFolder, 'dir')
            mkdir(destFolder);
        end
        
        % Rename and move if exists
        if isfile(groupCorrFile)
            movefile(groupCorrFile, fullfile(destFolder, sprintf('%s.%s.groupCorrMatrix.mat', mouseID, dayName)));
        end
        if isfile(meanCorrFile)
            movefile(meanCorrFile, fullfile(destFolder, sprintf('%s.%s.meanCorrValue.mat', mouseID, dayName)));
        end
        if isfile(pngFile)
            movefile(pngFile, fullfile(destFolder, sprintf('%s.%s.groupCorrMatrix.png', mouseID, dayName)));
        end
    end
end


% === Define base and output folder ===
basePath = '/Users/gianalee/Desktop/sarah''s data/Data/';
outputFolder = fullfile(basePath, 'all_groupCorrMatrix_pngs');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% === Find all mouse folders ===
mouseFolders = dir(basePath);
mouseFolders = mouseFolders([mouseFolders.isdir] & startsWith({mouseFolders.name}, 'm'));

for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(basePath, mouseID);

    % Find date folders inside this mouse folder
    dayFolders = dir(mousePath);
    dayFolders = dayFolders([dayFolders.isdir] & ~startsWith({dayFolders.name}, '.'));

    for j = 1:length(dayFolders)
        dayName = dayFolders(j).name;
        dayPath = fullfile(mousePath, dayName);

        % Define the PNG file path
        pngPath = fullfile(dayPath, 'groupCorrMatrix.png');

        if isfile(pngPath)
            newName = sprintf('%s_%s_groupCorrMatrix.png', mouseID, dayName);
            copyfile(pngPath, fullfile(outputFolder, newName));
        end
    end
end

fprintf('✅ Done extracting and renaming all groupCorrMatrix.png files.\n');
