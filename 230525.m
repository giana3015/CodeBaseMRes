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

clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
dateStr = '20200924';
folderPath = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
outputCSV = fullfile(folderPath, sprintf('%s_%s_peak_drift_all_cells.csv', mouseID, dateStr));

% === FIND all matching .mat files ===
files = dir(fullfile(folderPath, 'ratemap_cell*_trial*.mat'));
fprintf('🔍 Found %d ratemap files in %s\n', length(files), folderPath);

% === GROUP BY CELL ===
allCellIDs = [];
for f = 1:length(files)
    name = files(f).name;
    tokens = regexp(name, 'ratemap_cell(\d+)_trial(\d+).mat', 'tokens', 'once');
    if ~isempty(tokens)
        allCellIDs(end+1) = str2double(tokens{1});
    end
end
cellList = unique(allCellIDs);

% === INITIALIZE RESULT STORAGE ===
allRows = {};

% === PROCESS EACH CELL ===
for i = 1:length(cellList)
    cellID = cellList(i);
    trialPeaks = nan(10, 2);  % store (X, Y) for trials 1–10

    for trial = 1:10
        fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
        filePath = fullfile(folderPath, fileName);

        if ~isfile(filePath)
            fprintf('⏭️ Skipping missing: %s\n', fileName);
            continue;
        end

        % Load ratemap
        S = load(filePath);
        varnames = fieldnames(S);
        ratemap = S.(varnames{1});

        if isempty(ratemap) || all(isnan(ratemap(:)))
            fprintf('⚠️ Invalid map in: %s\n', fileName);
            continue;
        end

        % Find peak (X, Y)
        [~, idx] = max(ratemap(:));
        [peakY, peakX] = ind2sub(size(ratemap), idx);
        trialPeaks(trial, :) = [peakX, peakY];
    end

    % Calculate distance from trial 1
    refX = trialPeaks(1,1);
    refY = trialPeaks(1,2);

    for trial = 1:10
        px = trialPeaks(trial, 1);
        py = trialPeaks(trial, 2);

        if isnan(px) || isnan(refX)
            dist = NaN;
        else
            dist = sqrt((px - refX)^2 + (py - refY)^2);
        end

        allRows{end+1,1} = {mouseID, dateStr, cellID, trial, px, py, dist};
    end
end

% === WRITE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,CellID,Trial,Peak_X,Peak_Y,Distance_from_Trial1\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%d,%d,%g,%g,%.4f\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ Full CSV saved to:\n%s\n', outputCSV);

clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
rootPath = fullfile('/home/barrylab/Documents/Giana/Data', mouseID);
outputCSV = fullfile(rootPath, sprintf('%s_all_dates_peak_drift.csv', mouseID));

% === FIND ALL DATE FOLDERS ===
dateFolders = dir(fullfile(rootPath, '2*'));  % e.g., 20200924
dateFolders = dateFolders([dateFolders.isdir]);

% === INIT STORAGE ===
allRows = {};

% === LOOP THROUGH EACH DATE ===
for d = 1:length(dateFolders)
    dateStr = dateFolders(d).name;
    pcFolder = fullfile(rootPath, dateStr, 'PC_ratemaps');

    if ~isfolder(pcFolder)
        fprintf('⏭️ Skipping (no PC_ratemaps): %s\n', dateStr);
        continue;
    end

    % === GET ALL .mat FILES ===
    files = dir(fullfile(pcFolder, 'ratemap_cell*_trial*.mat'));
    if isempty(files)
        fprintf('⏭️ No ratemaps found in: %s\n', pcFolder);
        continue;
    end

    % === EXTRACT UNIQUE CELL IDS ===
    cellIDs = [];
    for f = 1:length(files)
        toks = regexp(files(f).name, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
        if ~isempty(toks)
            cellIDs(end+1) = str2double(toks{1});
        end
    end
    cellList = unique(cellIDs);

    % === PROCESS EACH CELL ===
    for i = 1:length(cellList)
        cellID = cellList(i);
        trialPeaks = nan(10, 2);  % (X, Y)

        for trial = 1:10
            fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
            filePath = fullfile(pcFolder, fileName);

            if ~isfile(filePath)
                continue;
            end

            try
                S = load(filePath);
                vars = fieldnames(S);
                ratemap = S.(vars{1});
                if isempty(ratemap) || all(isnan(ratemap(:)))
                    continue;
                end
                [~, idx] = max(ratemap(:));
                [py, px] = ind2sub(size(ratemap), idx);
                trialPeaks(trial, :) = [px, py];
            catch
                fprintf('⚠️ Error reading %s\n', fileName);
                continue;
            end
        end

        % === Distance from Trial 1 ===
        refX = trialPeaks(1,1);
        refY = trialPeaks(1,2);

        for trial = 1:10
            px = trialPeaks(trial,1);
            py = trialPeaks(trial,2);

            if isnan(px) || isnan(refX)
                dist = NaN;
            else
                dist = sqrt((px - refX)^2 + (py - refY)^2);
            end

            allRows{end+1,1} = {mouseID, dateStr, cellID, trial, px, py, dist};
        end
    end
end

% === WRITE MASTER CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,CellID,Trial,Peak_X,Peak_Y,Distance_from_Trial1\n');
for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%d,%d,%g,%g,%.4f\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end
fclose(fid);

fprintf('\n✅ All cells across all dates saved to:\n%s\n', outputCSV);

clc; clear; close all;

% === CONFIGURATION ===
dataRoot = '/home/barrylab/Documents/Giana/Data';
outputCSV = fullfile(dataRoot, 'place_field_drift_with_genotype.csv');

AD_mice = {'m4005','m4020','m4202','m4232','m4602','m4609','m4610'};
WT_mice = {'m4098','m4101','m4201','m4230','m4376','m4578','m4604','m4605'};

% === FIND ALL MOUSE FOLDERS ===
mouseFolders = dir(fullfile(dataRoot, 'm*'));
mouseFolders = mouseFolders([mouseFolders.isdir]);

allRows = {};

for m = 1:length(mouseFolders)
    mouseID = mouseFolders(m).name;

    % Assign genotype
    if ismember(mouseID, AD_mice)
        genotype = 'AD';
    elseif ismember(mouseID, WT_mice)
        genotype = 'WT';
    else
        fprintf('⏭️ Skipping unknown genotype: %s\n', mouseID);
        continue;
    end

    mousePath = fullfile(dataRoot, mouseID);
    dateFolders = dir(fullfile(mousePath, '2*'));
    dateFolders = dateFolders([dateFolders.isdir]);

    for d = 1:length(dateFolders)
        dateStr = dateFolders(d).name;
        pcFolder = fullfile(mousePath, dateStr, 'PC_ratemaps');

        if ~isfolder(pcFolder)
            continue;
        end

        files = dir(fullfile(pcFolder, 'ratemap_cell*_trial*.mat'));
        if isempty(files), continue; end

        % Extract all unique cell IDs
        cellIDs = [];
        for f = 1:length(files)
            tok = regexp(files(f).name, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
            if ~isempty(tok)
                cellIDs(end+1) = str2double(tok{1});
            end
        end
        cellList = unique(cellIDs);

        % Process each cell
        for i = 1:length(cellList)
            cellID = cellList(i);
            trialPeaks = nan(10, 2); % x, y

            for trial = 1:10
                fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
                filePath = fullfile(pcFolder, fileName);
                if ~isfile(filePath), continue; end

                try
                    S = load(filePath);
                    vars = fieldnames(S);
                    rm = S.(vars{1});

                    if isempty(rm) || all(isnan(rm(:)))
                        continue;
                    end

                    [~, idx] = max(rm(:));
                    [py, px] = ind2sub(size(rm), idx);
                    trialPeaks(trial, :) = [px, py];
                catch
                    fprintf('⚠️ Error reading %s\n', fileName);
                    continue;
                end
            end

            % Trial 1 reference point
            refX = trialPeaks(1,1);
            refY = trialPeaks(1,2);

            for trial = 1:10
                px = trialPeaks(trial,1);
                py = trialPeaks(trial,2);

                if isnan(px) || isnan(refX)
                    dist = NaN;
                else
                    dist = sqrt((px - refX)^2 + (py - refY)^2);
                end

                allRows{end+1,1} = {genotype, mouseID, dateStr, cellID, trial, px, py, dist};
            end
        end
    end
end

% === WRITE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'Genotype,MouseID,Date,CellID,Trial,Peak_X,Peak_Y,Distance_from_Trial1\n');
for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%s,%d,%d,%g,%g,%.4f\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7}, row{8});
end
fclose(fid);

fprintf('\n✅ Final CSV with genotype saved to:\n%s\n', outputCSV);

% === Configuration ===
cellID = 2;  % Adjust this for different cells
rootFolder = '/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps';
outputFile = fullfile(rootFolder, sprintf('peak_tracking_cell%02d_consecutive.csv', cellID));

% === Initialize storage ===
trialPeaks = nan(10, 2); % trial × [X, Y]

% === Load peak positions for all trials ===
for trial = 1:10
    fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
    filePath = fullfile(rootFolder, fileName);

    if ~isfile(filePath), continue; end

    raw = load(filePath);
    vars = fieldnames(raw);
    ratemap = raw.(vars{1});

    if isempty(ratemap) || all(isnan(ratemap(:)))
        continue;
    end

    [~, idx] = max(ratemap(:));
    [py, px] = ind2sub(size(ratemap), idx);
    trialPeaks(trial, :) = [px, py];
end

% === Compute distance between consecutive trials ===
consecDists = nan(9, 1);
for t = 1:9
    if all(~isnan(trialPeaks(t,:))) && all(~isnan(trialPeaks(t+1,:)))
        dx = trialPeaks(t+1,1) - trialPeaks(t,1);
        dy = trialPeaks(t+1,2) - trialPeaks(t,2);
        consecDists(t) = sqrt(dx^2 + dy^2);
    end
end

% === Sum movement for block 1–5 and 6–10 ===
% (meaning trial 1→2 to 4→5, and 6→7 to 9→10)
earlyBlockDist = sum(consecDists(1:4), 'omitnan');  % Trials 1–5 = 1→2, 2→3, 3→4, 4→5
lateBlockDist  = sum(consecDists(6:9), 'omitnan');  % Trials 6–10 = 6→7, 7→8, 8→9, 9→10

% === Save to CSV ===
fid = fopen(outputFile, 'w');
fprintf(fid, 'From_Trial,To_Trial,Distance\n');
for t = 1:9
    fprintf(fid, '%d,%d,%.4f\n', t, t+1, consecDists(t));
end
fprintf(fid, '\nSummary,,\n');
fprintf(fid, 'Total_Distance_T1to5,,%.4f\n', earlyBlockDist);
fprintf(fid, 'Total_Distance_T6to10,,%.4f\n', lateBlockDist);
fclose(fid);

fprintf('✅ Consecutive trial movement saved to: %s\n', outputFile);

clc; clear; close all;

% === Configuration ===
dataRoot = '/home/barrylab/Documents/Giana/Data';
outputCSV = fullfile(dataRoot, 'consecutive_peak_drift_summary.csv');

AD_mice = {'m4005','m4020','m4202','m4232','m4602','m4609','m4610'};
WT_mice = {'m4098','m4101','m4201','m4230','m4376','m4578','m4604','m4605'};

% === Find all mouse folders ===
mouseFolders = dir(fullfile(dataRoot, 'm*'));
mouseFolders = mouseFolders([mouseFolders.isdir]);

allRows = {};

for m = 1:length(mouseFolders)
    mouseID = mouseFolders(m).name;

    % Assign genotype
    if ismember(mouseID, AD_mice)
        genotype = 'AD';
    elseif ismember(mouseID, WT_mice)
        genotype = 'WT';
    else
        fprintf('⏭️ Skipping unknown genotype: %s\n', mouseID);
        continue;
    end

    mousePath = fullfile(dataRoot, mouseID);
    dateFolders = dir(fullfile(mousePath, '2*'));
    dateFolders = dateFolders([dateFolders.isdir]);

    for d = 1:length(dateFolders)
        dateStr = dateFolders(d).name;
        pcFolder = fullfile(mousePath, dateStr, 'PC_ratemaps');

        if ~isfolder(pcFolder), continue; end

        files = dir(fullfile(pcFolder, 'ratemap_cell*_trial*.mat'));
        if isempty(files), continue; end

        % Get unique cell IDs
        cellIDs = [];
        for f = 1:length(files)
            tok = regexp(files(f).name, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
            if ~isempty(tok)
                cellIDs(end+1) = str2double(tok{1});
            end
        end
        cellList = unique(cellIDs);

        for i = 1:length(cellList)
            cellID = cellList(i);
            trialPeaks = nan(10, 2); % trial × [X, Y]

            % === Load peak positions ===
            for trial = 1:10
                fileName = sprintf('ratemap_cell%02d_trial%d.mat', cellID, trial);
                filePath = fullfile(pcFolder, fileName);
                if ~isfile(filePath), continue; end

                try
                    S = load(filePath);
                    vars = fieldnames(S);
                    rm = S.(vars{1});
                    if isempty(rm) || all(isnan(rm(:))), continue; end
                    [~, idx] = max(rm(:));
                    [py, px] = ind2sub(size(rm), idx);
                    trialPeaks(trial, :) = [px, py];
                catch
                    continue;
                end
            end

            % === Compute distances between consecutive trials ===
            consecDists = nan(9,1);
            for t = 1:9
                if all(~isnan(trialPeaks(t,:))) && all(~isnan(trialPeaks(t+1,:)))
                    dx = trialPeaks(t+1,1) - trialPeaks(t,1);
                    dy = trialPeaks(t+1,2) - trialPeaks(t,2);
                    consecDists(t) = sqrt(dx^2 + dy^2);
                end
            end

            % === Sum early (1–5) and late (6–10) movement ===
            earlyMove = sum(consecDists(1:4), 'omitnan');  % trials 1–5
            lateMove  = sum(consecDists(6:9), 'omitnan');  % trials 6–10

            allRows{end+1, 1} = {genotype, mouseID, dateStr, cellID, earlyMove, lateMove};
        end
    end
end

% === Save to CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'Genotype,MouseID,Date,CellID,T1_5_Distance,T6_10_Distance\n');
for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%s,%d,%.4f,%.4f\n', row{1}, row{2}, row{3}, row{4}, row{5}, row{6});
end
fclose(fid);

fprintf('\n✅ Drift summary saved to:\n%s\n', outputCSV);

% === Configuration ===
folder = '/home/barrylab/Documents/Giana/Data/m4005/20200924/PC_ratemaps';
file1 = fullfile(folder, 'ratemap_cell02_trial1.mat');
file2 = fullfile(folder, 'ratemap_cell02_trial2.mat');
nShuffles = 1000;

% === Load the ratemaps ===
S1 = load(file1);
S2 = load(file2);
fields1 = fieldnames(S1);
fields2 = fieldnames(S2);
ratemap1 = S1.(fields1{1});
ratemap2 = S2.(fields2{1});

% === Flatten maps ===
map1 = ratemap1(:);
map2 = ratemap2(:);

% === Compute actual correlation ===
real_corr = corr(map1, map2, 'type', 'Pearson');

% === Generate null distribution with circular shuffling ===
shuffled_corrs = zeros(1, nShuffles);
for s = 1:nShuffles
    shift = randi(length(map2));
    shuffled_map2 = circshift(map2, shift);
    shuffled_corrs(s) = corr(map1, shuffled_map2, 'type', 'Pearson');
end

% === Compute p-value ===
pval = mean(abs(shuffled_corrs) >= abs(real_corr));
is_remapping = pval > 0.05;

% === Display results ===
fprintf('Real correlation: %.4f\n', real_corr);
fprintf('p-value from shuffling: %.4f\n', pval);
if is_remapping
    fprintf('🧠 Result: Likely remapping (not significantly correlated)\n');
else
    fprintf('🧠 Result: Likely stable (significantly correlated)\n');
end

% === Plot histogram ===
edges = linspace(-1, 1, 30);
histogram(shuffled_corrs, edges, 'FaceColor', [0.7 0.7 0.7]);
hold on;
yLimits = ylim;
plot([real_corr real_corr], yLimits, 'r--', 'LineWidth', 2);
xlabel('Correlation');
ylabel('Count');
title('Shuffle Distribution with Real Correlation');
legend('Shuffled correlations', 'Real correlation');
box on;
