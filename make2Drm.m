function [ratemaps] = make2Drm(trialData,in,ratemaps)

% Step 1: Get active sessions and movement mask
[activeSessions] = activeSessionFilter(trialData);
speedMask = trialData.pos.speed > in.speedThresh; % animal must be moving

% Step 2: Ensure masks are same length
minLen = min(length(activeSessions), length(speedMask));
activeSessions = activeSessions(1:minLen);
speedMask = speedMask(1:minLen);

% Step 3: Combine masks and extract matching timepoints
activeSessions = find(activeSessions & speedMask);

% Step 4: Get position limits and bin data
poslim = ceil(getPosLim(trialData.pos));
posBinData = bin_data_SS('dwell_time','position', in.binSizePix, trialData.pos, activeSessions, poslim);

% Step 5: Loop over cells
for c = 1:length(ratemaps.cellN)
    
    % Bin spikes occurring in active sessions
    ratemaps.cellN{c}.activeSessionSpikes = ratemaps.cellN{c}.posSample(ismember(ratemaps.cellN{c}.posSample, activeSessions));
    
    binnedSpks = bin_data_SS('spikes','position', in.binSizePix, trialData.pos, ratemaps.cellN{c}.activeSessionSpikes, poslim);
    
    % Make smoothed ratemap
    ratemaps.cellN{c}.rm_2d = make_smooth_ratemap(posBinData, binnedSpks, in.rmSmooth, 'gaus', 'norm');
    
    % Get peak firing rate (per bin)
    ratemaps.cellN{c}.rm_2d_peak = max(ratemaps.cellN{c}.rm_2d(:));
end

end



function poslim  = getPosLim(posdata)
% For 2D spatial return the extent of the window that was tracked

win_max_x       =max(posdata.xy(:,1));
win_min_x       =min(posdata.xy(:,1));
win_max_y       =max(posdata.xy(:,2));
win_min_y       =min(posdata.xy(:,2));


poslim          =[win_max_x+50 ,0 , win_max_y+50 ,0];

end