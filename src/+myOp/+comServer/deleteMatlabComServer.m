function deleteMatlabComServer()
    try
        h = actxGetRunningServer("Matlab.Application");
        delete(h);
    catch
    end
end