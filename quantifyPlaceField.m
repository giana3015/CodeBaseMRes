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
