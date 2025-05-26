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