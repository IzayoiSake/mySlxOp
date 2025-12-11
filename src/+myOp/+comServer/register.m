function register(opts)
%   注册COM服务器
%   tests = comServer.register(opts)
    arguments
        opts.version (1,1) string = "";
        opts.user {mustBeMember(opts.user, {'current', 'all'})} = 'current';
    end
    version = opts.version;
    user = opts.user;

    if isequal(version, "")
        if isequal(user, 'current')
            comserver('register');
        else
            comserver('register', 'User', 'all');
        end
    else
        matlabExe = myOp.findMatlab("version", version);
        if isequal(user, 'current')
            cmd = "comserver('register')";
        elseif isequal(user, 'all')
            cmd = "comserver('register', 'User', 'all')";
        end
        cmd = append('"', matlabExe, '"', ' -batch -wait "', cmd, '; exit;"');
        disp(append("正在使用Cmd运行Matlab注册COM服务器, Matlab版本: ", version));
        disp(append("命令: ", cmd));
        [status, cmdout] = system(cmd);
        if status ~= 0
            error("Cmd运行Matlab失败: %s", cmdout);
        end
        disp(append("COM服务器注册成功, Matlab版本: ", version));
    end
end