function convert_Slx(opts)
% exportSlx - 导出Slx文件为指定版本, 和指定类型
%   opts: 选项结构体, 包含以下字段:
%       version: 指定的Slx版本
%       type: 指定的导出类型
%       modelName: 要导出的模型名称
%       modelPath: 要加载并导出的模型文件的路径
%       filePath: 导出文件的路径

    arguments
        opts.version (1,1) string ...
        {mustBeMember(opts.version, ["R2020b"; "R2021a"; "R2021b"; "R2022a"; "R2022b"; "R2023a"; "R2023b"; "R2024a"; "R2024b"])} = "R2023b"
        opts.type (1,1) string {mustBeMember(opts.type, ["slx"; "mdl"])} = "slx"
        opts.modelPath (1,1) string = ''
        opts.filePath (1,1) string = ''
    end

    app = myOp.PathManagerApp();

    % 转换模型的按钮
    app.ConvertButton.Text = "🔄 转换模型";
    % 将按钮设置为 开关模式, 以便在转换过程中可以点击中断
    app.ConvertButton.Enable = 'on'; % 确保按钮可用
    app.ConvertButton.Interruptible = 'on'; % 允许中断
    app.ConvertButton.BusyAction = "queue";
    params = opts;
    params.app = app;
    app.ConvertButton.ButtonPushedFcn = @(src, event) convertModel(params);
end




function convertModel(opts)
    arguments
        opts struct
    end
    app = opts.app;
    % if isempty(isRunning) || ~isRunning
    %     isRunning = true;
    %     app.ConvertButton.Text = "⏳ 转换中...";
    %     drawnow; % 立即更新按钮状态
    % else
    %     % 提示用户正在转换中，请稍后, 并给选项是否立即中断转换
    %     app.ConvertButton.BusyAction = "cancel";
    %     selection = uiconfirm(app.UIFigure, "正在转换中，请稍后！是否要立即中断转换？", "提示", ...
    %         "Options", ["是", "否"], ...
    %         "DefaultOption", 2, ...
    %         "CancelOption", 2);
    %     if selection == 1
    %         isRunning = false;
    %         app.ConvertButton.Text = "⌚️ 正在停止...";
    %         app.ConvertButton.Enable = 'off'; % 禁用按钮以防止重复点击
    %         drawnow; % 立即更新按钮状态
    %     else
    %         return; % 用户选择继续等待，直接返回
    %     end
    % end
    app.ConvertButton.Text = "⏳ 转换中...";
    app.ConvertButton.Enable = 'off'; % 禁用按钮以防止重复点击
    drawnow; % 立即更新按钮状态

    if isempty(app.PathListBox.Items)
        uialert(app.UIFigure, "请先添加要转换的模型文件路径！", "提示");
        app.ConvertButton.Text = "🔄 转换模型";
        app.ConvertButton.Enable = 'on'; % 启用按钮
        return;
    end

    % 获取所有路径下的Slx文件
    pathList = app.PathListBox.Items;
    pathList = string(pathList);
    filePaths = getAllSlxFiles(pathList);
    % 检查每个文件的版本是否符合目标版本, 并找出需要转换的文件
    isCompatible = checkSlxVersion(filePaths, opts.version);
    filePathsToConvert = filePaths(~isCompatible);
    % 如果没有需要转换的文件, 就提示用户并返回
    if isempty(filePathsToConvert)
        uialert(app.UIFigure, "所有文件都已经是目标版本，无需转换！", "提示");
        app.ConvertButton.Text = "🔄 转换模型";
        app.ConvertButton.Enable = 'on'; % 启用按钮
        return;
    end

    % 创建进度条
    % d = uiprogressdlg(app.UIFigure, ...
    % 'Title', '转换中, 请等待', ...
    % 'Message', '正在转换模型...', ...
    % 'Cancelable', 'on', ...
    % 'CancelFcn', @(src, event) cancelConversion(app));
    d = uiprogressdlg(app.UIFigure, ...
    'Title', '转换中, 请等待', ...
    'Message', '正在转换模型...', ...
    'Cancelable', 'on');
    
    % 转换需要转换的文件，导出到临时目录，并返回新的文件路径列表
    if d.CancelRequested
        msg = sprintf("🚫 转换已被用户中断");
        disp(msg);
        app.ConvertButton.Text = "🔄 转换模型";
        app.ConvertButton.Enable = 'on'; % 启用按钮
        delete(d); % 关闭进度条
        return;
    end
    msg = sprintf("✨️ 发现 %d 个需要转换的文件，正在转换中...", length(filePathsToConvert));
    disp(msg);
    [targetFilePathList, isOk, myTempDir] = exportSlxAll(d, filePathsToConvert, opts.version);
    if d.CancelRequested
        msg = sprintf("🚫 转换已被用户中断");
        disp(msg);
        app.ConvertButton.Text = "🔄 转换模型";
        app.ConvertButton.Enable = 'on'; % 启用按钮
        delete(d); % 关闭进度条
        return;
    end
    
    % % 调用对应版本的 matlab 完成文件的参数修改, 并覆盖原文件
    % msg = sprintf("✨️ 正在使用MATLAB COM服务器执行Slx文件保存操作...");
    % disp(msg);
    % modifySlx(...
    %     'app', app, ...
    %     'filePathsToConvert', filePathsToConvert, ...
    %     'targetFilePathList', targetFilePathList, ...
    %     'isOk', isOk, ...
    %     'd', d, ...
    %     'myTempDir', myTempDir ...
    % );
    for i = 1:length(filePathsToConvert)
        targetFilePath = targetFilePathList(i);
        filePathToConvert = filePathsToConvert(i);
        if isOk(i)
            myOp.slx.file.onGenerateASAP2("path", targetFilePath, "mute", true);
            % 将修改后的文件覆盖原文件
            movefile(targetFilePath, filePathToConvert, 'f');
            msg = sprintf("%s. ✅ 文件 [%s] 已成功转换并覆盖原文件。", string(i), filePathToConvert);
            disp(msg);
        end
    end
    
    app.ConvertButton.Text = "🔄 转换模型";
    app.ConvertButton.Enable = 'on'; % 启用按钮
    delete(d); % 关闭进度条
end


function filePath = getAllSlxFiles(pathList)
    % 获取所有路径下的Slx文件
    filePath = [];
    for i = 1:length(pathList)
        allFiles = searchFiles(pathList(i));
        for j = 1:length(allFiles)
            thisFile = allFiles(j);
            thisFile = dir(thisFile);
            ext = thisFile.name(end-3:end);
            if strcmp(ext, '.slx') || strcmp(ext, '.mdl')
                filePath = [filePath; string(fullfile(thisFile.folder, thisFile.name))];
            end
        end
    end
    filePath = string(filePath);
end


function filesOut = searchFiles(folder)
    filesOut = [];
    folder = string(folder);
    if isfolder(folder)
        files = dir(folder);
        for i = 1:length(files)
            thisFile = files(i);
            if startsWith(thisFile.name, '.')

            elseif thisFile.isdir
                newFiles = searchFiles(fullfile(folder, thisFile.name));
                filesOut = [filesOut; newFiles];
            else
                filesOut = [filesOut; string(fullfile(thisFile.folder, thisFile.name))];
            end
        end
    else
        filesOut = [filesOut; folder];
    end
    filesOut = string(filesOut);
end

function isCompatible = checkSlxVersion(filePath, targetVersion)
    % 检查Slx文件的版本是否符合目标版本 (不加载模型)
    arguments
        filePath string
        targetVersion (1,1) string
    end
    
    isCompatible = false(length(filePath), 1);
    
    for i = 1:length(filePath)
        try
            % ✅ 使用 MDLInfo 而不是 ModelInfo
            % 这不会在 Simulink 中打开模型，也不会占用 License
            info = Simulink.MDLInfo(filePath(i));
            
            % 💡 注意：ReleaseName 返回的是 "R2023b" 这种格式
            % 如果你对比的是版本号(如 23.2)，请使用 info.SimulinkVersion
            if strcmpi(info.ReleaseName, targetVersion)
                isCompatible(i) = true;
            end
            
        catch ME
            msg = sprintf("⚠️ 无法读取文件 [%s] 的信息: %s", filePath(i), ME.message);
            % 这里建议设为 false，因为无法确认其版本
            isCompatible(i) = false; 
            disp(msg);
        end
    end
end

function cancelConversion(app)
    app.ConvertButton.Text = "⌚️ 正在停止...请稍等";
end




function [targetFilePath, isOk] = exportSlx(opts)
    arguments
        opts.slxFilePath (1,1) string;
        opts.myTempDir (1,1) string;
        opts.version (1,1) string ...
        {mustBeMember(opts.version, ["R2020b"; "R2021a"; "R2021b"; "R2022a"; "R2022b"; "R2023a"; "R2023b"; "R2024a"; "R2024b"])};
    end

    isOk = false;

    slxFilePath = opts.slxFilePath;
    version = opts.version;
    myTempDir = opts.myTempDir;
    mySubTempDir = tempname;
    [~, mySubTempDir, ~] = fileparts(mySubTempDir);
    mySubTempDir = fullfile(myTempDir, mySubTempDir);
    mkdir(mySubTempDir);

    modelName = dir(slxFilePath).name;
    modelName = split(modelName, ".");
    modelName = modelName(1);
    isLoaded = bdIsLoaded(modelName);
    if isLoaded
        close_system(modelName, 0);
    end
    open_system(slxFilePath);
    model = load_system(slxFilePath);
    model = get_param(model, 'Name');

    % 导出文件到临时目录
    slxFilePathStru = dir(slxFilePath);
    targetFilePath = fullfile(mySubTempDir, slxFilePathStru.name);
    try
        save_system(model, targetFilePath, ...
            'ExportToVersion', version, ...
            'OverwriteIfChangedOnDisk', true);
        isOk = true;
    catch ME
        isOk = false;
    end
    close_system(model, 0);
end


function [targetFilePathList, isOk, myTempDirOut] = exportSlxAll(d, filePathsToConvert, version)
    arguments
        d;
        filePathsToConvert string;
        version (1,1) string ...
        {mustBeMember(version, ["R2020b"; "R2021a"; "R2021b"; "R2022a"; "R2022b"; "R2023a"; "R2023b"; "R2024a"; "R2024b"])};
    end

    persistent last_filePathsToConvert last_isOk last_targetFilePathList last_version;
    persistent myTempDir;
    isNew = false;
    if isempty(myTempDir) || ~isfolder(myTempDir)
        myTempDir = tempname;
        mkdir(myTempDir);
        isNew = true;
    end

    filePathsToConvert = string(filePathsToConvert);
    filePathsToConvert = filePathsToConvert(:);

    isOk = false(length(filePathsToConvert), 1);
    targetFilePathList = strings(length(filePathsToConvert), 1);
    myTempDirOut = myTempDir;

    if isempty(last_filePathsToConvert)
        last_filePathsToConvert = filePathsToConvert;
        last_version = version;
        last_isOk = isOk;
        last_targetFilePathList = targetFilePathList;
    end
    % 找出与上次完全相同的输入, 如果版本也相同, 就直接返回上次的结果
    if ~isNew
        if isequal(version, last_version)
            for i = 1:length(filePathsToConvert)
                idx = find(last_filePathsToConvert == filePathsToConvert(i), 1);
                if ~isempty(idx)
                    isOk(i) = last_isOk(idx);
                    targetFilePathList(i) = last_targetFilePathList(idx);
                end
            end
        end
    end

    % 检测是否已经打开了 parfor 的并行池，如果没有就创建一个
    if length(filePathsToConvert) >= 4
        needParfor = false;
    else
        needParfor = false;
    end
    if needParfor
        pool = gcp('nocreate');
        if isempty(pool)
            parpool(4); % 使用默认设置创建并行池
        end
        parpoolNum = gcp().NumWorkers;
    else
        parpoolNum = 1;
    end

    isProcessed = false(length(filePathsToConvert), 1);
    loops = ceil(length(filePathsToConvert) / parpoolNum);
    for i = 1:loops
        if d.CancelRequested
            break;
        end
        idx = (i-1)*parpoolNum + 1 : min(i*parpoolNum, length(filePathsToConvert));
        isOkParfor = isOk(idx);
        filePathsToConvertParfor = filePathsToConvert(idx);
        targetFilePathListParfor = targetFilePathList(idx);
        isProcessedParfor = isProcessed(idx);
        if needParfor
            parfor j = 1:length(idx)
                if isOkParfor(j)
                    isProcessedParfor(j) = true;
                    continue;
                end
                % if d.CancelRequested
                %     continue;
                % end
                [targetFilePathListParfor(j), isOkParfor(j)] = exportSlx(...
                    'slxFilePath', filePathsToConvertParfor(j), ...
                    'myTempDir', myTempDir, ...
                    'version', version ...
                );
                isProcessedParfor(j) = true;
            end
        else
            for j = 1:length(idx)
                if isOkParfor(j)
                    isProcessedParfor(j) = true;
                    continue;
                end
                % if d.CancelRequested
                %     continue;
                % end
                [targetFilePathListParfor(j), isOkParfor(j)] = exportSlx(...
                    'slxFilePath', filePathsToConvertParfor(j), ...
                    'myTempDir', myTempDir, ...
                    'version', version ...
                );
                isProcessedParfor(j) = true;
            end
        end
        isOk(idx) = isOkParfor;
        targetFilePathList(idx) = targetFilePathListParfor;
        isProcessed(idx) = isProcessedParfor;
        % 更新进度条
        d.Value = i / loops;
    end

    % parfor i = 1:length(filePathsToConvert)
    %     if isOk(i)
    %         isProcessed(i) = true;
    %         continue;
    %     end
    %     % if d.CancelRequested
    %     %     continue;
    %     % end
    %     [targetFilePathList(i), isOk(i)] = exportSlx(...
    %         'slxFilePath', filePathsToConvert(i), ...
    %         'myTempDir', myTempDir, ...
    %         'version', version ...
    %     );
    %     isProcessed(i) = true;
    % end
    
    for i = 1:length(filePathsToConvert)
        modelName = dir(filePathsToConvert(i)).name;
        if isOk(i)
            msg = sprintf("%s. ✅ 模型 [%s] 已成功导出到临时目录: %s", string(i), modelName, targetFilePathList{i});
            disp(msg);
        elseif isProcessed(i)
            msg = sprintf("%s. ❌ 导出模型 [%s] 失败", string(i), modelName);
            disp(msg);
        else
            msg = sprintf("%s. ⚠️ 模型 [%s] 的导出已被用户中断", string(i), modelName);
            disp(msg);
        end
    end
    if all(isProcessed)
        last_filePathsToConvert = "";
        last_targetFilePathList = "";
        last_isOk = [];
        last_version = "";
    else
        last_filePathsToConvert = filePathsToConvert;
        last_targetFilePathList = targetFilePathList;
        last_isOk = isOk;
        last_version = version;
    end
end


function modifySlx(opts)
    arguments
        opts.filePathsToConvert string;
        opts.targetFilePathList string;
        opts.isOk logical;
        opts.app myOp.PathManagerApp;
        opts.d;
        opts.myTempDir string;
    end
    filePathsToConvert = opts.filePathsToConvert;
    targetFilePathList = opts.targetFilePathList;
    isOk = opts.isOk;
    app = opts.app;
    d = opts.d;
    myTempDir = opts.myTempDir;
    % 调用对应版本的 matlab 完成文件的参数修改, 并覆盖原文件
    changedPath = myOp.path.getChangedPath();
    h = myOp.comServer.getMatlabComServer();
    h.Execute("clear;");
    cmd = append("cd(""", pwd, """);");
    for i = 1:length(changedPath)
        cmd = append(cmd, "addpath(""", changedPath{i}, """);");
    end
    h.Execute(cmd);
    isProcessed = false(length(filePathsToConvert), 1);
    for i = 1:length(filePathsToConvert)
        if d.CancelRequested
            break;
        end
        if isOk(i)
            [~, modelName, ~] = fileparts(targetFilePathList(i));
            cmd = append("load_system(""", targetFilePathList(i), """);");
            out = h.Execute(cmd);
            cmd = append("set_param(""", modelName, """, 'GenerateASAP2', true);");
            out = h.Execute(cmd);
            cmd = append("save_system(""", modelName, """, """, filePathsToConvert(i), """);");
            out = h.Execute(cmd);
            cmd = append("close_system(""", modelName, """, 0);");
            out = h.Execute(cmd);
            msg = sprintf("%s. ✅ 文件 [%s] 已成功转换并覆盖原文件。", string(i), filePathsToConvert(i));
            disp(msg);
        end
        isProcessed(i) = true;
    end
    cmd = "";
    for i = 1:length(changedPath)
        cmd = append(cmd, "rmpath(""", changedPath{i}, """);");
    end
    h.Execute(cmd);
    msg = sprintf("🍁 Matlab的 Com 服务器已复原");
    disp(msg);
    
    if all(isProcessed)
        % 删除临时文件夹
        disp("👌 正在清理临时文件...");
        try
            if isfolder(myTempDir)
                rmdir(myTempDir, 's');
            end
        catch ME
            msg = sprintf("⚠️ 删除临时文件夹 [%s] 失败: %s", myTempDir, ME.message);
            disp(msg);
        end
        disp("🍁 所有操作已完成!");
    end
end