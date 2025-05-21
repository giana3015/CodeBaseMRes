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


% === Prepare a container for all data ===
allRows = {};

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);

    % Parse path to get Mouse ID and Date
    parts = strsplit(filePath, filesep);
    mouseID = parts{end-2};
    dateStr = parts{end-1};
    fileName = files(f).name;

    % Extract cell and trial number from filename
    tokens = regexp(fileName, 'cell(\d+)trail(\d+)', 'tokens');
    if isempty(tokens)
        warning('Could not parse cell/trial from: %s — skipping.', fileName);
        continue;
    end
    cellNum = str2double(tokens{1}{1});
    trialNum = str2double(tokens{1}{2});

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
        binaryField = bwareaopen(binaryField, 5);
        nBins = sum(binaryField(:));
        fieldSize = nBins * binSize_cm^2;
    end

    % Append as flat row
    allRows(end+1, :) = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === Convert to table and save ===
T = cell2table(allRows, ...
    'VariableNames', {'MouseID', 'Date', 'Cell', 'Trial', 'PeakRate_Hz', 'FieldSize_cm2', 'FileName'});

outPath = fullfile(rootFolder, 'place_field_metrics_all_mice.csv');
writetable(T, outPath);

fprintf('\n✅ All data saved to: %s\n', outPath);
