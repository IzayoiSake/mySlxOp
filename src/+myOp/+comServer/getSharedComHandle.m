function h = getSharedComHandle()

    persistent comHandle

    if ~isempty(comHandle)
        try
            comHandle.Execute(" "); % probe
            h = comHandle;
            return;
        catch
            comHandle = [];
        end
    end

    % 创建或连接 COM
    try
        comHandle = actxGetRunningServer("Matlab.Application");
    catch
        comHandle = actxserver("Matlab.Application");
        comHandle.Visible = 0;
    end

    h = comHandle;
end
