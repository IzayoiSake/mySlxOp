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
                warning('Variable %s already exists. Force Overwriting it.', name);
                assignin('base', name, param);
            else
                if (choiceAll == 1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    warning('Variable %s already exists. But choose to overwrite it.', name);
                    assignin('base', name, param);
                elseif (choiceAll == -1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    warning('Variable %s already exists. But choose not to overwrite it.', name);
                else
                    choiceAll = int16(0);
                    evalin('base', name)
                    questStr = append("Variable ", name, " already exists. Do you want to overwrite it?");
                    choice = menu(questStr, 'AllYes', 'AllNo', 'Yes', 'No');
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
                headerName = getfullname(bdroot);
            end

            % 创建 Simulink.Signal
            param = Simulink.Signal;
            param.DataType = dataType;
            param.CoderInfo.StorageClass = 'Custom';
            param.CoderInfo.CustomStorageClass = 'ExportToFile';
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
                warning('Variable %s already exists. Force Overwriting it.', name);
                assignin('base', name, param);
            else
                if (choiceAll == 1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    warning('Variable %s already exists. But choose to overwrite it.', name);
                    assignin('base', name, param);
                elseif (choiceAll == -1 && (nowTimeSeconds - lastTimeSeconds) < seconds(5))
                    warning('Variable %s already exists. But choose not to overwrite it.', name);
                else
                    choiceAll = int16(0);
                    evalin('base', name)
                    questStr = append("Variable ", name, " already exists. Do you want to overwrite it?");
                    choice = menu(questStr, 'AllYes', 'AllNo', 'Yes', 'No');
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

    end
end