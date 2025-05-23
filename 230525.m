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
