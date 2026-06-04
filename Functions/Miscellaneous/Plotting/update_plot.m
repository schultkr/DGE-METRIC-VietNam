function update_plot(src,plt,ax,t,X,names)
    i = src.Value;
    set(plt,'YData',X(i,:));
    title(ax,names{i},'Interpreter','none');
end