function save_my_figure(fig, name, outdir)
% SAVE_MY_FIGURE Save a figure in multiple formats
%
%   save_my_figure(fig, name, outdir) saves the figure handle 'fig' with 
%   the specified 'name' to the directory 'outdir' in both PNG (300 DPI) 
%   and PDF (vector) formats.
%
%   Inputs:
%       fig    - Figure handle to save
%       name   - Name for the output files (without extension)
%       outdir - Output directory path
%
%   Example:
%       fig = figure();
%       plot(1:10);
%       save_my_figure(fig, 'MyPlot', './output');
%
%   This will create:
%       ./output/MyPlot.png (300 DPI raster)
%       ./output/MyPlot.pdf (vector graphics)

    % Sanitize filename - replace invalid characters with underscores
    name = regexprep(name, '[^A-Za-z0-9_\-]', '_');
    
    % Save as PNG with high resolution
    exportgraphics(fig, fullfile(outdir, [name '.png']), 'Resolution', 300);
    
    % Save as PDF with vector graphics
    exportgraphics(fig, fullfile(outdir, [name '.pdf']), 'ContentType', 'vector');
    
end
