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

ratemap_cell02_trial1.mat
ratemap_cell02_trial10.mat
ratemap_cell02_trial2.mat
ratemap_cell02_trial3.mat
ratemap_cell02_trial4.mat
ratemap_cell02_trial5.mat
ratemap_cell02_trial6.mat
ratemap_cell02_trial7.mat
ratemap_cell02_trial8.mat
ratemap_cell02_trial9.mat
ratemap_cell03_trial1.mat
ratemap_cell03_trial10.mat
ratemap_cell03_trial2.mat
ratemap_cell03_trial3.mat
ratemap_cell03_trial4.mat
ratemap_cell03_trial5.mat
ratemap_cell03_trial6.mat
ratemap_cell03_trial7.mat
ratemap_cell03_trial8.mat
ratemap_cell03_trial9.mat
ratemap_cell04_trial1.mat
ratemap_cell04_trial10.mat
ratemap_cell04_trial2.mat
ratemap_cell04_trial3.mat
ratemap_cell04_trial4.mat
ratemap_cell04_trial5.mat
ratemap_cell04_trial6.mat
ratemap_cell04_trial7.mat
ratemap_cell04_trial8.mat
ratemap_cell04_trial9.mat
ratemap_cell05_trial1.mat
ratemap_cell05_trial10.mat
ratemap_cell05_trial2.mat
ratemap_cell05_trial3.mat
ratemap_cell05_trial4.mat
ratemap_cell05_trial5.mat
ratemap_cell05_trial6.mat
ratemap_cell05_trial7.mat
ratemap_cell05_trial8.mat
ratemap_cell05_trial9.mat
ratemap_cell06_trial1.mat
ratemap_cell06_trial10.mat
ratemap_cell06_trial2.mat
ratemap_cell06_trial3.mat
ratemap_cell06_trial4.mat
ratemap_cell06_trial5.mat
ratemap_cell06_trial6.mat
ratemap_cell06_trial7.mat
ratemap_cell06_trial8.mat
ratemap_cell06_trial9.mat
ratemap_cell07_trial1.mat
ratemap_cell07_trial10.mat
ratemap_cell07_trial2.mat
ratemap_cell07_trial3.mat
ratemap_cell07_trial4.mat
ratemap_cell07_trial5.mat
ratemap_cell07_trial6.mat
ratemap_cell07_trial7.mat
ratemap_cell07_trial8.mat
ratemap_cell07_trial9.mat
ratemap_cell17_trial1.mat
ratemap_cell17_trial10.mat
ratemap_cell17_trial2.mat
ratemap_cell17_trial3.mat
ratemap_cell17_trial4.mat
ratemap_cell17_trial5.mat
ratemap_cell17_trial6.mat
ratemap_cell17_trial7.mat
ratemap_cell17_trial8.mat
ratemap_cell17_trial9.mat
ratemap_cell21_trial1.mat
ratemap_cell21_trial10.mat
ratemap_cell21_trial2.mat
ratemap_cell21_trial3.mat
ratemap_cell21_trial4.mat
ratemap_cell21_trial5.mat
ratemap_cell21_trial6.mat
ratemap_cell21_trial7.mat
ratemap_cell21_trial8.mat
ratemap_cell21_trial9.mat
ratemap_cell34_trial1.mat
ratemap_cell34_trial10.mat
ratemap_cell34_trial2.mat
ratemap_cell34_trial3.mat
ratemap_cell34_trial4.mat
ratemap_cell34_trial5.mat
ratemap_cell34_trial6.mat
ratemap_cell34_trial7.mat
ratemap_cell34_trial8.mat
ratemap_cell34_trial9.mat
ratemap_cell39_trial1.mat
ratemap_cell39_trial10.mat
ratemap_cell39_trial2.mat
ratemap_cell39_trial3.mat
ratemap_cell39_trial4.mat
ratemap_cell39_trial5.mat
ratemap_cell39_trial6.mat
ratemap_cell39_trial7.mat
ratemap_cell39_trial8.mat
ratemap_cell39_trial9.mat
ratemap_cell45_trial1.mat
ratemap_cell45_trial10.mat
ratemap_cell45_trial2.mat
ratemap_cell45_trial3.mat
ratemap_cell45_trial4.mat
ratemap_cell45_trial5.mat
ratemap_cell45_trial6.mat
ratemap_cell45_trial7.mat
ratemap_cell45_trial8.mat
ratemap_cell45_trial9.mat
ratemap_cell49_trial1.mat
ratemap_cell49_trial10.mat
ratemap_cell49_trial2.mat
ratemap_cell49_trial3.mat
ratemap_cell49_trial4.mat
ratemap_cell49_trial5.mat
ratemap_cell49_trial6.mat
ratemap_cell49_trial7.mat
ratemap_cell49_trial8.mat
ratemap_cell49_trial9.mat
ratemap_cell52_trial1.mat
ratemap_cell52_trial10.mat
ratemap_cell52_trial2.mat
ratemap_cell52_trial3.mat
ratemap_cell52_trial4.mat
ratemap_cell52_trial5.mat
ratemap_cell52_trial6.mat
ratemap_cell52_trial7.mat
ratemap_cell52_trial8.mat
ratemap_cell52_trial9.mat
ratemap_cell54_trial1.mat
ratemap_cell54_trial10.mat
ratemap_cell54_trial2.mat
ratemap_cell54_trial3.mat
ratemap_cell54_trial4.mat
ratemap_cell54_trial5.mat
ratemap_cell54_trial6.mat
ratemap_cell54_trial7.mat
ratemap_cell54_trial8.mat
ratemap_cell54_trial9.mat
ratemap_cell55_trial1.mat
ratemap_cell55_trial10.mat
ratemap_cell55_trial2.mat
ratemap_cell55_trial3.mat
ratemap_cell55_trial4.mat
ratemap_cell55_trial5.mat
ratemap_cell55_trial6.mat
ratemap_cell55_trial7.mat
ratemap_cell55_trial8.mat
ratemap_cell55_trial9.mat
ratemap_cell59_trial1.mat
ratemap_cell59_trial10.mat
ratemap_cell59_trial2.mat
ratemap_cell59_trial3.mat
ratemap_cell59_trial4.mat
ratemap_cell59_trial5.mat
ratemap_cell59_trial6.mat
ratemap_cell59_trial7.mat
ratemap_cell59_trial8.mat
ratemap_cell59_trial9.mat
ratemap_cell61_trial1.mat
ratemap_cell61_trial10.mat
ratemap_cell61_trial2.mat
ratemap_cell61_trial3.mat
ratemap_cell61_trial4.mat
ratemap_cell61_trial5.mat
ratemap_cell61_trial6.mat
ratemap_cell61_trial7.mat
ratemap_cell61_trial8.mat
ratemap_cell61_trial9.mat
ratemap_cell65_trial1.mat
ratemap_cell65_trial10.mat
ratemap_cell65_trial2.mat
ratemap_cell65_trial3.mat
ratemap_cell65_trial4.mat
ratemap_cell65_trial5.mat
ratemap_cell65_trial6.mat
ratemap_cell65_trial7.mat
ratemap_cell65_trial8.mat
ratemap_cell65_trial9.mat
ratemap_cell66_trial1.mat
ratemap_cell66_trial10.mat
ratemap_cell66_trial2.mat
ratemap_cell66_trial3.mat
ratemap_cell66_trial4.mat
ratemap_cell66_trial5.mat
ratemap_cell66_trial6.mat
ratemap_cell66_trial7.mat
ratemap_cell66_trial8.mat
ratemap_cell66_trial9.mat
