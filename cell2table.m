function t = cell2table(c,varargin)  %#codegen
%CELL2TABLE Convert cell array to table.
%   T = CELL2TABLE(C) converts the M-by-N cell array C to an M-by-N table T.
%   CELL2TABLE vertically concatenates the contents of the cells in each column
%   of C to create each variable in T, with one exception: if a column of C
%   contains character vectors, then the corresponding variable in T is a
%   cell array of character vectors.
%
%   T = CELL2TABLE(C, 'PARAM1', VAL1, 'PARAM2', VAL2, ...) specifies optional
%   parameter name/value pairs that determine how the data in C are converted.
%
%      'VariableNames'    A string array or cell array of character vectors
%                         containing variable names for T.  The names must be
%                         valid MATLAB identifiers, and must be unique.
%      'RowNames'         A string array or cell array of character vectors
%                         containing row names for T. The names need not be
%                         valid MATLAB identifiers, but must be unique.
%      'DimensionNames'   A string array or cell array of character vectors
%                         containing dimension names for T. The names must be
%                         unique and must not conflict with the variable names.
%
%   See also TABLE2CELL, ARRAY2TABLE, STRUCT2TABLE, TABLE.

%   Copyright 2012-2021 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    t = matlab.internal.coder.cell2table(c, varargin{:});
    return
end

if ~iscell(c) || ~ismatrix(c)
    error(message('MATLAB:cell2table:NDCell'));
end
[nrows,nvars] = size(c);

if nargin == 1
    rownames = {};
    supplied.VariableNames = false;
    supplied.RowNames = false;
    supplied.DimensionNames = false;
else
    pnames = {'VariableNames' 'RowNames' 'DimensionNames' };
    dflts =  {            {}         {}               {}  };
    [varnames,rownames,dimnames,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
end

if ~supplied.VariableNames && (nvars > 0) % skip nvars==0 for performance
    baseName = inputname(1);
    if isempty(baseName)
        varnames = matlab.internal.tabular.defaultVariableNames(1:nvars);
    else
        if nvars == 1
            varnames = {baseName};
        else
            varnames = matlab.internal.datatypes.numberedNames(baseName,1:nvars);
        end
    end
end

if nvars == 0
    % Performant special case to create an Nx0 empty table.
    t = table.empty(nrows,0);
    % Assign the supplied var names just to check for the correct number (zero) and
    % throw a consistent error. No need to check for conflicts with dim names.
    if supplied.VariableNames, t.Properties.VariableNames = varnames; end
    if supplied.RowNames, t.Properties.RowNames = rownames; end
    if supplied.DimensionNames, t.Properties.DimensionNames = dimnames; end
else
    % Each column of C becomes a variable in T. container2vars ensures that the vars
    % in its output cell are all the same height.
    vars = tabular.container2vars(c); % cellArray -> cellVector
    if supplied.DimensionNames
        t = table.init(vars,nrows,rownames,nvars,varnames,dimnames);
    else
        t = table.init(vars,nrows,rownames,nvars,varnames);
    end
end
