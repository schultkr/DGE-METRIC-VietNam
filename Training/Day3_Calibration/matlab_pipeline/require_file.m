function require_file(pathValue, label)
%REQUIRE_FILE Error if a required file is missing.

if nargin < 2 || strlength(string(label)) == 0
    label = "file";
end

if strlength(string(pathValue)) == 0 || ~isfile(pathValue)
    error("Missing %s: %s", char(label), char(string(pathValue)));
end
end

