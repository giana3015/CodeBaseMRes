clc; clear; close all;

% === CONFIGURATION ===
rootFolder = '/home/barrylab/Documents/Giana/Data';
binSize_cm = 2;             % Bin size in cm
threshold_frac = 0.3;       % Threshold for place field detection
outputCSV = fullfile(rootFolder, 'place_field_metrics_all_mice.csv');

% === FIND ALL PC_ratemaps FOLDERS ===
folders = dir(fullfile(rootFolder, 'm*', '2*', 'PC_ratemaps'));
fprintf('🔍 Found %d PC_ratemaps folders.\n', length(folders));

allRows = {};

for k = 1:length(folders)
    pcFolder = fullfile(folders(k).folder, folders(k).name);

    % ✅ CORRECTLY EXTRACT MouseID and Date from path
    splitPath = split(pcFolder, filesep);
    if length(splitPath) < 3
        warning('⚠️ Unexpected folder structure: %s', pcFolder);
        continue;
    end
    mouseID = splitPath{end-2};    % e.g. 'm4005'
    dateStr = splitPath{end-1};    % e.g. '20200924'

    % ✅ LOAD all matching ratemap files
    files = dir(fullfile(pcFolder, 'ratemap_cell*_trial*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % === EXTRACT Cell and Trial numbers ===
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
            continue;
        end
        cellNum = str2double(tokens{1});
        trialNum = str2double(tokens{2});

        % === LOAD RATEMAP from .mat ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % Assumes first variable is the ratemap matrix

        % === SANITY CHECK ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid ratemap: %s', fileName);
            continue;
        end

        % === COMPUTE METRICS ===
        peak = max(ratemap(:), [], 'omitnan');
        thresh = threshold_frac * peak;
        binaryField = ratemap > thresh;
        binaryField = bwareaopen(binaryField, 5);  % remove tiny noisy regions
        nBins = sum(binaryField(:));
        fieldSize = nBins * binSize_cm^2;

        % === STORE ROW ===
        allRows(end+1, :) = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === WRITE OUTPUT CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:size(allRows, 1)
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        allRows{i,1}, allRows{i,2}, allRows{i,3}, allRows{i,4}, ...
        allRows{i,5}, allRows{i,6}, allRows{i,7});
end

fclose(fid);
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);
