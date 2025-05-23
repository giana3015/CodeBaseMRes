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

% === Configuration ===
mouseID = 'm4005';
dateStr = '20200924';
rootFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');

nCells = 100;  % adjust based on how many cells you think exist
nShuffles = 1000;
threshold = 0.05;

rateMaps1 = [];  % trial 1
rateMaps2 = [];  % trial 10
validCells = [];

% === Load ratemaps for each cell ===
for c = 1:nCells
    try
        f1 = fullfile(rootFolder, sprintf('ratemap_cell%02d_trial1.mat', c));
        f2 = fullfile(rootFolder, sprintf('ratemap_cell%02d_trial10.mat', c));
        
        if ~isfile(f1) || ~isfile(f2)
            continue;
        end

        S1 = load(f1); vars1 = fieldnames(S1); R1 = S1.(vars1{1});
        S2 = load(f2); vars2 = fieldnames(S2); R2 = S2.(vars2{1});
        
        if isempty(R1) || isempty(R2) || any(isnan(R1(:))) || any(isnan(R2(:)))
            continue;
        end

        % Flatten into row vector
        rateMaps1(end+1, :) = R1(:)';
        rateMaps2(end+1, :) = R2(:)';
        validCells(end+1) = c;
    catch
        fprintf('⚠️ Failed for cell %d\n', c);
    end
end

% === Compute real correlations ===
nNeurons = size(rateMaps1, 1);
real_corrs = zeros(nNeurons, 1);
for i = 1:nNeurons
    real_corrs(i) = corr(rateMaps1(i,:)', rateMaps2(i,:)', 'type', 'Pearson');
end

% === Compute shuffled null distribution + p-values ===
shuffled_corrs = zeros(nNeurons, nShuffles);
pvals = zeros(nNeurons, 1);

for i = 1:nNeurons
    m1 = rateMaps1(i,:);
    m2 = rateMaps2(i,:);
    
    for s = 1:nShuffles
        shift = randi(length(m2));
        shuffled = circshift(m2, shift);
        shuffled_corrs(i, s) = corr(m1', shuffled', 'type', 'Pearson');
    end
    
    pvals(i) = mean(abs(shuffled_corrs(i,:)) >= abs(real_corrs(i)));
end

% === Classify cells ===
remapping_cells = pvals > threshold;
stable_cells = pvals <= threshold;

sig_corrs = real_corrs(stable_cells);
nonsig_corrs = real_corrs(remapping_cells);

% === Histogram + Plot ===
edges = linspace(-1, 1, 30);
[counts_sig, ~] = histcounts(sig_corrs, edges);
[counts_nonsig, ~] = histcounts(nonsig_corrs, edges);

figure; hold on;
h1 = bar(edges(1:end-1), counts_nonsig, 'histc');
h2 = bar(edges(1:end-1), counts_sig, 'histc');
h1.FaceColor = [0.7 0.7 0.7];
h2.FaceColor = [0.2 0.6 1.0];
h1.EdgeColor = 'none';
h2.EdgeColor = 'none';

legend({'Remapping', 'Stable'}, 'Location', 'NorthWest');
xlabel('Trial 1 vs Trial 10 Correlation');
ylabel('Number of Place Cells');
title(sprintf('Remapping Analysis for %s on %s', mouseID, dateStr));
box on;
