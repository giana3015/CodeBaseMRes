clc; clear; close all;

% === CONFIGURATION ===
rootFolder = '/home/barrylab/Documents/Giana/Data';
binSize_cm = 2;
threshold_frac = 0.3;
outputCSV = fullfile(rootFolder, 'place_field_metrics_all_mice.csv');

% === FIND ALL PC_ratemaps FOLDERS ===
folders = dir(fullfile(rootFolder, 'm*', '2*', 'PC_ratemaps'));
fprintf('🔍 Found %d PC_ratemaps folders.\n', length(folders));

allRows = {};

for k = 1:length(folders)
    pcFolder = fullfile(folders(k).folder, folders(k).name);
    [~, dateStr] = fileparts(folders(k).folder);                     % folder above PC_ratemaps
    [~, mouseID] = fileparts(fileparts(folders(k).folder));          % folder above that = mXXXX

    files = dir(fullfile(pcFolder, 'ratemap*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % ✅ EXTRACT cell/trial numbers
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
            continue;
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});

        % === COMPUTE METRICS ===
        if isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid ratemap: %s', fileName);
            peak = NaN;
            fieldSize = NaN;
        else
            peak = max(ratemap(:), [], 'omitnan');
            thresh = threshold_frac * peak;
            binaryField = ratemap > thresh;
            binaryField = bwareaopen(binaryField, 5);
            nBins = sum(binaryField(:));
            fieldSize = nBins * binSize_cm^2;
        end

        % ✅ APPEND ROW
        allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ Combined master CSV saved to:\n%s\n', outputCSV);
