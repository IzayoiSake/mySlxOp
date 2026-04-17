classdef workSpace

    properties(Constant)
        % 这里可以定义一些常量属性，如果需要的话
    end


    methods(Static)

        function compareVars(var1, var2)
            % 🟢 1. 获取变量名
            name1 = inputname(1);
            name2 = inputname(2);

            if isempty(name1)
                name1 = 'Variable1';
            end
            if isempty(name2)
                name2 = 'Variable2';
            end

            % 🟡 2. 创建临时文件夹
            tempDir = myOp.workSpace.myTempDir();
            if ~exist(tempDir, 'dir')
                mkdir(tempDir);
            end

            try
                % 🟠 3. 保存变量到临时文件
                fileName1 = fullfile(tempDir, [name1, '.mat']);
                fileName2 = fullfile(tempDir, [name2, '.mat']);
                
                % 使用结构体保存以保持变量名在 visdiff 中可见
                s1.var = var1;
                save(fileName1, '-struct', 's1');
                
                s2.var = var2;
                save(fileName2, '-struct', 's2');

                % 🔵 4. 启动比较工具
                visdiff(fileName1, fileName2);

                % 🟣 5. 设置定时清理
                myOp.workSpace.timerCleanup(tempDir);

            catch ME
                fprintf('❌ 比较过程中出现错误: %s\n', ME.message);
                % 如果启动失败，立即清理
                myOp.workSpace.doCleanup(tempDir);
            end
        end

    end


    methods(Static, Access = private)

        function doCleanup(folder)
            % ⚪️ 执行物理删除操作
            if exist(folder, 'dir')
                try
                    rmdir(folder, 's');
                    fprintf('🧹 临时文件夹已清理: %s\n', folder);
                catch
                    fprintf('⚠️ 清理失败（文件可能被占用）: %s\n', folder);
                end
            end
        end
        
        function timerCleanup(folder)
            % ⚪️ 定时清理回调函数
            myTimer = timer('StartDelay', 60, ... % 60秒后执行
                            'TimerFcn', @(~,~) myOp.workSpace.doCleanup(folder), ...
                            'ExecutionMode', 'singleShot');
            start(myTimer);
        end

        function tempDir = myTempDir()

            namePrefix = '__myOp_workSpace__';

            % 检查是否之前创建过临时目录(以 namePrefix 开头的文件夹)
            tempRoot = tempdir;
            dirInfo = dir(tempRoot);
            for i = 1:length(dirInfo)
                if dirInfo(i).isdir && startsWith(dirInfo(i).name, namePrefix)
                    rmdir(fullfile(tempRoot, dirInfo(i).name), 's');
                    disp(['🧹 已清理旧临时文件夹: ', dirInfo(i).name]);
                end
            end
            
            % 创建一个临时目录用于存放比较文件
            nameSuffix = char(java.util.UUID.randomUUID);
            nameSuffix = replace(nameSuffix, '-', '_');
            tempDir = fullfile(tempdir, append(namePrefix, nameSuffix));
            if ~exist(tempDir, 'dir')
                mkdir(tempDir);
            end
        end

    end

end