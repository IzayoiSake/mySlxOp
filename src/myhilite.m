function myhilite(obj)
    persistent isSet;
    if isempty(isSet)
        hiliteData.HiliteType = 'user5';
        hiliteData.ForegroundColor = 'magenta'; % 品红色
        hiliteData.BackgroundColor = 'orange';
        set_param(0,'HiliteAncestorsData', hiliteData);
        isSet = true;
    end
    try
        obj = myOp.slx.general.parseBlock(obj);
    catch
        obj = myOp.slx.general.parseLine(obj);
    end
    for i = 1:length(obj)
        thisObj = obj{i};
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