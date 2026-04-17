classdef PathManagerApp < handle
    % PathManagerApp - 模仿 Python 版的路径管理 App
    
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        MainLayout    matlab.ui.container.GridLayout
        InfoLabel     matlab.ui.control.Label
        PathListBox   matlab.ui.control.ListBox
        RemoveButton  matlab.ui.control.Button
        InfoGrid      matlab.ui.container.GridLayout
        ButtonLayout   matlab.ui.container.GridLayout
        ConvertButton matlab.ui.control.Button
    end
    
    methods
        function app = PathManagerApp()
            % 🚀 构造函数：启动即创建界面
            app.createComponents();
        end
    end
    
    methods (Access = private)

        function createComponents(app)
            % 🎨 创建主窗口
            app.UIFigure = uifigure('Name', "路径管理器", ...
                                    'Position', [100 100 600 500]);
            
            % 📐 使用网格布局 (2行1列)
            app.MainLayout = uigridlayout(app.UIFigure, [2, 1]);
            app.MainLayout.RowHeight = {'1x', 80}; % 第一行自适应，第二行(按钮区)固定
            
            % 1️⃣ 上方区域：标签 + 列表框 (再嵌套一个网格)
            app.InfoGrid = uigridlayout(app.MainLayout, [2, 1]);
            app.InfoGrid.RowHeight = {50, '1x'};
            app.InfoGrid.Layout.Row = 1;
            app.InfoGrid.Layout.Column = 1;
            
            % 提示标签
            app.InfoLabel = uilabel(app.InfoGrid, ...
                'Text', sprintf("请将文件或文件夹拖放到此窗口\n或按 Ctrl+V 粘贴路径"), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold');
            app.InfoLabel.Layout.Row = 1;
            
            % 路径列表框 (多选模式)
            app.PathListBox = uilistbox(app.InfoGrid, ...
                'Items', {}, ...
                'Multiselect', 'on', ...
                'FontName', 'Consolas'); % 程序员专属字体，路径更整齐
            app.PathListBox.Layout.Row = 2;
            
            % 2️⃣ 下方区域：控制按钮
            % 首先添加布局
            app.ButtonLayout = uigridlayout(app.MainLayout, [1, 2]);
            app.ButtonLayout.ColumnWidth = {'1x', '1x'}; % 两个按钮等宽
            app.ButtonLayout.Layout.Row = 2;
            app.ButtonLayout.Layout.Column = 1;
            % 添加"移除选中"按钮
            app.RemoveButton = uibutton(app.ButtonLayout, ...
                'Text', '🗑️ 移除选中的路径(Ctrl + D)', ...
                'FontSize', 14, ...
                'BackgroundColor', [1 0.95 0.95]); % 淡淡的红色提醒
            app.RemoveButton.Layout.Row = 1;
            app.RemoveButton.Layout.Column = 1;
            % 添加"转换模型"按钮
            app.ConvertButton = uibutton(app.ButtonLayout, ...
                'Text', '备用', ...
                'FontSize', 14, ...
                'BackgroundColor', [0.95 1 0.95]); % 淡淡的绿色鼓励
            app.ConvertButton.Layout.Row = 1;
            app.ConvertButton.Layout.Column = 2;

            % 💡 绑定基本的事件处理
            % app.UIFigure.DropFcn = @(src, event) disp('文件已拖入');
            app.UIFigure.WindowKeyPressFcn = @(src, event) app.handleKeyPress(src, event);
            app.RemoveButton.ButtonPushedFcn = @(src, event) app.removeSelectedPaths();
        end
    
        function handleKeyPress(app, ~, event)
            keyPress4PathListBox(app, [], event);
        end

        function keyPress4PathListBox(app, ~, event)
            if isequal(app.UIFigure.CurrentObject, app.PathListBox)
                % 🔍 检查是否按下了 Ctrl + V 键
                if (any(strcmp(event.Modifier, 'control')) || any(strcmp(event.Modifier, 'command'))) && strcmp(event.Key, 'v')
                    extractedPaths = string.empty;
                    try
                        % ☕ 调用 Java 接口获取系统剪贴板
                        cb = java.awt.Toolkit.getDefaultToolkit().getSystemClipboard();
                        contents = cb.getContents([]);
                        
                        % 📑 定义"文件列表"的数据类型
                        fileFlavor = java.awt.datatransfer.DataFlavor.javaFileListFlavor;
                        
                        if contents.isDataFlavorSupported(fileFlavor)
                            % 情况 A：剪贴板里是真正的【文件对象】（从资源管理器复制的）
                            javaFileList = contents.getTransferData(fileFlavor);
                            iter = javaFileList.iterator();
                            while iter.hasNext()
                                fileObj = iter.next();
                                extractedPaths(end+1) = string(fileObj.getAbsolutePath()); % 获取绝对路径
                            end
                        elseif contents.isDataFlavorSupported(java.awt.datatransfer.DataFlavor.stringFlavor)
                            % 情况 B：剪贴板里是【纯文本】（用户手动复制的路径字符串）
                            rawText = string(contents.getTransferData(java.awt.datatransfer.DataFlavor.stringFlavor));
                            extractedPaths = splitlines(rawText);
                        end
                    catch ME
                        fprintf('❌ 粘贴出错: %s\n', ME.message);
                    end
                    
                    % 📝 如果提取到了路径，执行添加和去重
                    if ~isempty(extractedPaths)
                        extractedPaths = strtrim(extractedPaths);
                        extractedPaths(extractedPaths == "") = [];
                        app.addPathsToList(extractedPaths);
                    end
                elseif (any(strcmp(event.Modifier, 'control')) || any(strcmp(event.Modifier, 'command'))) && strcmp(event.Key, 'c')
                    % 处理 Ctrl + C 复制事件
                    % 1️⃣ 获取列表框中所有选中的项
                    % 在 Multiselect='on' 时，Value 返回的是字符串数组或 cell 数组
                    selectedPaths = app.PathListBox.Value;
                    if ~isempty(selectedPaths)
                        % 2️⃣ 将选中的路径合并为一个大字符串，每行一个路径
                        % 使用 newline 作为分隔符，确保粘贴到文本编辑器时格式正确
                        copyStr = strjoin(string(selectedPaths), newline);
                        
                        % 3️⃣ 写入系统剪贴板
                        clipboard('copy', copyStr);
                        
                        % 💡 可选：在命令行或状态栏给个反馈
                        fprintf('✅ 已将 %d 条路径复制到剪贴板\n', numel(selectedPaths));
                    else
                        % 如果没有选中项，可以考虑清空剪贴板或不做处理
                        fprintf('ℹ️ 未选中任何路径，未执行复制\n');
                    end
                elseif (any(strcmp(event.Modifier, 'control')) || any(strcmp(event.Modifier, 'command'))) && strcmp(event.Key, 'd')
                    % 处理 Ctrl + D 删除事件
                    app.removeSelectedPaths();
                end
            end
        end

        function addPathsToList(app, newPaths)
            % 获取当前列表中的所有路径
            currentItems = string(app.PathListBox.Items);
            currentItems = currentItems(:);
            newPaths = newPaths(:);
            
            % 💡 合并并去重，同时保持原有的添加顺序 ('stable')
            % newPaths(:) 确保它是列向量
            updatedItems = unique([currentItems; newPaths(:)], 'stable');
            
            % 更新 UI 列表
            app.PathListBox.Items = cellstr(updatedItems);
        end

        function removeSelectedPaths(app)
            % 获取当前列表中的所有路径
            currentItems = string(app.PathListBox.Items);
            % 获取选中的路径
            selectedItems = string(app.PathListBox.Value);
            % 计算剩余的路径
            remainingItems = setdiff(currentItems, selectedItems, 'stable');
            % 更新 UI 列表
            app.PathListBox.Items = cellstr(remainingItems);
        end

    end
end