

load("Data/m4005/20200924/ratemaps.mat")
load("Data/m4005/20200924/trialData.mat")

in.binSizePix = 2;     % spatial bin size (in pixels or cm depending on tracking)
in.speedThresh = 2;    % speed threshold to define "active running"
in.rmSmooth = 3;       % smoothing kernel for ratemap (in bins)

ratemaps = make2Drm(trialData, in, ratemaps);

figure;
imagesc(ratemaps.cellN{1}.rm_2d);
axis equal tight;
colorbar;
title('Place Cell Ratemap');
xlabel('X bin'); ylabel('Y bin');