function myhilite(obj)
    persistent isSet;
    if isempty(isSet)
        hiliteData.HiliteType = 'user5';
        hiliteData.ForegroundColor = 'magenta'; % 品红色
        hiliteData.BackgroundColor = 'orange';
        set_param(0,'HiliteAncestorsData', hiliteData);
        isSet = true;
    end
    if isempty(obj)
        return;
    end
    if ~iscell(obj)
        if ischar(obj) && ~isstring(obj)
            obj = {obj};
            obj = obj(:);
        else
            obj = obj(:);
            obj = mat2cell(obj, ones(1, numel(obj)));
        end
    end

    isChecked = false(length(obj), 1);
    for i = 1:length(obj)
        thisObj = obj{i};
        try
            thisObj = myOp.slx.general.parseBlock(thisObj);
            isChecked(i) = true;
            obj{i} = thisObj{1};
            continue;
        catch Me
        end
        try
            thisObj = myOp.slx.general.parseLine(thisObj);
            isChecked(i) = true;
            obj{i} = thisObj{1};
            continue;
        catch Me
        end
    end
    
    for i = 1:length(obj)
        thisObj = obj{i};
        if ~isChecked(i)
            if isstring(thisObj) || ischar(thisObj)
                msg = append("⚠️ 对象 '", string(thisObj), "' 既不是 Simulink 模块也不是信号线，无法高亮显示。");
                warning(msg);
            end
            continue;
        end
        if isa(thisObj, "Simulink.Segment")
            srcBlock = get_param(thisObj.Handle, 'SrcBlockHandle');
            dstBlock = get_param(thisObj.Handle, 'DstBlockHandle');
            if srcBlock ~= -1
                hilite_system(srcBlock, 'user5');
            elseif dstBlock ~= -1
                hilite_system(dstBlock, 'user5');
            end
        end
        hilite_system(thisObj.Handle, 'user5');
    end
end