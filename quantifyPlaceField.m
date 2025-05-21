clc; clear; close all;

% === CONFIGURATION ===
filename = 'your_ratemap_file.mat';   % CHANGE THIS to your actual file name
ratemap_var = 'ratemap';              % CHANGE this if your variable is named differently
binSize_cm = 2;                       % spatial bin size (e.g. 2cm × 2cm)
threshold_frac = 0.3;                 % 30% of peak firing

% === LOAD RATEMAP ===
data = load(filename);
if isfield(data, ratemap_var)
    ratemap = data.(ratemap_var);
else
    error('Could not find variable "%s" in file.', ratemap_var);
end

% === PLACE FIELD ANALYSIS ===
peakRate = max(ratemap(:), [], 'omitnan');
threshold = threshold_frac * peakRate;
binaryField = ratemap > threshold;

% Optional: clean up small noise regions (<5 bins)
binaryField = bwareaopen(binaryField, 5);

% Place field size = number of bins × bin area
nBins = sum(binaryField(:));
fieldSize_cm2 = nBins * (binSize_cm^2);

% === PRINT RESULTS ===
fprintf('Peak firing rate: %.2f Hz\n', peakRate);
fprintf('Threshold (%.0f%% of peak): %.2f Hz\n', threshold_frac*100, threshold);
fprintf('Place field size: %.2f cm² (%d bins)\n', fieldSize_cm2, nBins);

% === PLOT RESULTS ===
figure;
subplot(1,2,1);
imagesc(ratemap); axis image; colorbar;
title(sprintf('Ratemap (Peak: %.2f Hz)', peakRate));

subplot(1,2,2);
imagesc(binaryField); axis image;
title(sprintf('Place Field (>%.0f%% Peak)', threshold_frac*100));


clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
dateStr = '20200924';
pcRatemapFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
binSize_cm = 2;
threshold_frac = 0.3;

% === GET ALL .mat FILES IN PC_ratemaps ===
files = dir(fullfile(pcRatemapFolder, '*.mat'));
fprintf('🔍 Found %d files in %s\n', length(files), pcRatemapFolder);

allRows = {};

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);
    fileName = files(f).name;

    % Try to extract cell/trial numbers if possible
    tokens = regexp(fileName, 'cell(\d+)_trail(\d+)', 'tokens');
    if isempty(tokens)
        cellNum = NaN;
        trialNum = NaN;
    else
        cellNum = str2double(tokens{1}{1});
        trialNum = str2double(tokens{1}{2});
    end

    % Load ratemap
    S = load(filePath);
    vars = fieldnames(S);
    ratemap = S.(vars{1});

    % Compute peak rate and place field size
    if isempty(ratemap) || all(isnan(ratemap(:)))
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

    % Append row
    allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === FINAL OUTPUT ===
if isempty(allRows)
    error('❌ No valid ratemaps found in PC_ratemaps folder.');
end

T = cell2table(vertcat(allRows{:}), ...
    'VariableNames', {'MouseID', 'Date', 'Cell', 'Trial', 'PeakRate_Hz', 'FieldSize_cm2', 'FileName'});

% Save

clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
dateStr = '20200924';
binSize_cm = 2;
threshold_frac = 0.3;

% === PATH TO RATEMAPS ===
pcRatemapFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
outCSV = fullfile(pcRatemapFolder, sprintf('%s_%s_place_fields.csv', mouseID, dateStr));

% === GET ALL .mat FILES IN THE PC_ratemaps FOLDER ===
files = dir(fullfile(pcRatemapFolder, '*.mat'));
fprintf('🔍 Found %d .mat files in %s\n', length(files), pcRatemapFolder);

% === PREPARE TO COLLECT RESULTS ===
allRows = {};

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);
    fileName = files(f).name;

    % Try to extract cell and trial numbers from filename
    tokens = regexp(fileName, 'cell(\d+)_trail(\d+)', 'tokens');
    if isempty(tokens)
        warning('⚠️ Skipping unparseable file: %s', fileName);
        cellNum = NaN;
        trialNum = NaN;
    else
        cellNum = str2double(tokens{1}{1});
        trialNum = str2double(tokens{1}{2});
    end

    % Load ratemap
    S = load(filePath);
    vars = fieldnames(S);
    ratemap = S.(vars{1});  % assumes 1 variable per .mat file

    % Compute peak and field size
    if isempty(ratemap) || all(isnan(ratemap(:)))
        peak = NaN;
        fieldSize = NaN;
    else
        peak = max(ratemap(:), [], 'omitnan');
        thresh = threshold_frac * peak;
        binaryField = ratemap > thresh;
        binaryField = bwareaopen(binaryField, 5);  % remove small specks
        nBins = sum(binaryField(:));
        fieldSize = nBins * binSize_cm^2;
    end

    % Store result row
    allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === SAVE TO CSV USING fprintf (no cell2table, no T) ===
if isempty(allRows)
    error('❌ No valid ratemaps processed.');
end

fid = fopen(outCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);

fprintf('\n✅ CSV saved to:\n%s\n', outCSV);

clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
dateStr = '20200924';
binSize_cm = 2;
threshold_frac = 0.3;

pcRatemapFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
outCSV = fullfile(pcRatemapFolder, sprintf('%s_%s_place_fields.csv', mouseID, dateStr));

% === FIND ALL FILES STARTING WITH "ratemap" ===
files = dir(fullfile(pcRatemapFolder, 'ratemap*.mat'));
fprintf('🔍 Found %d ratemap files in %s\n', length(files), pcRatemapFolder);

allRows = {};

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);
    fileName = files(f).name;

    % Assign fallback CellID = file index
    cellNum = f;
    trialNum = NaN;

    % Load ratemap
    S = load(filePath);
    vars = fieldnames(S);
    ratemap = S.(vars{1});  % assumes single variable inside

    % Compute peak rate and place field size
    if isempty(ratemap) || all(isnan(ratemap(:)))
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

    % Store row
    allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === SAVE TO CSV ===
fid = fopen(outCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);

fprintf('\n✅ CSV written to:\n%s\n', outCSV);

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
    [~, dateStr] = fileparts(folders(k).folder);        % folder above PC_ratemaps
    [~, mouseID] = fileparts(fileparts(folders(k).folder)); % one level up = mXXXX

    files = dir(fullfile(pcFolder, 'ratemap*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % fallback IDs
        cellNum = f;
        trialNum = NaN;

        % Load ratemap
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});

        % Compute
        if isempty(ratemap) || all(isnan(ratemap(:)))
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

        % Append row
        allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE FINAL CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);

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

        % fallback IDs
        cellNum = f;
        trialNum = NaN;

        % Load ratemap
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes only 1 variable per file

        % === Validate and compute ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % Append row
        allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV (manually with fprintf) ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);

fprintf('\n✅ Master CSV written to:\n%s\n', outputCSV);

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

        % === TRY TO EXTRACT CELL/TRIAL FROM FILENAME ===
        tokens = regexp(fileName, 'cell(\d+)[_]?trail(\d+)', 'tokens', 'once');
        if isempty(tokens)
            cellNum = f;       % fallback to file index
            trialNum = NaN;
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes only 1 variable per file

        % === COMPUTE METRICS ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % === APPEND ROW ===
        allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV MANUALLY ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);

fprintf('\n✅ Master CSV written to:\n%s\n', outputCSV);

files = dir('/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps/ratemap*.mat');
for i = 1:length(files)
    disp(files(i).name)
end

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

        % === EXTRACT CELL/TRIAL NUMBERS ===
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            cellNum = f;
            trialNum = NaN;
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes 1 variable per file

        % === COMPUTE PEAK + FIELD SIZE ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % === APPEND ROW ===
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
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);

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

    % ✅ Extract MouseID and Date from folder path
    splitPath = split(pcFolder, filesep);
    mouseID = splitPath{end-2};  % e.g. 'm4005'
    dateStr = splitPath{end-1};  % e.g. '20200924'

    files = dir(fullfile(pcFolder, 'ratemap*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % === EXTRACT CELL/TRIAL NUMBERS ===
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            cellNum = f;
            trialNum = NaN;
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes 1 variable per file

        % === COMPUTE PEAK + FIELD SIZE ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % === APPEND ROW ===
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

    % ✅ Extract MouseID and Date from folder path
    splitPath = split(pcFolder, filesep);
    mouseID = splitPath{end-2};  % e.g. 'm4005'
    dateStr = splitPath{end-1};  % e.g. '20200924'

    files = dir(fullfile(pcFolder, 'ratemap*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % === EXTRACT CELL/TRIAL NUMBERS ===
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            cellNum = f;
            trialNum = NaN;
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes 1 variable per file

        % === COMPUTE PEAK + FIELD SIZE ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % ✅ CORRECT WAY TO APPEND (flat row, not nested)
        allRows(end+1, :) = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:size(allRows, 1)
    row = allRows(i, :);
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);
fclose(fid);
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);

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

    % ✅ Extract MouseID and Date from folder path
    splitPath = split(pcFolder, filesep);
    mouseID = splitPath{end-2};  % e.g. 'm4005'
    dateStr = splitPath{end-1};  % e.g. '20200924'

    files = dir(fullfile(pcFolder, 'ratemap*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % === EXTRACT CELL/TRIAL NUMBERS ===
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            cellNum = f;
            trialNum = NaN;
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes 1 variable per file

        % === COMPUTE PEAK + FIELD SIZE ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % ✅ APPEND ROW (FLAT, NOT NESTED)
        allRows(end+1, :) = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:size(allRows, 1)
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        allRows{i,1}, allRows{i,2}, allRows{i,3}, allRows{i,4}, ...
        allRows{i,5}, allRows{i,6}, allRows{i,7});
end

fclose(fid);
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);
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

    % ✅ Correct path extraction
    splitPath = split(folders(k).folder, filesep);
    mouseID = splitPath{end-1};   % m4005
    dateStr = splitPath{end};     % 20200924

    files = dir(fullfile(pcFolder, 'ratemap*.mat'));
    fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % === EXTRACT CELL/TRIAL NUMBERS ===
        tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if isempty(tokens)
            cellNum = f;
            trialNum = NaN;
            warning('⚠️ Could not parse cell/trial from: %s', fileName);
        else
            cellNum = str2double(tokens{1});
            trialNum = str2double(tokens{2});
        end

        % === LOAD RATEMAP ===
        S = load(filePath);
        vars = fieldnames(S);
        ratemap = S.(vars{1});  % assumes 1 variable per file

        % === COMPUTE PEAK + FIELD SIZE ===
        if ~isnumeric(ratemap) || isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid or non-numeric file: %s', fileName);
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

        % ✅ Append correct flat row
        allRows(end+1, :) = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:size(allRows, 1)
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        allRows{i,1}, allRows{i,2}, allRows{i,3}, allRows{i,4}, ...
        allRows{i,5}, allRows{i,6}, allRows{i,7});
end

fclose(fid);
fprintf('\n✅ Master CSV saved to:\n%s\n', outputCSV);
