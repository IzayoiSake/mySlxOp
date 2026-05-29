classdef std

    methods(Static)

        %% 创建标准参数和信号
        function createStdParam(name, value, dataType, opts)
        %   创建标准参数
        %   createStdParam(name, value, dataType, opts)
        %
        %   输入:
        %       name - 参数名
        %       value - 参数值
        %       dataType - 参数数据类型
        %       opts - 可选参数
        %           headerName - 头文件名, 默认为 bdroot + "_Para"
        %           force - 是否强制覆盖已存在的变量, 默认为 false
            
            arguments
                name {mustBeText};
                value = 0;
                dataType {mustBeText} = '';
                opts.headerName {mustBeText} = append(getfullname(bdroot), "_Para");
                opts.dimensions = [];
                opts.force (1, 1) {mustBeNumericOrLogical} = false;
            end

            headerName = opts.headerName;
            dimensions = opts.dimensions;
            force = opts.force;
            
            if isempty(dataType)
                dataType = myOp.slx.std.guessDataType(name);
            end

            % 创建 Simulink.Parameter
            param = Simulink.Parameter;
            if ~isempty(dimensions) && numel(value) == 1
                value = repmat(value, dimensions);
            elseif ~isempty(dimensions) && ~isequal(size(value), dimensions)
                errorMsg = append("createStdParam: 参数 <", name, "> 的值尺寸与指定的尺寸不匹配.");
                error(errorMsg);
            elseif ~isempty(dimensions) && numel(value) == prod(dimensions)
                value = reshape(value, dimensions);
            end
            param.Value = value;
            param.DataType = dataType;
            param.CoderInfo.StorageClass = 'Custom';
            param.CoderInfo.CustomStorageClass = 'ConstVolatile';
            param.CoderInfo.CustomAttributes.HeaderFile = append(headerName, ".h");
            param.CoderInfo.CustomAttributes.DefinitionFile = append(headerName, ".c");


            persistent choiceAll;
            persistent lastTimeSeconds;
            if isempty(choiceAll)
                choiceAll = int16(0);
                % 获取当前时间
                lastTimeSeconds = datetime('now');
            end
        
            nowTimeSeconds = datetime('now');
            % 检查变量是否已存在
            codeStr = append("exist('", name, "', 'var')");
            if (evalin('base', codeStr) == 0)
                assignin('base', name, param);
            elseif force
                msgH = sprintf('<a href="matlab:eval(''%s'')">%s</a>', string(name), string(name));
                msg = append("变量 ", msgH, " 已存在. 强制覆盖它.");
                disp(msg);
                assignin('base', name, param);
            else
                if (choiceAll == 1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    msgH = sprintf('<a href="matlab:eval(''%s'')">%s</a>', string(name), string(name));
                    msg = append("变量 ", msgH, " 已存在. 选择覆盖它.");
                    disp(msg);
                    assignin('base', name, param);
                elseif (choiceAll == -1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    msgH = sprintf('<a href="matlab:eval(''%s'')">%s</a>', string(name), string(name));
                    msg = append("变量 ", msgH, " 已存在. 选择不覆盖它.");
                    disp(msg);
                else
                    choiceAll = int16(0);
                    evalin('base', name)
                    questStr = append("变量 ", name, " 已存在. 是否覆盖?                                ");
                    choice = myOp.slx.std.menuCentered(questStr, {'AllYes', 'AllNo', 'Yes', 'No'});
                    switch choice
                        case 1
                            choiceAll = int16(1);
                            assignin('base', name, param);
                        case 2
                            choiceAll = int16(-1);
                        case 3
                            assignin('base', name, param);
                        case 4
                            return;
                    end
                end
                lastTimeSeconds = datetime('now');
            end
        end

        function createStdSig(name, dataType, headerName, opts)
        %   创建标准信号
        %   createStdSig(name, dataType, headerName, opts)
        %
        %   输入:
        %       name - 信号名
        %       dataType - 信号数据类型
        %       headerName - 头文件名
        %       opts - 可选参数
        %           force - 是否强制覆盖已存在的变量, 默认为 false

            arguments
                name {mustBeText};
                dataType {mustBeText} = '';
                headerName {mustBeText} = '';
                opts.force (1, 1) {mustBeNumericOrLogical} = false;
            end

            force = opts.force;

            if isempty(dataType)
                dataType = myOp.slx.std.guessDataType(name);
            end

            if isempty(headerName)
                % headerName = getfullname(bdroot);
                headerName_h = '';
                headerName_c = '';
            else
                headerName_h = append(headerName, ".h");
                headerName_c = append(headerName, ".c");
            end

            % 创建 Simulink.Signal
            param = Simulink.Signal;
            param.DataType = dataType;
            param.CoderInfo.StorageClass = 'Custom';
            param.CoderInfo.CustomStorageClass = 'ExportToFile';
            param.CoderInfo.CustomAttributes.HeaderFile = headerName_h;
            param.CoderInfo.CustomAttributes.DefinitionFile = headerName_c;


            persistent choiceAll;
            persistent lastTimeSeconds;
            if isempty(choiceAll)
                choiceAll = int16(0);
                % 获取当前时间
                lastTimeSeconds = datetime('now');
            end
        
            nowTimeSeconds = datetime('now');
            % 检查变量是否已存在
            codeStr = append("exist('", name, "', 'var')");
            if (evalin('base', codeStr) == 0)
                assignin('base', name, param);
            elseif force
                msgH = sprintf('<a href="matlab:eval(''%s'')">%s</a>', string(name), string(name));
                msg = append("变量 ", msgH, " 已存在. 强制覆盖它.");
                disp(msg);
                assignin('base', name, param);
            else
                if (choiceAll == 1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    msgH = sprintf('<a href="matlab:eval(''%s'')">%s</a>', string(name), string(name));
                    msg = append("变量 ", msgH, " 已存在. 选择覆盖它.");
                    disp(msg);
                    assignin('base', name, param);
                elseif (choiceAll == -1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    msgH = sprintf('<a href="matlab:eval(''%s'')">%s</a>', string(name), string(name));
                    msg = append("变量 ", msgH, " 已存在. 选择不覆盖它.");
                    disp(msg);
                else
                    choiceAll = int16(0);
                    evalin('base', name)
                    questStr = append("变量 ", name, " 已存在. 是否覆盖?                               ");
                    choice = myOp.slx.std.menuCentered(questStr, {'AllYes', 'AllNo', 'Yes', 'No'});
                    switch choice
                        case 1
                            choiceAll = int16(1);
                            assignin('base', name, param);
                        case 2
                            choiceAll = int16(-1);
                        case 3
                            assignin('base', name, param);
                        case 4
                            return;
                    end
                end
                lastTimeSeconds = datetime('now');
            end
        end

        function dataType = guessDataType(name)
        %   猜测变量的数据类型
            dataTypeIndexName = {...
                "bo", ...
                "i", ...
                "u", ...
                "f", ...
            };
            dataTypeIndexName = dataTypeIndexName(:);
            % 数据类型列表
            dataTypeList = {...
                'boolean', ...
                'int16', ...
                'uint16', ...
                'single', ...
            };
            dataTypeList = dataTypeList(:);

            isGuessDone = false;

            try
                % 将 name 以 '_' 分割
                nameSplit = split(name, '_');
                % 取第三份
                parLastName = nameSplit{3};

                % 如果 parLastName 以 dataTypeIndexName 中的任意一个开头(区分大小写), 则取出对应的数据类型
                for i = 1:length(dataTypeIndexName)
                    if startsWith(parLastName, dataTypeIndexName{i})
                        dataType = dataTypeList{i};
                        isGuessDone = true;
                        break;
                    end
                end
            catch
                % 如果 name 不符合规范, 则报错
                errorMsg = append("createStdParam: 数据类型 为空, 且 变量名 <", name, "> 不规范, 请手动指定数据类型.");
                error(errorMsg);
            end

            if isGuessDone
                return;
            end

            % 给 dataTypeIndexName 添加前缀"c"
            for i = 1:length(dataTypeIndexName)
                dataTypeIndexName{i} = append('c', dataTypeIndexName{i});
            end

            try
                % 将 name 以 '_' 分割
                nameSplit = split(name, '_');
                % 取第三份
                parLastName = nameSplit{3};

                % 如果 parLastName 以 dataTypeIndexName 中的任意一个开头(区分大小写), 则取出对应的数据类型
                for i = 1:length(dataTypeIndexName)
                    if startsWith(parLastName, dataTypeIndexName{i})
                        dataType = dataTypeList{i};
                        isGuessDone = true;
                        break;
                    end
                end
            catch
                % 如果 name 不符合规范, 则报错
                errorMsg = append("createStdParam: 数据类型 为空, 且 变量名 <", name, "> 不规范, 请手动指定数据类型.");
                error(errorMsg);
            end

            if isGuessDone
                return;
            end
        end

        function choice = menuCentered(questStr, labels)
        % 显示一个居中在屏幕的模态对话框，返回所选按钮索引
            if nargin < 2 || isempty(labels)
                labels = {"OK"};
            end
            if ~iscell(labels)
                labels = cellstr(labels);
            end

            screenSize = get(0, 'ScreenSize'); % [left bottom width height]
            dlgW = max(300, 120 * numel(labels));
            dlgH = 120;
            posX = floor((screenSize(3) - dlgW) / 2);
            posY = floor((screenSize(4) - dlgH) / 2);

            % f = figure("Visible", "off");
            d = dialog('Name', questStr, 'WindowStyle', 'modal', ...
                'Position', [posX posY dlgW dlgH], ...
                'CloseRequestFcn', @(s,e) onClose());
            uicontrol('Parent', d, 'Style', 'text', 'String', questStr, 'HorizontalAlignment', 'center', 'Position', [10 dlgH-60 dlgW-20 40]);

            btnGap = 10;
            totalGap = (numel(labels) + 1) * btnGap;
            btnW = floor((dlgW - totalGap) / numel(labels));
            btnH = 30;
            btnY = 10;
            btnX = btnGap;

            choice = 0;
            for i = 1:numel(labels)
                uicontrol('Parent', d, 'Style', 'pushbutton', 'String', labels{i}, 'Position', [btnX btnY btnW btnH], 'Callback', @(s,e) onClick(i));
                btnX = btnX + btnW + btnGap;
            end

            function onClick(idx)
                choice = idx;
                uiresume(d);
            end

            function onClose()
                choice = 0;
                uiresume(d);
            end

            uiwait(d);
            if isvalid(d)
                delete(d);
            end
            drawnow;
            if desktop('-inuse')
                commandwindow;
            end
            % close(f);
        end
    
        function ctParDataType = getCtParDataType()
        %   获取 Simulink 的标定参数的数据类型
            ctParDataType = {...
                'Simulink.Parameter'; ...
                'Simulink.LookupTable'; ...
            };
        end

        function parNames = ctParSort(parNames)
        %   对标定参数进行排序
            
            if ~iscell(parNames)
                parNames = {parNames};
            end

            parsFirst = cell(length(parNames), 1);
            parsSecond = cell(length(parNames), 1);
            parsThird = cell(length(parNames), 1);

            for i = 1:length(parNames)
                par = parNames{i};
                parSplit = split(par, '_');
                if length(parSplit) >= 3
                    parFirst = parSplit{1};
                    parSecond = parSplit{2};
                    parThird = parSplit{3};
                elseif length(parSplit) >= 2
                    parFirst = parSplit{1};
                    parSecond = parSplit{2};
                    parThird = '';
                elseif length(parSplit) >= 1
                    parFirst = parSplit{1};
                    parSecond = '';
                    parThird = '';
                end
                parsFirst{i} = parFirst;
                parsSecond{i} = parSecond;
                parsThird{i} = parThird;
            end

            % 先预处理 parsThird 中的数据
            for i = 1:length(parsThird)
                parThird = parsThird{i};
                
                % 如果 parThird 以字符 'c' 开头
                if ~startsWith(parThird, 'c')
                    continue;
                end
                % 如果 parThird 以以下字符串开头, 则去掉对应开头, 区分大小写
                head = {...
                    'cbo'; ...
                    'cf'; ...
                    'cu'; ...
                    'ci'; ...
                    'ca'; ...
                    'c'; ...
                };
                for j = 1:length(head)
                    if startsWith(parThird, head{j})
                        parThird = strrep(parThird, head{j}, '');
                        break;
                    end
                end
                parsThird{i} = parThird;
            end


            % 按照1,2,3的优先级排序, 1相同的情况下放在一起, 在1相同的情况下按照2排序, 2相同的情况下按照3排序
            [~, idx] = sortrows([parsFirst, parsSecond, parsThird]);

            parNames = parNames(idx);
        end

        function varargout = createStdBus(opts)
        % 创建总线
            arguments
                opts.name {mustBeText} = '';
                opts.elementNames = [];
                opts.elementTypes = [];
                opts.elementDimensions = [];
                opts.headerName = append(getfullname(bdroot), "_Bus");
            end
            
            bus = Simulink.Bus;
            bus.DataScope = "Exported";
            bus.HeaderFile = append(opts.headerName, ".h");

            if ~isempty(opts.elementNames) || ~isempty(opts.elementTypes) || ~isempty(opts.elementDimensions)
                if length(opts.elementNames) ~= length(opts.elementTypes) || length(opts.elementNames) ~= length(opts.elementDimensions)
                    error("createStdBus: 元素名称, 类型, 维度, 的长度必须相同.");
                end
                if ~isempty(opts.elementNames)
                    bus.Elements = Simulink.BusElement.empty(length(opts.elementNames), 0);
                    for i = 1:length(opts.elementNames)
                        bus.Elements(i) = Simulink.BusElement;
                        bus.Elements(i).Name = opts.elementNames{i};
                    end
                end
                if ~isempty(opts.elementTypes)
                    for i = 1:length(opts.elementTypes)
                        bus.Elements(i).DataType = opts.elementTypes{i};
                    end
                end
                if ~isempty(opts.elementDimensions)
                    for i = 1:length(opts.elementDimensions)
                        bus.Elements(i).Dimensions = opts.elementDimensions{i};
                    end
                end
            end
            if nargout == 1
                varargout{1} = bus;
            else
                if isequal(opts.name, '')
                    error("createStdBus: 当没有输出参数时, name 不能为空.");
                else
                    assignin('base', opts.name, bus);
                end
            end
        end

    end
end
