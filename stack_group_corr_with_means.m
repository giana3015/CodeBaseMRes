
% === Root directory ===
rootFolder = '/Users/gianalee/Desktop/sarah''s data/Data/';
mFolders = dir(fullfile(rootFolder, 'm*'));

for m = 1:length(mFolders)
    if ~mFolders(m).isdir, continue; end
    baseFolder = fullfile(rootFolder, mFolders(m).name);
    fprintf('\n=== Starting animal folder: %s ===\n', mFolders(m).name);

    dayFolders = dir(fullfile(baseFolder, '2*'));
    days = {dayFolders([dayFolders.isdir]).name};

    for d = 1:length(days)
        session = days{d};
        sessionFolder = fullfile(baseFolder, session);
        morningFolder = fullfile(sessionFolder, 'morningtrailcorrmatrix');
        afternoonFolder = fullfile(sessionFolder, 'afternoontrailcorrmatrix');

        % === Output folders ===
        morningOut = fullfile(sessionFolder, 'grouped morningtrail');
        afternoonOut = fullfile(sessionFolder, 'grouped afternoontrail');
        if ~exist(morningOut, 'dir'), mkdir(morningOut); end
        if ~exist(afternoonOut, 'dir'), mkdir(afternoonOut); end

        % === Morning correlation group matrix ===
        mFiles = dir(fullfile(morningFolder, 'morningCorrMatrix_cell*.mat'));
        morningStack = [];

        for k = 1:length(mFiles)
            data = load(fullfile(morningFolder, mFiles(k).name));
            if isfield(data, 'morningCorr')
                matrix = data.morningCorr;
                if all(size(matrix) == [5,5])
                    morningStack(:,:,end+1) = matrix;
                end
            end
        end

        if ~isempty(morningStack)
            groupMorning = mean(morningStack, 3, 'omitnan');
            save(fullfile(morningOut, 'groupMorningCorrMatrix.mat'), 'groupMorning');
            fig = figure('Visible', 'off');
            imagesc(groupMorning, [-1 1]); axis square;
            colormap(jet); colorbar;
            title(sprintf('%s — Group Morning Corr', session));
            saveas(fig, fullfile(morningOut, 'groupMorningCorrMatrix.png'));
            close(fig);

            % Compute and save mean correlation
            upperTri = groupMorning(triu(true(size(groupMorning)), 1));
            meanMorningCorr = mean(upperTri, 'omitnan');
            save(fullfile(morningOut, 'meanMorningCorr.mat'), 'meanMorningCorr');
        end

        % === Afternoon correlation group matrix ===
        aFiles = dir(fullfile(afternoonFolder, 'afternoonCorrMatrix_cell*.mat'));
        afternoonStack = [];

        for k = 1:length(aFiles)
            data = load(fullfile(afternoonFolder, aFiles(k).name));
            if isfield(data, 'afternoonCorr')
                matrix = data.afternoonCorr;
                if all(size(matrix) == [5,5])
                    afternoonStack(:,:,end+1) = matrix;
                end
            end
        end

        if ~isempty(afternoonStack)
            groupAfternoon = mean(afternoonStack, 3, 'omitnan');
            save(fullfile(afternoonOut, 'groupAfternoonCorrMatrix.mat'), 'groupAfternoon');
            fig = figure('Visible', 'off');
            imagesc(groupAfternoon, [-1 1]); axis square;
            colormap(jet); colorbar;
            title(sprintf('%s — Group Afternoon Corr', session));
            saveas(fig, fullfile(afternoonOut, 'groupAfternoonCorrMatrix.png'));
            close(fig);

            % Compute and save mean correlation
            upperTri = groupAfternoon(triu(true(size(groupAfternoon)), 1));
            meanAfternoonCorr = mean(upperTri, 'omitnan');
            save(fullfile(afternoonOut, 'meanAfternoonCorr.mat'), 'meanAfternoonCorr');
        end
    end
end
