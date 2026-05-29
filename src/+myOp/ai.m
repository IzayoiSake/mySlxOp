classdef ai

    methods(Static)
        function setupAgenticToolkit(cmd)
            arguments
                cmd (1,1) string {mustBeMember(cmd, ["install", "configure", "update", "uninstall", "status"])}
            end
            % 检测是否存在 setupAgenticToolkit 函数
            if exist('setupAgenticToolkit', 'file')
                % 已存在，直接调用
                setupAgenticToolkit(cmd);
            else
                % 不存在，提示用户安装
                disp('⚠️ Simulink Agentic Toolkit 未安装或未正确配置。请先安装并配置 Toolkit 后再使用相关功能。');
            end
        end

        function startAgenticToolkit()
            % 获取 Windows 当前用户的配置文件路径 (即 C:\Users\当前用户名)
            userDir = getenv('USERPROFILE');

            % 拼接并添加路径
            toolkitPath = fullfile(userDir, '.matlab', 'agentic-toolkits', 'simulink');
            % 2. 判断路径是否存在，防止没安装时 MATLAB 启动报错飘红
            if isfolder(toolkitPath)
                addpath(toolkitPath);
                % 运行初始化命令
                satk_initialize;
                disp('✅ 已加载 Simulink Agentic Toolkit。');
            else
                disp('⚠️ 未检测到 Simulink Agentic Toolkit，已跳过加载。');
            end
        end

        % function stopAgenticToolkit()
        %     disp('🛑 正在终止 Simulink Agentic Toolkit...');

        %     % 1. 终极杀招：强行关闭引擎共享，切断 Copilot/MCP 底层连接
        %     try
        %         unshareMATLABSession;
        %         disp('✅ 核心防御: 已强行切断 MATLAB 会话共享 (后门已彻底焊死)。');
        %     catch ME
        %         fprintf('ℹ️ 核心防御: 当前会话未共享或已断开 (%s)。\n', ME.message);
        %     end

        %     % 2. 移除环境变量与搜索路径 (清理工作空间)
        %     userDir = getenv('USERPROFILE');
        %     toolkitPath = fullfile(userDir, '.matlab', 'agentic-toolkits', 'simulink');
            
        %     pathList = strsplit(path, pathsep);
        %     if any(strcmp(toolkitPath, pathList))
        %         rmpath(toolkitPath);
        %         savepath; % 可选：将移除操作保存到本地路径配置文件中
        %         disp('✅ 路径清理: 已从搜索路径中彻底移除 Toolkit。');
        %     else
        %         disp('ℹ️ 路径清理: Toolkit 路径不在当前搜索环境中，无需清理。');
        %     end
            
        %     disp('🛡️ Agentic Toolkit 已安全关闭，当前窗口恢复绝对隔离！');
        % end

    end


    methods(Static, Access=private)
    end


end