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
rootFolder = '/home/barrylab/Documents/Giana/Data';
binSize_cm = 2;               % spatial bin size in cm (e.g. 2×2 cm)
threshold_frac = 0.3;         % threshold as % of peak firing

% === FIND ALL RATEMAP FILES ===
files = dir(fullfile(rootFolder, 'm*', '*', 'PC_ratemaps', 'ratemap_cell*.mat'));

% === COLLECT RESULTS ===
allRows = {};  % for building final table

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);

    % Extract identifiers
    parts = strsplit(filePath, filesep);
    mouseID = parts{end-2};        % e.g., 'm4005'
    dateStr = parts{end-1};        % e.g., '20200924'
    fileName = files(f).name;      % e.g., 'ratemap_cell01trail1.mat'

    % Parse cell and trial number
    tokens = regexp(fileName, 'cell(\d+)trail(\d+)', 'tokens');
    if isempty(tokens)
        warning('Could not parse cell/trial from %s — skipping.', fileName);
        continue;
    end
    cellNum = str2double(tokens{1}{1});
    trialNum = str2double(tokens{1}{2});

    % Load ratemap
    S = load(filePath);
    vars = fieldnames(S);
    ratemap = S.(vars{1});  % assume only 1 variable in the .mat file

    % Compute peak and place field size
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

    % Append to results
    allRows(end+1, :) = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === CONVERT TO TABLE AND SAVE ===
T = cell2table(allRows, ...
    'VariableNames', {'MouseID', 'Date', 'Cell', 'Trial', 'PeakRate_Hz', 'FieldSize_cm2', 'FileName'});

outPath = fullfile(rootFolder, 'place_field_metrics_all_mice.csv');
writetable(T, outPath);

fprintf('\n✅ All place field data saved to:\n%s\n', outPath);
outPath = fullfile(rootFolder, 'place_field_metrics_all_mice.csv');
writetable(T, outPath);

fprintf('\n✅ All data saved to: %s\n', outPath);
