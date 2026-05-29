function onGenerateASAP2(opts)
    arguments
        opts.path (1,1) string = "";
        opts.mute (1,1) logical = false;
    end
    
    Path = opts.path;
    if isequal(Path, "")
        % 创建一个不显示的窗口
        f = figure('Visible', 'off');
        % 打开文件选择对话框
        [file, folder] = uigetfile('*.slx', '选择一个 .slx 文件');
        % 关闭窗口
        close(f);
        if isequal(file, 0)
            disp('用户取消了文件选择');
            return;
        else
            Path = fullfile(folder, file);
        end
    end
    
    if ~isfile(Path)
        disp('文件不存在，请检查路径是否正确');
        return;
    end
    
    [~, name, ~] = fileparts(Path);
    
    % 使用相对安全的临时目录
    tempDir = fullfile(tempdir, [char(name), '_processing']);
    if exist(tempDir, 'dir')
        rmdir(tempDir, 's'); % 如果残留历史目录，先清空
    end
    mkdir(tempDir);
    
    try
        % 1. 安全解压文件 (将解压内容放在独立文件夹中，方便后续精准打包)
        unzipPath = fullfile(tempDir, 'unzip');
        unzip(Path, unzipPath);
        
        simulinkDir = fullfile(unzipPath, 'simulink');
        xmlFiles = getConfigXml(simulinkDir);
        
        if isempty(xmlFiles)
            disp('未找到配置 XML 文件，请检查 .slx 文件结构');
            rmdir(tempDir, 's');
            return;
        end
        
        % 定义节点匹配模式
        searchPattern = '<P Name="GenerateASAP2">.*?</P>';
        replacePattern = '<P Name="GenerateASAP2">on</P>';
        
        % 定义目标对象的起始标签匹配模式
        searchObjectPattern = '([ \t]*)<Object[^>]*ClassName="Simulink\.ERTTargetCC"[^>]*>';
        for i = 1:length(xmlFiles)
            xmlPath = fullfile(simulinkDir, xmlFiles(i).name);
            while true
                try
                    txt = fileread(xmlPath);
                    break; % 读取成功，跳出循环
                catch
                    pause(0.1); % 等待 100ms 后重试，避免文件被占用时的读取错误
                end
            end
            
            if ~isempty(regexp(txt, searchPattern, 'once'))
                % 场景 A: 节点已存在，直接替换 (保持原逻辑)
                txt = regexprep(txt, searchPattern, replacePattern);
                
                fid = fopen(xmlPath, 'w', 'n', 'utf-8');
                fwrite(fid, txt, 'char');
                fclose(fid);
                if ~opts.mute
                    disp(['已成功更新配置文件: ', xmlFiles(i).name]);
                end
                
            else
                % 场景 B: 节点不存在，带【动态缩进】进行强行插入
                if ~isempty(regexp(txt, searchObjectPattern, 'once'))
                    
                    % [重点修改 2] 构造带动态缩进的替换表达式：
                    % $0 代表完整搜到的字符串 (包含原来的缩进和整个 Object 标签)
                    % \n 代表换行
                    % $1 代表正则里第一对括号 ([ \t]*) 抓取到的“原有缩进”
                    % '  ' 代表在原有缩进基础上，再额外退格 2 个空格，符合 XML 层级美学
                    replaceObjPattern = sprintf('$0\n$1  %s', replacePattern);
                    
                    % 执行插入
                    txt = regexprep(txt, searchObjectPattern, replaceObjPattern, 'once');
                    
                    fid = fopen(xmlPath, 'w', 'n', 'utf-8');
                    fwrite(fid, txt, 'char');
                    fclose(fid);
                    if ~opts.mute
                        disp(['已成功带缩进插入配置: ', xmlFiles(i).name]);
                    end
                else
                    disp(['未找到目标 ERTTargetCC 对象，无法插入配置: ', xmlFiles(i).name]);
                end
            end
        end
        
        % 重新打包并覆盖源文件
        if ~opts.mute
            disp('⌚️ 正在重新打包 .slx 文件...');
        end
        zipName = [char(name), '.zip'];
        zipPath = fullfile(tempDir, zipName);
        zip(zipPath, '*', unzipPath);
        
        % 强行覆盖选择的源 slx 文件
        movefile(zipPath, Path, 'f');
        if ~opts.mute
            disp(['✅ 任务完成！已成功更新并保存模型: ', Path]);
        end
        
        % 打扫战场
        rmdir(tempDir, 's');
        
    catch ME
        % 发生异常时，确保清理临时文件夹
        if exist(tempDir, 'dir')
            rmdir(tempDir, 's');
        end
        rethrow(ME);
    end
end

function xmlFiles = getConfigXml(simulinkDir)
    % 1. 先用基础通配符抓取所有候选文件
    xmlFiles = dir(fullfile(simulinkDir, 'configSet*.xml'));

    % 2. 如果存在文件，进行正则精准过滤
    if ~isempty(xmlFiles)
        fileNames = {xmlFiles.name};
        pattern = '^configSet\d+\.xml$';
        isValid = ~cellfun(@isempty, regexp(fileNames, pattern, 'once'));
        xmlFiles = xmlFiles(isValid);
    end
end