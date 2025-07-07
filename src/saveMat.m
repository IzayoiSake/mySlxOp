function saveMat(opts)
% saveMat - Save the figure data to a .mat file
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
    myTempName = tempname;
    tempNamePath = myTempName;
    disp(append("临时文件: ", """", tempNamePath, """"));
    tempNamePath = append(tempNamePath, ".m");
    % 将基础工作区的变量保存到临时.m文件
    % vars = evalin('base', 'who');
    % matlab.io.saveVariablesToScript(tempNamePath, vars);
    runStr = append("matlab.io.saveVariablesToScript", "(", """", tempNamePath, """", ")");
    disp(append("正在保存基础工作区变量为Script"));
    evalin('base', runStr);
    % 检查, 如果临时.m文件不存在，则抛出错误
    if ~isfile(tempNamePath)
        error("临时.m文件创建失败: %s", tempNamePath);
    end
    % 检查, 如果同步生成了.mat文件，则删除它
    companionFilePath = append(myTempName, ".mat");
    if isfile(companionFilePath)
        delete(companionFilePath);
        disp(append("删除同步生成的.mat文件: ", companionFilePath));
    end
    try
        matlabExe = findMatlab(version="R2023b");
        matlabExe = append(matlabExe, '.exe');
        disp(append("正在使用Cmd运行Matlab"));
        cmd = append('"', matlabExe, '"', ' -nosplash -nodesktop -wait -r "run(''', tempNamePath, '''); save(''', opts.filePath, '''); exit;"');
        [status, cmdout] = system(cmd);
        if status ~= 0
            error("Cmd运行Matlab失败: %s", cmdout);
        end
    catch ME
        disp("Matlab调用失败");
        delete(tempNamePath);
        error(ME.message);
    end
    % 删除临时.m文件
    delete(tempNamePath);
    disp("完成");
end