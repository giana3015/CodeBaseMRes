function binned_array = bin_pos_data(var2binby, binsize, posdata, pos2use,xRange)

% Inputs:
% var2binby = 'position', 'direction', 'speed' or 'pxd' - the variables
%               to be binned by, in order: units of cm for position, degrees for direction, cm/s for speed
%               - depend on pixels_per_metre in .pos file header *with y increasing upwards*.
% binsize - vector of length 1, 2 or 3 !! SEE IMPORTANT NOTES AT LINE 25 RE: USAGE OF BINSIZE
% posdata - position data in the format of global: TintStructure(index).data{i}.pos
% pos2use - list of samples to be binned (e.g. the position samples corresponding to spikes being fired
%               by a given cell, or the entire list of positions, or those facing North etc etc). Can include
%               repeats of a given position sample.
% Outputs:
% binned_array = requested data binned as required - ij format (y, x) for binning by 'position',
%       column vector for 'direction', 'speed'.

% win_max_x = key_value('window_max_x', posdata.header, 'num');
% win_min_x = key_value('window_min_x', posdata.header, 'num');
% win_max_y = key_value('window_max_y', posdata.header, 'num');
% win_min_y = key_value('window_min_y', posdata.header, 'num');
if length(xRange) == 2
    win_max_x = xRange(2);
    win_min_x = xRange(1);
    win_max_y = 1;
    win_min_y = 0;
    
else
    win_max_x = xRange(1);
    win_min_x = xRange(2);
    win_max_y = xRange(3);
    win_min_y = xRange(4);
end
max_speed = max(posdata.speed);

extent_x = win_max_x - win_min_x;
extent_y = win_max_y - win_min_y;

% MA: Note that the binsize variable can be used in one of two ways:
%
% EITHER 
% (1) Binsize is a vector of length 1 and contains the binsize for whatever
% is being binned, be it pos, dir or speed (or a combination although here it
% would be better to use method 2)
%
% OR 
% (2) Binsize is a vector of length 2 or 3 and contains the binsizes
% for pos, dir, and speed IN THAT ORDER
%
% The following lines should cope with both situations:

% (1) If binsize is a vector of length 1, assign the same value to pos, dir 
% & speed.
pos_binsize = binsize(1);
dir_binsize = binsize(1);
speed_binsize = binsize(1);

% (2) If binsize is a vector of length 2 or 3 assign corresponding value to 
% pos, dir & speed.
if length(binsize) > 1
    dir_binsize = binsize(2);
end

if length(binsize) > 2
    speed_binsize = binsize(3);
end

pxd_params.algorithm.iterations = 30;
pxd_params.algorithm.accuracy = 0.0001;
pxd_params.algorithm.tolerance = 0.1;

if size(posdata.dir,1) < size(posdata.dir,2)%Catch row vectors
    posdata.dir = posdata.dir';
end

%Convert var2binby to lowercase
var2binby=lower(var2binby);

switch var2binby

    case 'position'

        if isempty(pos2use) == 1
            array_size = ceil([extent_x extent_y] ./ [pos_binsize pos_binsize]);
            binned_array = zeros(array_size);
        else
            binned_array = histnd(posdata.xy(pos2use,:), [extent_x extent_y], [pos_binsize pos_binsize]);
            binned_array = permute(binned_array, [2 1]); % Correct the annoying ij / xy monkey business.
        end

    case 'direction'

        if isempty(pos2use) == 1
            array_size = ceil(360 ./ dir_binsize);
            binned_array = zeros(1,array_size);
        else
            binned_array = histnd(posdata.dir(pos2use,:), 360, dir_binsize);
        end

    case 'speed'

        max_speed = max(posdata.speed);
        if isempty(pos2use) == 1
            array_size = ceil(max_speed ./ speed_binsize);
            binned_array = zeros(1,array_size);
        else
            binned_array = histnd(posdata.speed(pos2use,:), max_speed, speed_binsize);
        end

    case {'pos pxd' 'dir pxd'}

        if isempty(pos2use) == 1
            array_size = ceil([extent_x extent_y 360] ./ [pos_binsize pos_binsize dir_binsize]);
            binned_array = zeros(array_size);
        else
            data.spikes = histnd([posdata.xy(pos2use,:) posdata.dir(pos2use,:)], [extent_x extent_y 360], [pos_binsize pos_binsize dir_binsize]);
            data.spikes = permute(data.spikes, [3 2 1]); % Correct format for pxd function, [dir y x]
            data.times = histnd([posdata.xy posdata.dir], [extent_x extent_y 360], [pos_binsize pos_binsize dir_binsize]);
            pos_sample_rate = key_value('sample_rate', posdata.header, 'num');
            data.times = data.times./pos_sample_rate; % Convert to seconds
            data.times = permute(data.times, [3 2 1]);
            [data, parameters] = pxd(data, pxd_params);
        end

    case {'pos pxs' 'speed pxs'}

        % Use persistent here with a test to see if the dataset is the same, then we won't need to
        % rerun the (slow) pxd function

        if isempty(pos2use) == 1
            array_size = ceil([extent_x extent_y max_speed] ./ [pos_binsize pos_binsize speed_binsize]);
            binned_array = zeros(array_size);
        else
            data.spikes = histnd([posdata.xy(pos2use,:) posdata.speed(pos2use,:)], [extent_x extent_y max_speed], [pos_binsize pos_binsize speed_binsize]);
            data.spikes = permute(data.spikes, [3 2 1]); % Correct format for pxs function, [speed y x]
            data.times = histnd([posdata.xy posdata.speed], [extent_x extent_y max_speed], [pos_binsize pos_binsize speed_binsize]);
            pos_sample_rate = key_value('sample_rate', posdata.header, 'num');
            data.times = data.times./pos_sample_rate; % Convert to seconds
            data.times = permute(data.times, [3 2 1]);
            [data, parameters] = pxs(data, pxd_params);
        end

    case {'dir dxs' 'speed dxs'}

        % Use persistent here with a test to see if the dataset is the same, then we won't need to
        % rerun the (slow) pxd function

        if isempty(pos2use) == 1
            array_size = ceil([extent_x extent_y max_speed] ./ [pos_binsize pos_binsize speed_binsize]);
            binned_array = zeros(array_size);
        else
            data.spikes = histnd([posdata.dir(pos2use,:) posdata.speed(pos2use,:)], [360 max_speed], [dir_binsize speed_binsize]);
            data.spikes = permute(data.spikes, [2 1]); % Correct format for dxs function, [speed dir]
            data.times = histnd([posdata.dir posdata.speed], [360 max_speed], [dir_binsize speed_binsize]);
            pos_sample_rate = key_value('sample_rate', posdata.header, 'num');
            data.times = data.times./pos_sample_rate; % Convert to seconds
            data.times = permute(data.times, [2 1]);
            [data, parameters] = dxs(data, pxd_params);
        end


    case {'pos pxdxs' 'dir pxdxs' 'speed pxdxs'}

        % Use persistent here with a test to see if the dataset is the same, then we won't need to
        % rerun the (slow) pxd function

        if isempty(pos2use) == 1
            array_size = ceil([extent_x extent_y 360 max_speed] ./ [pos_binsize pos_binsize dir_binsize speed_binsize]);
            binned_array = zeros(array_size);
        else
            data.spikes = histnd([posdata.xy(pos2use,:) posdata.dir(pos2use,:) posdata.speed(pos2use,:)], [extent_x extent_y 360 max_speed], [pos_binsize pos_binsize dir_binsize speed_binsize]);
            data.spikes = permute(data.spikes, [4 3 2 1]); % Correct format for pxdxs function, [speed dir y x]
            data.times = histnd([posdata.xy posdata.dir posdata.speed], [extent_x extent_y 360 max_speed], [pos_binsize pos_binsize dir_binsize speed_binsize]);
            pos_sample_rate = key_value('sample_rate', posdata.header, 'num');
            data.times = data.times./pos_sample_rate; % Convert to seconds
            data.times = permute(data.times, [4 3 2 1]);
            [data, parameters] = pxdxs(data, pxd_params);
        end

    otherwise
        error(sprintf('var2binby = %s is not recognised\n', var2binby));
end

switch var2binby

    case {'pos pxd' 'pos pxs' 'pos pxdxs'}
        if parameters.algorithm.converged
            binned_array = data.position.ml_rate;
        else
            binned_array = [];
        end

    case {'dir pxd' 'dir dxs' 'dir pxdxs'}
        if parameters.algorithm.converged
            binned_array = data.direction.ml_rate;
        else
            binned_array = [];
        end

    case {'speed pxs' 'speed dxs' 'speed pxdxs'}
        if parameters.algorithm.converged
            binned_array = data.speed.ml_rate;
        else
            binned_array = [];
        end
end

if size(binned_array,2) == 1
    binned_array = binned_array';
end