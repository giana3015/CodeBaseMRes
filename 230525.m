% === Configuration ===
cellID = 2;  % Adjust this for different cells
rootFolder = '/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps';
outputFile = fullfile(rootFolder, sprintf('peak_tracking_cell%02d.csv', cellID));

% === Initialize results ===
results = [];

% === Loop over trials ===
for trial = 1:10
    fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
    filePath = fullfile(rootFolder, fileName);

    if ~isfile(filePath)
        fprintf('⚠️ File not found: %s\n', fileName);
        continue;
    end

    % Load file
    raw = load(filePath);
    vars = fieldnames(raw);
    
    if isempty(vars)
        fprintf('⚠️ No variables in: %s\n', fileName);
        continue;
    end

    ratemap = raw.(vars{1});  % Avoid dot notation

    if isempty(ratemap) || all(isnan(ratemap(:)))
        fprintf('⚠️ Empty or invalid ratemap in: %s\n', fileName);
        continue;
    end

    % Find peak
    [~, idx] = max(ratemap(:));
    [peakY, peakX] = ind2sub(size(ratemap), idx);

    % Store
    results(end+1, :) = [trial, peakX, peakY];
end

% Save to CSV
fid = fopen(outputFile, 'w');
fprintf(fid, 'Trial,Peak_X,Peak_Y\n');
for i = 1:size(results, 1)
    fprintf(fid, '%d,%d,%d\n', results(i,1), results(i,2), results(i,3));
end
fclose(fid);

fprintf('✅ Peak positions saved to: %s\n', outputFile);

% === Configuration ===
cellID = 2;  % Adjust this for different cells
rootFolder = '/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps';
outputFile = fullfile(rootFolder, sprintf('peak_tracking_cell%02d.csv', cellID));

% === Initialize results ===
results = [];

% === Variables to store reference (trial 1) peak ===
refX = NaN;
refY = NaN;

% === Loop over trials ===
for trial = 1:10
    fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
    filePath = fullfile(rootFolder, fileName);

    if ~isfile(filePath)
        fprintf('⚠️ File not found: %s\n', fileName);
        continue;
    end

    raw = load(filePath);
    vars = fieldnames(raw);
    
    if isempty(vars)
        fprintf('⚠️ No variables in: %s\n', fileName);
        continue;
    end

    ratemap = raw.(vars{1});

    if isempty(ratemap) || all(isnan(ratemap(:)))
        fprintf('⚠️ Empty or invalid ratemap in: %s\n', fileName);
        continue;
    end

    % Find peak position
    [~, idx] = max(ratemap(:));
    [peakY, peakX] = ind2sub(size(ratemap), idx);

    % If trial 1, store reference peak
    if trial == 1
        refX = peakX;
        refY = peakY;
        dist = 0;
    else
        dist = sqrt((peakX - refX)^2 + (peakY - refY)^2);
    end

    results(end+1, :) = [trial, peakX, peakY, dist];
end

% === Save to CSV ===
fid = fopen(outputFile, 'w');
fprintf(fid, 'Trial,Peak_X,Peak_Y,Distance_from_Trial1\n');
for i = 1:size(results, 1)
    fprintf(fid, '%d,%d,%d,%.4f\n', results(i,1), results(i,2), results(i,3), results(i,4));
end
fclose(fid);

fprintf('✅ Peak tracking with distances saved to: %s\n', outputFile);

clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
dateStr = '20200924';
folderPath = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
outputCSV = fullfile(folderPath, sprintf('%s_%s_peak_drift_all_cells.csv', mouseID, dateStr));

% === FIND all matching .mat files ===
files = dir(fullfile(folderPath, 'ratemap_cell*_trial*.mat'));
fprintf('🔍 Found %d ratemap files in %s\n', length(files), folderPath);

% === GROUP BY CELL ===
allCellIDs = [];
for f = 1:length(files)
    name = files(f).name;
    tokens = regexp(name, 'ratemap_cell(\d+)_trial(\d+).mat', 'tokens', 'once');
    if ~isempty(tokens)
        allCellIDs(end+1) = str2double(tokens{1});
    end
end
cellList = unique(allCellIDs);

% === INITIALIZE RESULT STORAGE ===
allRows = {};

% === PROCESS EACH CELL ===
for i = 1:length(cellList)
    cellID = cellList(i);
    trialPeaks = nan(10, 2);  % store (X, Y) for trials 1–10

    for trial = 1:10
        fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
        filePath = fullfile(folderPath, fileName);

        if ~isfile(filePath)
            fprintf('⏭️ Skipping missing: %s\n', fileName);
            continue;
        end

        % Load ratemap
        S = load(filePath);
        varnames = fieldnames(S);
        ratemap = S.(varnames{1});

        if isempty(ratemap) || all(isnan(ratemap(:)))
            fprintf('⚠️ Invalid map in: %s\n', fileName);
            continue;
        end

        % Find peak (X, Y)
        [~, idx] = max(ratemap(:));
        [peakY, peakX] = ind2sub(size(ratemap), idx);
        trialPeaks(trial, :) = [peakX, peakY];
    end

    % Calculate distance from trial 1
    refX = trialPeaks(1,1);
    refY = trialPeaks(1,2);

    for trial = 1:10
        px = trialPeaks(trial, 1);
        py = trialPeaks(trial, 2);

        if isnan(px) || isnan(refX)
            dist = NaN;
        else
            dist = sqrt((px - refX)^2 + (py - refY)^2);
        end

        allRows{end+1,1} = {mouseID, dateStr, cellID, trial, px, py, dist};
    end
end

% === WRITE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,CellID,Trial,Peak_X,Peak_Y,Distance_from_Trial1\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%d,%d,%g,%g,%.4f\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ Full CSV saved to:\n%s\n', outputCSV);
