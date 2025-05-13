
baseDir = '/Users/gianalee/Desktop/sarah''s data/Data';
mouseDirs = dir(baseDir);

for m = 1:length(mouseDirs)
    if mouseDirs(m).isdir && startsWith(mouseDirs(m).name, 'm')
        mousePath = fullfile(baseDir, mouseDirs(m).name);
        dateDirs = dir(mousePath);
        
        for d = 1:length(dateDirs)
            if dateDirs(d).isdir && ~startsWith(dateDirs(d).name, '.')
                datePath = fullfile(mousePath, dateDirs(d).name);
                fileToLoad = fullfile(datePath, 'ActivePCtrialData.mat');
                
                if exist(fileToLoad, 'file')
                    load(fileToLoad);

                    nSamples = size(trialData.pos.xy, 1);
                    trialNames = trialData.pos.trialNames;
                    trialEnds = trialData.pos.trialFinalInd;

                    morningLabels = {'1','2','3','4','5'};
                    afternoonLabels = {'6','7','8','9','10'};

                    morningIdx = ismember(trialNames, morningLabels);
                    afternoonIdx = ismember(trialNames, afternoonLabels);

                    morningEnd = min(trialEnds(find(morningIdx, 1, 'last')), nSamples);
                    afternoonStart = trialEnds(find(strcmp(trialNames, '5'))) + 1;
                    afternoonEnd = min(trialEnds(find(strcmp(trialNames, '10'))), nSamples);

                    morningMask = false(nSamples, 1);
                    afternoonMask = false(nSamples, 1);
                    morningMask(1:morningEnd) = true;

                    if afternoonStart <= afternoonEnd && afternoonEnd <= nSamples
                        afternoonMask(afternoonStart:afternoonEnd) = true;
                    end

                    morningTrialData = trialData;
                    afternoonTrialData = trialData;

                    fieldsToFilter = {'xy','speed'};
                    for f = 1:length(fieldsToFilter)
                        field = fieldsToFilter{f};
                        if isfield(trialData.pos, field)
                            morningTrialData.pos.(field) = trialData.pos.(field)(morningMask,:);
                            afternoonTrialData.pos.(field) = trialData.pos.(field)(afternoonMask,:);
                        end
                    end

                    for c = 1:length(trialData.cellN)
                        spk = trialData.cellN{c}.timestamp;
                        morningTrialData.cellN{c}.timestamp = spk(ismember(spk, find(morningMask)));
                        afternoonTrialData.cellN{c}.timestamp = spk(ismember(spk, find(afternoonMask)));
                    end

                    morningTrialData.pos.trialNames = trialNames(morningIdx);
                    morningTrialData.pos.trialFinalInd = trialEnds(morningIdx);

                    afternoonTrialData.pos.trialNames = trialNames(afternoonIdx);
                    afternoonTrialData.pos.trialFinalInd = trialEnds(afternoonIdx);

                    save(fullfile(datePath, 'Trail1to5_ActivePCtrialData.mat'), 'morningTrialData');
                    save(fullfile(datePath, 'Trail6to10_ActivePCtrialData.mat'), 'afternoonTrialData');

                    fprintf('✅ Processed %s\%s\ActivePCtrialData.mat\n', mouseDirs(m).name, dateDirs(d).name);
                end
            end
        end
    end
end
