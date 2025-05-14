baseFolder = '/Users/gianalee/Desktop/sarah''s data/Data/m4005/';
dayFolders = dir(baseFolder);
dayFolders = dayFolders([dayFolders.isdir] & ~startsWith({dayFolders.name}, '.'));

for i = 1:length(dayFolders)
    dayName = dayFolders(i).name;
    corrFolder = fullfile(baseFolder, dayName, 'ratemap_correlation_matrix_PC');
    if ~exist(corrFolder, 'dir')
        fprintf('❌ No correlation folder in %s — skipping.\n', dayName);
        continue;
    end

    corrFiles = dir(fullfile(corrFolder, 'corrMatrix_cell*.mat'));
    if isempty(corrFiles)
        fprintf('⚠️ No correlation matrices in %s — skipping.\n', dayName);
        continue;
    end

    allCorrs = [];
    for k = 1:length(corrFiles)
        data = load(fullfile(corrFolder, corrFiles(k).name));
        if isfield(data, 'corrMatrix')
            C = data.corrMatrix;
            if isequal(size(C), [10 10])
                allCorrs(:, :, end+1) = C;
            end
        end
    end

    if isempty(allCorrs)
        fprintf('⚠️ No valid 10x10 matrices in %s — skipping.\n', dayName);
        continue;
    end

    groupAvg = mean(allCorrs, 3, 'omitnan');
    
    % === Save group matrix ===
    outPath = fullfile(baseFolder, dayName, 'groupCorrMatrix.mat');
    save(outPath, 'groupAvg');

    % === Save figure ===
    figPath = fullfile(baseFolder, dayName, 'groupCorrMatrix.png');
    figure('Visible','off');
    imagesc(groupAvg, [-1 1]); axis square;
    colormap(jet); colorbar;
    xticks(1:10); yticks(1:10);
    title(sprintf('%s — Group Ratemap Correlation', dayName));
    saveas(gcf, figPath);
    close;

    % === Compute & Save mean value ===
    meanCorrValue = mean(groupAvg(:), 'omitnan');
    save(fullfile(baseFolder, dayName, 'meanCorrValue.mat'), 'meanCorrValue');

    fprintf('✅ Saved groupCorrMatrix and meanCorrValue for %s\n', dayName);
end

% === Define base and output folder ===
basePath = '/home/barrylab/Documents/Giana/Data/correlation matrix';
outputFolder = fullfile(basePath, 'all_groupCorrMatrix_pngs');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% === Find all mouse folders ===
mouseFolders = dir(basePath);
mouseFolders = mouseFolders([mouseFolders.isdir] & startsWith({mouseFolders.name}, 'm'));

for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(basePath, mouseID);

    % Find date folders inside this mouse folder
    dayFolders = dir(mousePath);
    dayFolders = dayFolders([dayFolders.isdir] & ~startsWith({dayFolders.name}, '.'));

    for j = 1:length(dayFolders)
        dayName = dayFolders(j).name;
        dayPath = fullfile(mousePath, dayName);

        % Define the PNG file path
        pngPath = fullfile(dayPath, 'groupCorrMatrix.png');

        if isfile(pngPath)
            newName = sprintf('%s_%s_groupCorrMatrix.png', mouseID, dayName);
            copyfile(pngPath, fullfile(outputFolder, newName));
        end
    end
end

fprintf('✅ Done extracting and renaming all groupCorrMatrix.png files.\n');

