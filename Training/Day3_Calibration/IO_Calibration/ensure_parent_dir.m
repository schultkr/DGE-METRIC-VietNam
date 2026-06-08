function ensure_parent_dir(pathValue)
%ENSURE_PARENT_DIR Create the parent directory for an output path.

parentDir = fileparts(char(string(pathValue)));
if ~isempty(parentDir) && ~isfolder(parentDir)
    mkdir(parentDir);
end
end

