% === Base path to all sessions ===
baseFolder = '/Users/gianalee/Desktop/sarah''s data/Data/m4005/';
days = {'20200924', '20200925', '20200926', '20200927', '20200928'};

% === Ratemap parameters ===
in.speedThresh = 2;
in.binSizePix = 8;
in.rmSmooth = 5;
targetTrials = {'1','2','3','4','5','6','7','8','9','10'};

for d = 1:length(days)
    session = days{d};
    dataFolder = fullfile(baseFolder, session);
    trialDataPath = fullfile(dataFolder, 'trialData.mat');

    if ~isfile(trialDataPath)
        fprintf('❌ trialData.mat missing in %s — skipping.\n', session);
        continue;
    end

    fprintf('\n=== Processing %s ===\n', session);
    load(trialDataPath);  % loads "trialData"

    placeCellIdx = find(cellfun(@(c) c.placeCell == 1, trialData.cellN));
    trialNames = trialData.pos.trialNames;
    trialEnds = trialData.pos.trialFinalInd;

    % === Output folders ===
    ratemapFolder = fullfile(dataFolder, 'PC_ratemaps');
    corrFolder = fullfile(dataFolder, 'ratemap_correlation_matrix_PC');
    if ~exist(ratemapFolder, 'dir'), mkdir(ratemapFolder); end
    if ~exist(corrFolder, 'dir'), mkdir(corrFolder); end

    for c = 1:length(placeCellIdx)
        cell_id = placeCellIdx(c);
        fprintf('\n→ Cell %d\n', cell_id);

        for t = 1:length(targetTrials)
            trialName = targetTrials{t};
            trialIdx = find(strcmp(trialNames, trialName));

            if isempty(trialIdx), continue; end

            % Time window
            if trialIdx == 1
                startIdx = 1;
            else
                startIdx = trialEnds(trialIdx - 1) + 1;
            end
            endIdx = trialEnds(trialIdx);
            trialMask = false(size(trialData.pos.speed));
            trialMask(startIdx:endIdx) = true;

            trialData_this = trialData;
            trialData_this.activeMaskManual = trialMask;

            clear ratemaps
            ratemaps.cellN = {trialData.cellN{cell_id}};

            ratemaps = make2Drm(trialData_this, in, ratemaps);
            rm = ratemaps.cellN{1}.rm_2d;

            % Quantify
            meanRate = mean(rm(:), 'omitnan');
            peakRate = max(rm(:));
            fieldMask = rm > (2 * meanRate);
            CC = bwconncomp(fieldMask, 8);
            fieldSizes = cellfun(@numel, CC.PixelIdxList);
            hasValidField = any(fieldSizes >= 9);

            fprintf('Trial %s: Peak %.2f Hz, Mean %.2f Hz, Valid? %s\n', ...
                trialName, peakRate, meanRate, string(hasValidField));

            % Save mat only (skip figure)
            matName = sprintf('ratemap_cell%02d_trial%s.mat', cell_id, trialName);
            save(fullfile(ratemapFolder, matName), 'rm');
        end

        % === Correlation matrix for this cell ===
        ratemaps_all = cell(10,1);
        for t = 1:10
            try
                data = load(fullfile(ratemapFolder, sprintf('ratemap_cell%02d_trial%d.mat', cell_id, t)));
                ratemaps_all{t} = data.rm;
            catch
                ratemaps_all{t} = NaN;
            end
        end

        corrMatrix = NaN(10);
        for i = 1:10
            for j = 1:10
                rm1 = ratemaps_all{i};
                rm2 = ratemaps_all{j};
                if isnumeric(rm1) && isnumeric(rm2) && all(size(rm1) == size(rm2))
                    validMask = ~isnan(rm1) & ~isnan(rm2);
                    v1 = rm1(validMask);
                    v2 = rm2(validMask);
                    if ~isempty(v1)
                        corrMatrix(i,j) = corr(v1, v2);
                    end
                end
            end
        end

        save(fullfile(corrFolder, sprintf('corrMatrix_cell%02d.mat', cell_id)), 'corrMatrix');
    end
end