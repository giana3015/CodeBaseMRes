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

pcRatemapFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
outCSV = fullfile(pcRatemapFolder, sprintf('%s_%s_place_fields.csv', mouseID, dateStr));

% === GET ALL .mat FILES IN FOLDER ===
files = dir(fullfile(pcRatemapFolder, '*.mat'));
fprintf('🔍 Found %d files in: %s\n', length(files), pcRatemapFolder);

% === PREPARE DATA ===
allRows = {};

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);
    fileName = files(f).name;

    % Try to extract cell and trial number from filename
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

    % Compute metrics
    if isempty(ratemap) || all(isnan(ratemap(:)))
        peak = NaN;
        fieldSize = NaN;
    else
        peak = max(ratemap(:), [], 'omitnan');
        thresh = threshold_frac * peak;
        binaryField = ratemap > thresh;
        binaryField = bwareaopen(binaryField, 5);  % remove small blobs
        nBins = sum(binaryField(:));
        fieldSize = nBins * binSize_cm^2;
    end

    % Add row
    allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === WRITE MANUAL CSV ===
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

fprintf('\n✅ Place field CSV written to:\n%s\n', outCSV);
outPath = fullfile(pcRatemapFolder, sprintf('%s_%s_place_fields.csv', mouseID, dateStr));
writetable(T, outPath);

fprintf('\n✅ Saved place field metrics to:\n%s\n', outPath);
