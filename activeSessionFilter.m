function [trialsMask] = activeSessionFilter(inputData)

% === Priority override: use manual mask if passed from script ===
if isfield(inputData, 'activeMaskManual')
    trialsMask = inputData.activeMaskManual;
    return;
end

% === Default behavior (Session 1 & 2 logic for batch cases) ===

% Initialize trialsMask
trialsMask = zeros(inputData.pos.trialFinalInd(end), 1);

% --- Session 1 (Trials 1 to 5) ---
S1_startInd = find(strcmp(inputData.pos.trialNames, '1'));
S1_endInd   = find(strcmp(inputData.pos.trialNames, '5'));

if ~isempty(S1_startInd) && ~isempty(S1_endInd)
    if S1_startInd > 1
        startIdx = inputData.pos.trialFinalInd(S1_startInd - 1) + 1;
    else
        startIdx = 1;
    end
    endIdx = inputData.pos.trialFinalInd(min(S1_endInd, length(inputData.pos.trialFinalInd)));
    if startIdx <= endIdx
        trialsMask(startIdx:endIdx) = true;
    end
end

% --- Session 2 (Trials 6 to 10 or after 'S1') ---
if any(strcmp(inputData.pos.trialNames, 'S1'))
    S2_startInd = find(strcmp(inputData.pos.trialNames, 'S1'));
else
    sixIdx = find(strcmp(inputData.pos.trialNames, '6'));
    if isempty(sixIdx) || sixIdx == 1
        S2_startInd = [];
    else
        S2_startInd = sixIdx - 1;
    end
end

S2_endInd = find(strcmp(inputData.pos.trialNames, '10'));

if ~isempty(S2_startInd) && ~isempty(S2_endInd)
    if any(strcmp(inputData.pos.trialNames, 'S1'))
        startIdx2 = inputData.pos.trialFinalInd(S2_startInd) + 1;
    else
        if S2_startInd > length(inputData.pos.trialFinalInd)
            startIdx2 = length(inputData.pos.trialFinalInd);
        else
            startIdx2 = inputData.pos.trialFinalInd(S2_startInd) + 2;
        end
    end

    endIdx2 = inputData.pos.trialFinalInd(min(S2_endInd, length(inputData.pos.trialFinalInd)));

    if startIdx2 <= endIdx2 && endIdx2 <= length(trialsMask)
        trialsMask(startIdx2:endIdx2) = true;
    end
end
