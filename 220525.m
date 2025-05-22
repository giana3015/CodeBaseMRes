clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4005';
dateStr = '20200924';
binSize_cm = 2;
threshold_frac = 0.3;

pcRatemapFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID, dateStr, 'PC_ratemaps');
outCSV = fullfile(pcRatemapFolder, sprintf('%s_%s_place_fields.csv', mouseID, dateStr));

% === FIND ALL FILES STARTING WITH "ratemap" ===
files = dir(fullfile(pcRatemapFolder, 'ratemap*.mat'));
fprintf('🔍 Found %d ratemap files in %s\n', length(files), pcRatemapFolder);

allRows = {};

for f = 1:length(files)
    filePath = fullfile(files(f).folder, files(f).name);
    fileName = files(f).name;

    % ✅ EXTRACT Cell and Trial numbers from filename
    tokens = regexp(fileName, 'cell(\d+)_trial(\d+)', 'tokens', 'once');
    if isempty(tokens)
        warning('⚠️ Could not parse cell/trial from: %s', fileName);
        continue;
    else
        cellNum = str2double(tokens{1});
        trialNum = str2double(tokens{2});
    end

    % === LOAD RATEMAP ===
    S = load(filePath);
    vars = fieldnames(S);
    ratemap = S.(vars{1});  % assumes single variable inside

    % === COMPUTE PEAK RATE + FIELD SIZE ===
    if isempty(ratemap) || all(isnan(ratemap(:)))
        warning('⚠️ Skipping invalid ratemap: %s', fileName);
        peak = NaN;
        fieldSize = NaN;
    else
        peak = max(ratemap(:), [], 'omitnan');
        thresh = threshold_frac * peak;
        binaryField = ratemap > thresh;
        binaryField = bwareaopen(binaryField, 5);  % remove small noise
        nBins = sum(binaryField(:));
        fieldSize = nBins * binSize_cm^2;
    end

    % === STORE RESULT ROW ===
    allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
end

% === SAVE TO CSV ===
fid = fopen(outCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);

fprintf('\n✅ CSV written to:\n%s\n', outCSV);
