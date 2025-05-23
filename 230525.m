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
cellID = 2;
trial1_file = sprintf('/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps/ratemap_cell%02d_trial1.mat', cellID);
trial10_file = sprintf('/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps/ratemap_cell%02d_trial10.mat', cellID);
nShuffles = 1000;

% === Load ratemaps ===
S1 = load(trial1_file); vars1 = fieldnames(S1); R1 = S1.(vars1{1});
S2 = load(trial10_file); vars2 = fieldnames(S2); R2 = S2.(vars2{1});

if isempty(R1) || isempty(R2) || all(isnan(R1(:))) || all(isnan(R2(:)))
    error('One of the ratemaps is empty or invalid.');
end

% === Flatten ===
map1 = R1(:)';
map2 = R2(:)';

% === Real correlation ===
real_corr = corr(map1', map2', 'type', 'Pearson');

% === Null distribution from shuffles ===
shuffled_corrs = zeros(1, nShuffles);
for s = 1:nShuffles
    shift = randi(length(map2));
    shuffled_map2 = circshift(map2, shift);
    shuffled_corrs(s) = corr(map1', shuffled_map2', 'type', 'Pearson');
end

% === Calculate p-value (two-sided) ===
pval = mean(abs(shuffled_corrs) >= abs(real_corr));

% === Plot ===
figure;
histogram(shuffled_corrs, 30, 'FaceColor', [0.7 0.7 0.7]);
hold on;
yL = ylim;
plot([real_corr real_corr], yL, 'r', 'LineWidth', 2);
text(real_corr, yL(2)*0.9, sprintf('r = %.3f\np = %.4f', real_corr, pval), ...
    'HorizontalAlignment', 'center', 'BackgroundColor', 'w');
xlabel('Shuffled Correlation (null)');
ylabel('Frequency');
title(sprintf('Trial 1 vs Trial 10 Correlation — Cell %02d', cellID));
box on;
