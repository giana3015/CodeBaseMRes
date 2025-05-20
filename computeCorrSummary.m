% Set root folder
rootFolder = '/home/barrylab/Documents/Giana/Data/correlation matrix/';
mouseFolders = dir(fullfile(rootFolder, 'm*'));

% Preallocate results
results = [];

for i = 1:length(mouseFolders)
    mouseID = mouseFolders(i).name;
    mousePath = fullfile(rootFolder, mouseID);
    
    % Get all groupCorrMatrix files
    files = dir(fullfile(mousePath, '*.groupCorrMatrix.mat'));
    
    for j = 1:length(files)
        fileName = files(j).name;
        fullPath = fullfile(mousePath, fileName);
        data = load(fullPath);
        
        % Try to extract the matrix (variable may be named differently)
        f = fieldnames(data);
        corrMat = data.(f{1}); % assumes only one variable in the file
        
        % Safety check
        if size(corrMat,1) ~= 10 || size(corrMat,2) ~= 10
            warning("File %s does not contain a 10x10 matrix. Skipped.", fileName);
            continue;
        end

        % Morning vs Morning (1:5,1:5), upper triangle without diag
        m = corrMat(1:5, 1:5);
        morningMask = triu(true(5), 1);
        meanMorning = mean(m(morningMask));

        % Afternoon vs Afternoon (6:10,6:10), upper triangle without diag
        a = corrMat(6:10, 6:10);
        afternoonMask = triu(true(5), 1);
        meanAfternoon = mean(a(afternoonMask));

        % Morning vs Afternoon (1:5, 6:10), all values
        ma = corrMat(1:5, 6:10);
        meanMorningAfternoon = mean(ma(:));

        % Parse date from filename (assumes format: mXXXX.yyyymmdd.groupCorrMatrix.mat)
        tokens = regexp(fileName, '\.(\d{8})\.', 'tokens');
        if isempty(tokens)
            warning("Could not extract date from file: %s", fileName);
            continue;
        end
        dateStr = tokens{1}{1};

        % Store result
        results = [results; 
            {mouseID, dateStr, meanMorning, meanAfternoon, meanMorningAfternoon}];
    end
end

% Convert to table
resultTable = cell2table(results, ...
    'VariableNames', {'MouseID', 'Date', 'MorningCorr', 'AfternoonCorr', 'MorningAfternoonCorr'});

% Display or save
disp(resultTable);
writetable(resultTable, fullfile(rootFolder, 'summary_correlation_values.csv'));
