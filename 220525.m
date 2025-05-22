clc; clear; close all;

% === CONFIGURATION ===
mouseID = 'm4020';
rootFolder = fullfile('/home/barrylab/Documents/Giana/Data', mouseID);
binSize_cm = 2;
threshold_frac = 0.3;
outputCSV = fullfile(rootFolder, sprintf('%s_all_dates_place_fields.csv', mouseID));

% === GET ALL DATE FOLDERS (start with 2*) ===
dateFolders = dir(fullfile(rootFolder, '2*'));
allRows = {};

for d = 1:length(dateFolders)
    dateStr = dateFolders(d).name;
    pcFolder = fullfile(rootFolder, dateStr, 'PC_ratemaps');

    if ~isfolder(pcFolder)
        continue;  % skip if PC_ratemaps folder doesn't exist
    end

    files = dir(fullfile(pcFolder, 'ratemap_cell*_trial*.mat'));
    fprintf('📂 %s | %d ratemaps\n', dateStr, length(files));

    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;

        % === EXTRACT cell/trial numbers ===
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
        ratemap = S.(vars{1});

        % === COMPUTE METRICS ===
        if isempty(ratemap) || all(isnan(ratemap(:)))
            warning('⚠️ Skipping invalid ratemap: %s', fileName);
            peak = NaN;
            fieldSize = NaN;
        else
            peak = max(ratemap(:), [], 'omitnan');
            thresh = threshold_frac * peak;
            binaryField = ratemap > thresh;
            binaryField = bwareaopen(binaryField, 5);
            nBins = sum(binaryField(:));
            fieldSize = nBins * binSize_cm^2;
        end

        % === APPEND ROW ===
        allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
    end
end

% === SAVE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ CSV saved to: %s\n', outputCSV);

clc; clear; close all;

% === CONFIGURATION ===
mouseIDs = {'m4005', 'm4020', 'm4098', 'm4101'};  % Add more mouse IDs here
rootFolder = '/home/barrylab/Documents/Giana/Data';
binSize_cm = 2;
threshold_frac = 0.3;
outputCSV = fullfile(rootFolder, 'place_field_metrics_all_mice.csv');

allRows = {};

for m = 1:length(mouseIDs)
    mouseID = mouseIDs{m};
    mouseFolder = fullfile(rootFolder, mouseID);
    dateFolders = dir(fullfile(mouseFolder, '2*'));

    for d = 1:length(dateFolders)
        dateStr = dateFolders(d).name;
        pcFolder = fullfile(mouseFolder, dateStr, 'PC_ratemaps');

        if ~isfolder(pcFolder)
            continue;  % skip if PC_ratemaps folder doesn't exist
        end

        files = dir(fullfile(pcFolder, 'ratemap_cell*_trial*.mat'));
        fprintf('📂 %s | %s | %d ratemaps\n', mouseID, dateStr, length(files));

        for f = 1:length(files)
            filePath = fullfile(files(f).folder, files(f).name);
            fileName = files(f).name;

            % === EXTRACT cell/trial numbers ===
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
            ratemap = S.(vars{1});

            % === COMPUTE METRICS ===
            if isempty(ratemap) || all(isnan(ratemap(:)))
                warning('⚠️ Skipping invalid ratemap: %s', fileName);
                peak = NaN;
                fieldSize = NaN;
            else
                peak = max(ratemap(:), [], 'omitnan');
                thresh = threshold_frac * peak;
                binaryField = ratemap > thresh;
                binaryField = bwareaopen(binaryField, 5);
                nBins = sum(binaryField(:));
                fieldSize = nBins * binSize_cm^2;
            end

            % === APPEND ROW ===
            allRows{end+1, 1} = {mouseID, dateStr, cellNum, trialNum, peak, fieldSize, fileName};
        end
    end
end

% === SAVE TO CSV ===
fid = fopen(outputCSV, 'w');
fprintf(fid, 'MouseID,Date,Cell,Trial,PeakRate_Hz,FieldSize_cm2,FileName\n');

for i = 1:length(allRows)
    row = allRows{i};
    fprintf(fid, '%s,%s,%g,%g,%.4f,%.4f,%s\n', ...
        row{1}, row{2}, row{3}, row{4}, row{5}, row{6}, row{7});
end

fclose(fid);
fprintf('\n✅ Master CSV written to:\n%s\n', outputCSV);
