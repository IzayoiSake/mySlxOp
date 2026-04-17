% save_Mat - 使用旧版本Matlab, 保存基础工作区为mat文件
function save_Mat(opts)
% save_Mat - 使用旧版本Matlab, 保存基础工作区为mat文件
    arguments
        opts.filePath (1,1) string = "";
    end

    if ~isempty(opts.filePath) || strcmp(opts.filePath, "")
        f = figure('Renderer' , 'painters' , 'Position' , [-100 -100 0 0]);
        [fileName, fileDir] = uiputfile('*.mat', 'Save MAT-file', opts.filePath);
        close(f);
        if fileName ~= 0
            filePath = fullfile(fileDir, fileName);
            opts.filePath = filePath;
        else
            return;
        end
    end

    % 从系统获取一个临时文件名
    myTempDir = tempname;
    mkdir(myTempDir);
    myTempName = strrep(tempname, tempdir, '');
    myTempName = fullfile(myTempDir, myTempName);
    tempNamePath = myTempName;
    disp(append("临时文件: ", """", tempNamePath, """"));
    tempNamePath = append(tempNamePath, ".m");
    % 将基础工作区的变量保存到临时.m文件
    % vars = evalin('base', 'who');
    % matlab.io.saveVariablesToScript(tempNamePath, vars);
    % matlab.io.saveVariablesToScript('myScript.m', 'pars', 'MaximumArraySize', Inf);
    runStr = append("matlab.io.saveVariablesToScript", "(", """", tempNamePath, """", ", ", """MaximumArraySize""", ", ", "10000", ")");
    disp(append("正在保存基础工作区变量为Script"));
    evalin('base', runStr);
    % 检查, 如果临时.m文件不存在，则抛出错误
    if ~isfile(tempNamePath)
        % 删除可能存在的临时目录
        if isfolder(myTempDir)
            rmdir(myTempDir, 's');
        end
        error("临时.m文件创建失败: %s", tempNamePath);
    end

    changedPath = myOp.path.getChangedPath();

    try
        disp(append("正在使用COM服务器运行Matlab"));
        h = myOp.comServer.getMatlabComServer();
        h.Execute("clear;");
        % 切换工作目录, 添加路径
        cmd = append("cd(""", pwd, """);");
        for i = 1:length(changedPath)
            cmd = append(cmd, "addpath(""", changedPath{i}, """);");
        end
        % 运行临时.m文件, 保存.mat文件, 删除路径
        cmd = append(cmd, "run('", tempNamePath, "'); ");
        cmd = append(cmd, "save('", opts.filePath, "'); ");
        for i = 1:length(changedPath)
            cmd = append(cmd, "rmpath(""", changedPath{i}, """);");
        end
        h.Execute(cmd);
    catch ME
        disp("Matlab调用失败");
        delete(tempNamePath);
        % 检查, 如果同步生成了.mat文件，则删除它
        companionFilePath = append(myTempName, ".mat");
        if isfile(companionFilePath)
            delete(companionFilePath);
            disp(append("删除同步生成的.mat文件: ", companionFilePath));
        end
        rmdir(myTempDir, 's');
        disp("已删除临时文件和目录");
        error(ME.message);
    end
    h.Execute("clear;");
    % 删除临时.m文件
    delete(tempNamePath);
    % 检查, 如果同步生成了.mat文件，则删除它
    companionFilePath = append(myTempName, ".mat");
    if isfile(companionFilePath)
        delete(companionFilePath);
        disp(append("删除同步生成的.mat文件: ", companionFilePath));
    end
    % 删除临时目录
    rmdir(myTempDir, 's');
    disp("已删除临时文件和目录");
    disp(append("已保存MAT文件到: ", """", opts.filePath, """"));
end