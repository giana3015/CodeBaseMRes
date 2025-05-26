clc;
clear;
close all;

% === Configuration ===
mouse_folder = '/home/barrylab/Documents/Giana/Data/m4005';
nShuffles = 1000;
minValidPct = 0.03;
output_csv = fullfile(mouse_folder, 'remapping_summary_all_days.csv');

% === Find all date folders ===
date_dirs = dir(mouse_folder);
date_dirs = date_dirs([date_dirs.isdir] & ~startsWith({date_dirs.name}, '.'));

% === Prepare output storage ===
results = {};
comparisons = [1 5; 5 10; 1 10];

% === Loop over each date folder ===
for d = 1:length(date_dirs)
    date_name = date_dirs(d).name;
    day_path = fullfile(mouse_folder, date_name, 'PC_ratemaps');

    if ~exist(day_path, 'dir')
        fprintf('Skipping %s (no PC_ratemaps folder found).\n', date_name);
        continue;
    end

    % Find all ratemap files in this day
    files = dir(fullfile(day_path, 'ratemap_cell*_trial*.mat'));
    cellTrials = struct();

    % Organize by cell and trial
    for i = 1:length(files)
        fname = files(i).name;
        parts = regexp(fname, 'ratemap_cell(\d+)_trial(\d+)\.mat', 'tokens');
        if isempty(parts)
            continue;
        end
        cellID = sprintf('cell%02d', str2double(parts{1}{1}));
        trial = str2double(parts{1}{2});
        cellTrials.(cellID).(['trial' num2str(trial)]) = fullfile(day_path, fname);
    end

    % Run remapping for each cell in this day
    cellNames = fieldnames(cellTrials);
    for c = 1:length(cellNames)
        cellID = cellNames{c};
        for cmp = 1:size(comparisons,1)
            t1 = comparisons(cmp,1);
            t2 = comparisons(cmp,2);
            trial1_field = ['trial' num2str(t1)];
            trial2_field = ['trial' num2str(t2)];

            if isfield(cellTrials.(cellID), trial1_field) && isfield(cellTrials.(cellID), trial2_field)
                file1 = cellTrials.(cellID).(trial1_field);
                file2 = cellTrials.(cellID).(trial2_field);

                % Load ratemaps
                S1 = load(file1); vars1 = fieldnames(S1); ratemap1 = S1.(vars1{1});
                S2 = load(file2); vars2 = fieldnames(S2); ratemap2 = S2.(vars2{1});
                map1 = ratemap1(:);
                map2 = ratemap2(:);

                % Clean and validate
                validIdx = ~isnan(map1) & ~isnan(map2);
                totalBins = numel(map1);
                validBins = sum(validIdx);
                validPct = validBins / totalBins;

                if validBins < 3 || validPct < minValidPct
                    result = {'m4005', date_name, cellID, t1, t2, NaN, NaN, 'Below threshold'};
                else
                    map1 = map1(validIdx);
                    map2 = map2(validIdx);

                    % Real correlation
                    real_corr = corr(map1, map2, 'type', 'Pearson');

                    % Shuffling
                    shuffled_corrs = zeros(1, nShuffles);
                    for s = 1:nShuffles
                        shift = randi(length(map2));
                        shuffled_map2 = circshift(map2, shift);
                        shuffled_corrs(s) = corr(map1, shuffled_map2, 'type', 'Pearson');
                    end

                    % p-value
                    pval = mean(abs(shuffled_corrs) >= abs(real_corr));
                    remap_status = ternary(pval > 0.05, 'Remapping', 'Stable');

                    result = {'m4005', date_name, cellID, t1, t2, real_corr, pval, remap_status};
                end
            else
                result = {'m4005', date_name, cellID, t1, t2, NaN, NaN, 'Missing trial(s)'};
            end

            results(end+1, :) = result;
        end
    end
end

% === Write to CSV ===
header = {'MouseID', 'Date', 'CellID', 'Trial1', 'Trial2', 'RealCorrelation', 'PValue', 'Status'};
fid = fopen(output_csv, 'w');
fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%s\n', header{:});
for i = 1:size(results,1)
    row = results(i,:);
    fprintf(fid, '%s,%s,%s,%d,%d,%.4f,%.4f,%s\n', row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7}, row{8});
end
fclose(fid);

disp(['Remapping analysis complete for all days. Output saved to: ' output_csv]);

% === Ternary helper ===
function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end
