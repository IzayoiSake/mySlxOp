function showDesktop()
    % 显示桌面
    h = myOp.comServer.getMatlabComServer();
    % h.Visible = 1;
    cmd = 'desktop';
    h.Execute(cmd);
end