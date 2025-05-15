
% === Root directory containing all m**** folders ===
rootFolder = '/Users/gianalee/Desktop/sarah''s data/Data/';
mFolders = dir(fullfile(rootFolder, 'm*'));

for m = 1:length(mFolders)
    if ~mFolders(m).isdir, continue; end
    baseFolder = fullfile(rootFolder, mFolders(m).name);
    fprintf('\n=== Starting animal folder: %s ===\n', mFolders(m).name);

    days = {'20200924', '20200925', '20200926', '20200927', '20200928'};

    for d = 1:length(days)
        session = days{d};
        dataFolder = fullfile(baseFolder, session);
        trialDataPath = fullfile(dataFolder, 'trialData.mat');

        if ~isfile(trialDataPath)
            fprintf('❌ trialData.mat missing in %s — skipping.\n', session);
            continue;
        end

        fprintf('\n=== Processing %s ===\n', session);
        load(trialDataPath);

        placeCellIdx = find(cellfun(@(c) c.placeCell == 1, trialData.cellN));
        ratemapFolder = fullfile(dataFolder, 'PC_ratemaps');
        if ~exist(ratemapFolder, 'dir'), continue; end

        % Create new folders for output
        morningCorrFolder = fullfile(dataFolder, 'morningtrailcorrmatrix');
        afternoonCorrFolder = fullfile(dataFolder, 'afternoontrailcorrmatrix');
        if ~exist(morningCorrFolder, 'dir'), mkdir(morningCorrFolder); end
        if ~exist(afternoonCorrFolder, 'dir'), mkdir(afternoonCorrFolder); end

        for c = 1:length(placeCellIdx)
            cell_id = placeCellIdx(c);
            fprintf('\n→ Cell %d\n', cell_id);

            % Load stored ratemaps for trials 1–10
            ratemaps_all = cell(10,1);
            for t = 1:10
                try
                    data = load(fullfile(ratemapFolder, sprintf('ratemap_cell%02d_trial%d.mat', cell_id, t)));
                    ratemaps_all{t} = data.rm;
                catch
                    ratemaps_all{t} = NaN;
                end
            end

            % --- Morning correlation matrix (trials 1–5) ---
            morningCorr = NaN(5);
            for i = 1:5
                for j = 1:5
                    rm1 = ratemaps_all{i};
                    rm2 = ratemaps_all{j};
                    if isnumeric(rm1) && isnumeric(rm2) && all(size(rm1) == size(rm2))
                        validMask = ~isnan(rm1) & ~isnan(rm2);
                        v1 = rm1(validMask);
                        v2 = rm2(validMask);
                        if ~isempty(v1)
                            morningCorr(i,j) = corr(v1, v2);
                        end
                    end
                end
            end
            save(fullfile(morningCorrFolder, sprintf('morningCorrMatrix_cell%02d.mat', cell_id)), 'morningCorr');
            fig1 = figure('Visible','off');
            imagesc(morningCorr, [-1 1]); axis square;
            colormap(jet); colorbar;
            title(sprintf('%s — Cell %d Morning Correlation', session, cell_id));
            saveas(fig1, fullfile(morningCorrFolder, sprintf('morningCorrMatrix_cell%02d.png', cell_id)));
            close(fig1);

            % --- Afternoon correlation matrix (trials 6–10) ---
            afternoonCorr = NaN(5);
            for i = 6:10
                for j = 6:10
                    rm1 = ratemaps_all{i};
                    rm2 = ratemaps_all{j};
                    if isnumeric(rm1) && isnumeric(rm2) && all(size(rm1) == size(rm2))
                        validMask = ~isnan(rm1) & ~isnan(rm2);
                        v1 = rm1(validMask);
                        v2 = rm2(validMask);
                        if ~isempty(v1)
                            afternoonCorr(i-5,j-5) = corr(v1, v2);
                        end
                    end
                end
            end
            save(fullfile(afternoonCorrFolder, sprintf('afternoonCorrMatrix_cell%02d.mat', cell_id)), 'afternoonCorr');
            fig2 = figure('Visible','off');
            imagesc(afternoonCorr, [-1 1]); axis square;
            colormap(jet); colorbar;
            title(sprintf('%s — Cell %d Afternoon Correlation', session, cell_id));
            saveas(fig2, fullfile(afternoonCorrFolder, sprintf('afternoonCorrMatrix_cell%02d.png', cell_id)));
            close(fig2);
        end
    end
end
