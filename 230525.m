% === Configuration ===
cellID = 2;  % Adjust as needed (e.g., for cell02)
rootFolder = '/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps';
outputFile = fullfile(rootFolder, sprintf('peak_tracking_cell%02d.csv', cellID));

% === Initialize result storage ===
results = [];

% === Loop over trials 1–10 ===
for trial = 1:10
    filename = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
    filepath = fullfile(rootFolder, filename);

    if ~isfile(filepath)
        warning('File not found: %s', filename);
        continue;
    end

    S = load(filepath);
    varNames = fieldnames(S);
    ratemap = S.(varNames{1});  % assume only one variable inside

    if isempty(ratemap) || all(isnan(ratemap(:)))
        warning('Empty or NaN ratemap in: %s', filename);
        continue;
    end

    % Find peak firing bin
    [~, idx] = max(ratemap(:));
    [peakY, peakX] = ind2sub(size(ratemap), idx);

    % Store result: Trial, X, Y
    results(end+1, :) = [trial, peakX, peakY];
end

% === Save to CSV ===
T = array2table(results, 'VariableNames', {'Trial', 'Peak_X', 'Peak_Y'});
writetable(T, outputFile);
fprintf('✅ Saved peak tracking results to:\n%s\n', outputFile);
