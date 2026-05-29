function cmdStr = myhiliteCmd(hyperLink, displayName)
    if iscell(hyperLink)
        hyperLink = cell2mat(hyperLink);
    end
    if iscell(displayName)
        displayName = cell2mat(displayName);
    end
    if isstring(hyperLink) || ischar(hyperLink)
        % cmdPath = strrep(hyperLink, newline, ''' newline ''');
        cmdPath = strrep(string(hyperLink), newline, ' ');
        cmdPath = strrep(cmdPath, "'", "''");
        displayName = strrep(string(displayName), newline, ' ');
        cmdStr = sprintf('<a href="matlab:myhilite(''%s'')">%s</a>', string(cmdPath), string(displayName));
    elseif ishandle(hyperLink) && isnumeric(hyperLink)
        cmdStr = sprintf('<a href="matlab:myhilite([%.64g])">%s</a>', hyperLink, string(displayName));
    else
        error("无效的超链接");
    end
end