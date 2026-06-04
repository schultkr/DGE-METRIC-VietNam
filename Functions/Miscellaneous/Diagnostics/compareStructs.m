function diffs = compareStructs(strys, strys2, tol)
if nargin<3, tol = 0; end

% initialize a scalar struct with empty values
diffs = struct('onlyInStrys', {{}}, 'onlyInStrys2', {{}}, 'mismatch', {{}});

fn1 = fieldnames(strys);
fn2 = fieldnames(strys2);
only1 = setdiff(fn1, fn2);
only2 = setdiff(fn2, fn1);
common = intersect(fn1, fn2);

diffs.onlyInStrys = only1;
diffs.onlyInStrys2 = only2;

mismatches = {};
for k = 1:numel(common)
    f = common{k};
    a = strys.(f);
    b = strys2.(f);
    if isstruct(a) && isstruct(b) && isscalar(a) && isscalar(b)
        nested = compareStructs(a, b, tol);
        if ~isempty(nested.onlyInStrys) || ~isempty(nested.onlyInStrys2) || ~isempty(nested.mismatch)
            mismatches{end+1} = struct('field', f, 'type', 'struct', 'detail', nested); %#ok<AGROW>
        end
    else
        equal = compareValues(a, b, tol);
        if ~equal
            mismatches{end+1} = struct('field', f, 'type', class(a), 'value1', a, 'value2', b); %#ok<AGROW>
        end
    end
end

diffs.mismatch = mismatches;
end

function tf = compareValues(a, b, tol)
if nargin<3, tol = 0; end
if isnumeric(a) && isnumeric(b)
    if isempty(a) && isempty(b), tf = true; return; end
    if ~isequal(size(a), size(b)), tf = false; return; end
    if tol>0
        tf = all(abs(a(:)-b(:)) <= tol | (isnan(a(:)) & isnan(b(:))));
    else
        tf = isequaln(a, b);
    end
elseif ischar(a) || isstring(a)
    tf = isequaln(string(a), string(b));
elseif iscell(a) && iscell(b)
    if ~isequal(size(a), size(b)), tf = false; return; end
    tf = true;
    for i = 1:numel(a)
        if ~compareValues(a{i}, b{i}, tol), tf = false; break; end
    end
else
    tf = isequaln(a, b);
end
end
