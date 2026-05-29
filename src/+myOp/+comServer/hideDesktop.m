function hideDesktop()
    % 隐藏桌面
    h = myOp.comServer.getMatlabComServer();
    h.Visible = 0;
end