function idx = label_index(labels, label)
%LABEL_INDEX Find one label in a string-like label vector.

labels = string(labels);
label = string(label);
idx = find(strcmp(labels, label), 1);

if isempty(idx)
    error("Could not locate label '%s'.", char(label));
end
end

