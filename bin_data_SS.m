function [binned_array] = bin_data_SS(var2bin, var2binby, binsize, posdata, pos2use,xRange)

% [binned_array, grid_values] = tint_bin_data2( var2bin, var2binby, binsize, posdata)
%
% NB. This code is closley derived from tint_bin_data2 am not able to use
% the updated version of that function (now called bin_data) as the changes
% that have been made to it mean it is not easily made to work outside of
% the gui. However this function does call some of the new functions that
% Mike has updated (e.g. bin_posdata which replaced tint_bin_posdata) -
% largley these functions are unchanged
%
% Example:
%    [binXY] = cb_bin_data('dwell_time', 'position', binSizePix, pos, allOfPos);
 %   [binDir] = cb_bin_data('dwell_time', 'direction', vars.rm.binSizeDir, pos, allOfPos);
%
%
% Inputs:
% var2bin = 'dwell_time', 'spikes' 
% var2binby = 'position', 'direction', 'speed', 'pxd', special case: 'pos_scatter'- the variables 
%               to be binned by, in order (the values at the centre of each bin to be put 
%               in grid_values): units of cm for position, degrees for direction, cm/s for speed
%               - depend on pixels_per_metre in .pos file header *with y increasing upwards*.
% binsize = the size of the bins in the grid, e.g. 8 for most var2binby 
%               (two values for 'pxd': [8 16] direction first then position). 
%               Binsize units for 'position' are camera pixels, degrees for 'direction'
%               Square bins are assumed for 'position' (binsize*binsize), and the range of position is 
%               the area tracked by the camera (using window_min_x etc in .pos header).
%               can be [] for 'pos_scatter'.
% posdata - position data in the format of global: tint_app.data{i}.pos
% pos2use - index into posdata indicating which position samples were current when a spike was recorded. repetition of
%            the same value is allowed. 
%
% RETURNS
%
% bin_ind - bin index for each binned element (eg in case of all pos is a
%           vector the length of posdata with index corresponding ot bin in
%           binned_array for each pos point

pos_sample_rate = key_value('sample_rate', posdata.header, 'num');


switch var2bin
case 'dwell_time'
    if(strcmp(var2binby,'pos_scatter'))
%         binned_array = zeros(length(list),2);
        binned_array = posdata.xy(list,:);
%         grid_values = [];
    else
        [binned_array] = bin_pos_data(var2binby, binsize, posdata, pos2use, xRange);
        % turn units of binned_array into seconds (total area under histogram should equal the trial duration,
        % or the portions of the trial matching the constriants used to product pos2use)
        binned_array = binned_array./pos_sample_rate;
    end
case 'spikes'      
    if(strcmp(var2binby,'pos_scatter'))
%         binned_array = zeros(length(pos2use),2);
        binned_array = posdata.xy(pos2use, :);
%         grid_values = [];
    else
        % NB list can have repeated values to be put into histogram
        [binned_array] = bin_pos_data(var2binby, binsize, posdata, pos2use,xRange);
        
        %Fix: for some reason if pos2use is empty then the results (empty) ratemap is
        %transposed
        if isempty(pos2use), binned_array=binned_array'; end
    end 
otherwise
    warning(sprintf(' var2bin = %s unrecognised in tint_bin_data2\n', var2bin));
end

