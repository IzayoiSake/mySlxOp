
classdef mySlxOp

    methods(Static)

        %% 当前系统的Object的基础功能
        function block = checkBlock(block)
            if ~exist('block', 'var')
                block = find_system(gcs, 'SearchDepth', 1, 'Type', 'block', 'Selected', 'on');
                % 排除gcs自己
                block = block(~strcmp(block, gcs));
            end
            if isempty(block)
                block = find_system(gcs, 'SearchDepth', 1, 'Type', 'block', 'Selected', 'on');
                % 排除gcs自己
                block = block(~strcmp(block, gcs));
            end
            if isempty(block)
                block = {};
                return;
            end
            block = mySlxOp.parseBlock(block);
        end

        function classObject = returnSelf()
            % returnSelf 返回 mySlxOp 类的实例
            %
            % Output:
            %   classObject (mySlxOp) - mySlxOp 类的对象实例
            classObject = mySlxOp;
        end


        function block = parseBlock(block)
            if isempty(block)
                error('parseBlock: Block is empty.');
            end
            if ~iscell(block)
                if ischar(block) && ~isstring(block)
                    block = {block};
                else
                    block = mat2cell(block, ones(1, numel(block)));
                end
            end
            for i = 1:length(block)
                try
                    block{i} = get_param(block{i}, 'Object');
                catch
                    block{i} = get_param(block{i}.Handle, 'Object');
                end
            end
        end


        function line = checkLine(line)
            if ~exist('line', 'var')
                line = find_system(gcs, 'SearchDepth', 1, 'findAll', 'on', 'Type', 'line', 'Selected', 'on');
            end
            if isempty(line)
                line = find_system(gcs, 'SearchDepth', 1, 'findAll', 'on', 'Type', 'line', 'Selected', 'on');
            end
            if isempty(line)
                line = {};
                return;
            end
            line = mySlxOp.parseLine(line);
        end


        function line = parseLine(line)
            if isempty(line)
                error('parseLine: Line is empty.');
            end
            if ~iscell(line)
                if ischar(line) && ~isstring(line)
                    line = {line};
                else
                    line = mat2cell(line, ones(1, numel(line)));
                end
            end
            for i = 1:length(line)
                try
                    line{i} = get_param(line{i}, 'Object');
                catch
                    line{i} = get_param(line{i}.Handle, 'Object');
                end
            end
        end


        %% Bus Creator/Selector的相关功能
        function outNames = busBlockGetElementNames(opts)
        %   获取BusSelector或BusCreator中的被使用的元素名
        %   outNames = busBlockGetElementNames(opts)
        %
        %   输入:
        %       block - 模型中的 block 路径或句柄或者 block 对象, 如果不指定则默认为当前选择的 block
        %
        %   输出:
        %       outNames - 所有 Bus 被使用的元素名的 cell 数组
        
            arguments
                opts.block = '';
            end

            block = opts.block;
        
            block = mySlxOp.checkBlock(block);

            outNames = cell(0);
            
            for i = 1:length(block)
                thisBlock = block{i};
                % 如果是 Bus Selector
                if strcmp(thisBlock.BlockType, 'BusSelector')
                    % 获取outputsignalnames
                    outputSignals = get_param(thisBlock.Handle, 'OutputSignals');
                    outputSignalNames = split(outputSignals, ',');
                    outputSignalNames = cellstr(outputSignalNames);
                    outNames = [outNames; outputSignalNames];
                end
                % 如果是 Bus Creator
                if strcmp(thisBlock.BlockType, 'BusCreator')
                    % 获取inputsignalnames
                    inputSignalNames = get_param(thisBlock.Handle, 'InputSignalNames');
                    inputSignalNames = cellstr(inputSignalNames);
                    outNames = [outNames; inputSignalNames];
                end
            end
            outNames = outNames(:);
        end


        % function dataType = busBlockGetElementDataType(opts)
        % %   获取BusSelector或BusCreator中使用的元素的数据类型
        % %   dataType = busBlockGetElementDataType(opts)
        % %
        % %   输入:
        % %       block - 模型中的 block 路径或句柄或者 block 对象, 如果不指定则默认为当前选择的 block
        % %
        % %   输出:
        % %       dataType - 所有 Bus 被使用的元素的数据类型的 cell 数组

        %     arguments
        %         opts.block = '';
        %     end

        %     block = opts.block;

        %     block = mySlxOp.checkBlock(block);

        %     % 获取顶层模型
        %     topModel = bdroot(block{1}.Handle);
        %     topModel = getfullname(topModel);
        %     % 创建仿真器
        %     simModel = simulation(topModel);
        %     % 查看顶层模型是否已经被其他程序(函数)运行处于仿真状态
        %     isOtherSiming = true;
        %     simStatus = get_param(topModel, 'SimulationStatus');
        %     if strcmp(simStatus, 'stopped')
        %         isOtherSiming = false;
        %         warning('off', 'all');
        %         step(simModel);
        %         warning('on', 'all');
        %     end

        %     dataType = cell(0);
        %     for i = 1:length(block)
        %         thisBlock = block{i};
        %         % 如果是 Bus Selector
        %         if strcmp(thisBlock.BlockType, 'BusSelector')
        %             % 获取selectBlockObj 的编译后的数据类型
        %             thisBlockDataType = get_param(thisBlock.Handle, 'CompiledPortDataTypes');
        %             thisBlockDataType = thisBlockDataType.Outport;
        %             if ~iscell(thisBlockDataType)
        %                 thisBlockDataType = cellstr(thisBlockDataType);
        %             end
        %             thisBlockDataType = thisBlockDataType(:);
        %             dataType = [dataType; thisBlockDataType];
        %         end
        %         % 如果是 Bus Creator
        %         if strcmp(thisBlock.BlockType, 'BusCreator')
        %             % 获取selectBlockObj 的编译后的数据类型
        %             thisBlockDataType = get_param(thisBlock.Handle, 'CompiledPortDataTypes');
        %             thisBlockDataType = thisBlockDataType.Inport;
        %             if ~iscell(thisBlockDataType)
        %                 thisBlockDataType = cellstr(thisBlockDataType);
        %             end
        %             thisBlockDataType = thisBlockDataType(:);
        %             dataType = [dataType; thisBlockDataType];
        %         end
        %     end

        %     if ~isOtherSiming
        %         % 关闭仿真器
        %         stop(simModel);
        %     end

        % end


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
                name (1, :) {mustBeText};
                value = 0;
                dataType (1, :) {mustBeText} = '';
                opts.headerName (1, :) {mustBeText} = append(getfullname(bdroot), "_Para");
                opts.force (1, 1) {mustBeNumericOrLogical} = false;
            end

            headerName = opts.headerName;
            force = opts.force;
            
            if isempty(dataType)
                % 数据类型索引名
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
                            break;
                        end
                    end
                catch
                    % 如果 name 不符合规范, 则报错
                    errorMsg = append("createStdParam: 数据类型 为空, 且 变量名 <", name, "> 不规范, 请手动指定数据类型.");
                    error(errorMsg);
                end
            end

            % 创建 Simulink.Parameter
            param = Simulink.Parameter;
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
                name (1, :) {mustBeText};
                dataType (1, :) {mustBeText} = '';
                headerName (1, :) {mustBeText} = '';
                opts.force (1, 1) {mustBeNumericOrLogical} = false;
            end

            force = opts.force;

            if isempty(dataType)
                % 数据类型索引名
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
                try
                    % 将 name 以 '_' 分割
                    nameSplit = split(name, '_');
                    % 取第三份
                    parLastName = nameSplit{3};

                    % 如果 parLastName 以 dataTypeIndexName 中的任意一个开头(区分大小写), 则取出对应的数据类型
                    for i = 1:length(dataTypeIndexName)
                        if startsWith(parLastName, dataTypeIndexName{i})
                            dataType = dataTypeList{i};
                            break;
                        end
                    end
                catch
                    % 如果 name 不符合规范, 则报错
                    errorMsg = append("createStdSig: 数据类型 为空, 且 变量名 <", name, "> 不规范, 请手动指定数据类型.");
                    error(errorMsg);
                end
            end

            if isempty(headerName)
                headerName = getfullname(bdroot);
            end

            % 创建 Simulink.Signal
            param = Simulink.Signal;
            param.DataType = dataType;
            param.CoderInfo.StorageClass = 'Custom';
            param.CoderInfo.CustomStorageClass = 'ExportToFile';
            param.CoderInfo.CustomAttributes.HeaderFile = [headerName, '.h'];
            param.CoderInfo.CustomAttributes.DefinitionFile = [headerName, '.c'];


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
        
        
        %% 控制参数的相关功能
        function [parNames, parValues] = getCtrlParofSys(opts)

            arguments
                opts.block = '';
            end

            block = opts.block;

            block = mySlxOp.checkBlock(block);

            % 控制参数的数据类型
            ctrlParDataTypes = {...
                'Simulink.Parameter', ...
                'Simulink.LookupTable', ...
            };
            ctrlParDataTypes = ctrlParDataTypes(:);
            
            % 从基础工作空间中获取所有的变量
            allVars = evalin('base', 'whos');

            % 筛选出所有的控制参数
            ctrlParNames = {};
            for i = 1:length(allVars)
                varName = allVars(i).name;
                varType = allVars(i).class;
                if ismember(varType, ctrlParDataTypes)
                    ctrlParNames = [ctrlParNames; varName];
                end
            end

            % 在sysPath下查找所有 任意属性是ctrlParNames的block
            sysCtrlParNames = {};
            for i = 1:length(block)
                for j = 1:length(ctrlParNames)
                    searchBlocks = find_system(...
                        block{i}.Handle, ...
                        'FindAll', 'on', ...
                        'LookUnderMasks', 'all', ...
                        'RegExp', 'on', ...
                        'BlockDialogParams', append('.*', ctrlParNames{j}, '.*') ...
                    );
                    if ~isempty(searchBlocks)
                        sysCtrlParNames = [sysCtrlParNames; ctrlParNames{j}];
                    end
                end
            end
            sysCtrlParNames = unique(sysCtrlParNames);
            parNames = sysCtrlParNames;
            parNames = mySlxOp.ctrlParSort(parNames);
            parValues = cell(length(parNames), 1);
            for i = 1:length(parNames)
                tempVar = evalin('base', parNames{i});
                try
                    parValues{i} = tempVar.Value;
                catch
                    try
                        parValues{i} = tempVar;
                    catch
                        parValues{i} = 'Error';
                    end
                end
            end
        end


        function addOvrdParFunc(opts)

            arguments
                opts.line = '';
                opts.isParamAdd = false;
            end

            line = opts.line;
            isParamAdd = opts.isParamAdd;

            line = mySlxOp.checkLine(line);

            if isParamAdd
                mySlxOp.logAllLine("onlyRead", true);
            end

            for i = 1:length(line)
                thisLine = line{i};
                % 获取源端口和目标端口
                srcPort = get_param(thisLine.Handle, 'SrcPortHandle');
                dstPort = get_param(thisLine.Handle, 'DstPortHandle');
                try
                    srcPort = mySlxOp.parseBlock(srcPort);
                catch
                    srcPort = {};
                end
                try
                    dstPort = mySlxOp.parseBlock(dstPort);
                catch
                    dstPort = {};
                end
                % 获取源端口和目标端口的父模块
                parentBlocks = cell(length(srcPort) + length(dstPort), 1);
                for j = 1:length(srcPort)
                    parentBlocks{j} = get_param(srcPort{j}.Handle, 'Parent');
                end
                for j = 1:length(dstPort)
                    parentBlocks{length(srcPort) + j} = get_param(dstPort{j}.Handle, 'Parent');
                end
                parentBlocks = unique(parentBlocks);
                parentBlocks = mySlxOp.parseBlock(parentBlocks);
                
                for j = 1:length(parentBlocks)
                    parentBlock = parentBlocks{j};
                    % 查看是否是一个名字以 "Ovrd" 开头的 SubSystem
                    if mySlxOp.isSubsystem(parentBlock) && startsWith(parentBlock.Name, 'Ovrd')
                        % 搜寻switch模块
                        switchBlock = find_system(parentBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Switch');
                        if isempty(switchBlock)
                            continue;
                        end
                        switchBlock = mySlxOp.parseBlock(switchBlock);
                        switchBlock = switchBlock{1};
                        switchBlock = mySlxOp.parseBlock(switchBlock);
                        % 获取switch模块的输入端口连接的block
                        consBlock = mySlxOp.getLastBlock('block', switchBlock, 'portNum', 1);
                        consOvrdBlock = mySlxOp.getLastBlock('block', switchBlock, 'portNum', 2);

                        parName = line{i}.Name;
                        parName = strrep(parName, '<', '');
                        parName = strrep(parName, '>', '');
                        % 以'_'将其分割成三份
                        try
                            parNamesplit = split(parName, '_');
                            % 第三份前面加上'c'
                            parNamesplit{3} = append('c', parNamesplit{3});
                            % 重新拼接
                            parName = join(parNamesplit, '_');
                            parName = parName{1};
                            parOvrdName = parName;
                            % 替换第三份的前几个小写字母(从第一个字母开始, 遇到大写字母停止), 将整段小写字符串替换为'cbo'
                            parOvrdNameSplit = split(parOvrdName, '_');
                            parOvrdNameSplit{3} = regexprep(parOvrdNameSplit{3}, '^[a-z]+', 'cbo');
                            parOvrdName = join(parOvrdNameSplit, '_');
                            parOvrdName = parOvrdName{1};
                            parOvrdName = append(parOvrdName, 'Ovrd');
                            % 修改consBlock的Value为对应的parName
                            consBlock = consBlock{1};
                            set_param(consBlock.Handle, 'Value', parName);
                            % 修改consOvrdBlock的Value为对应的parOvrdName
                            consOvrdBlock = consOvrdBlock{1};
                            set_param(consOvrdBlock.Handle, 'Value', parOvrdName);

                            if isParamAdd
                                % 从基础工作区中查看是否parName存在
                                if evalin('base', ['exist(''', parName, ''', ''var'')']) == 0
                                    dataType = mySlxOp.getLineDataType('line', thisLine);
                                    dataType = dataType{1};
                                    if strcmp(dataType, 'Error')
                                        dataType = 'double';
                                    end
                                    mySlxOp.createStdParam(parName, 0, dataType);
                                end
                                % 从基础工作区中查看是否parOvrdName存在
                                if evalin('base', ['exist(''', parOvrdName, ''', ''var'')']) == 0
                                    dataType = 'boolean';
                                    mySlxOp.createStdParam(parOvrdName, 0, dataType);
                                end
                            end

                        catch
                            continue;
                        end
                    else
                        continue;
                    end
                end
            end
        end


        function pars = ctrlParSort(pars)

            if ~iscell(pars)
                pars = {pars};
            end

            parsFirst = cell(length(pars), 1);
            parsSecond = cell(length(pars), 1);
            parsThird = cell(length(pars), 1);

            for i = 1:length(pars)
                par = pars{i};
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

            pars = pars(idx);
        end


        function clearedVars = clearMat(opts)
        % 清除基础工作区中的无用的变量

            arguments
                opts.modelName = '';
                opts.hwParFilePath = '';
                opts.ctrlParFilePath = '';
            end

            clearedVars = {};
            % 读取工作区中的所有变量
            vars = evalin('base', 'who');
            % 获取当前模型的名称
            if isempty(opts.modelName)
                opts.modelName = bdroot;
            end
            opts.modelName = bdroot;
            if isempty(opts.modelName)
                disp('没有打开模型, 请先打开一个模型');
                return;
            end
            function [hwParData, hwParFilePath] = readHWPar(hwParFilePath)
                if isempty(hwParFilePath)
                    % 如果没有传入 hwParFilePath, 则让用户选择
                    [hwParFileName, hwParFileDir] = uigetfile('*.xlsx;*.xls', '选择HW数据文件');
                    hwParFilePath = fullfile(hwParFileDir, hwParFileName);
                    if isempty(hwParFilePath)
                        return;
                    end
                end
                hwParData = readtable(hwParFilePath);
            end
            function [ctrlParData, ctrlParFilePath] = readCtrlPar(ctrlParFilePath)
                if isempty(ctrlParFilePath)
                    [ctrlParFileName, ctrlParFileDir] = uigetfile('*.xlsx;*.xls', '选择Ctrl数据文件');
                    ctrlParFilePath = fullfile(ctrlParFileDir, ctrlParFileName);
                    % ctrlParFilePath = 'D:\Projects\01_CM60\03_AFE\CtrlPar\CtrlPar02_Afe\CtrlPar02_Afe.xlsx';
                    if isempty(ctrlParFilePath)
                        return;
                    end
                end
                ctrlParData = readtable(ctrlParFilePath);
            end
            % % 读取CtrlPar和HWPar数据(用户选择Excel文件)
            [ctrlParData, ctrlParFilePath] = readCtrlPar(opts.ctrlParFilePath);
            if isempty(ctrlParFilePath)
                return;
            end
            [hwParData, hwParFilePath] = readHWPar(opts.hwParFilePath);
            if isempty(hwParFilePath)
                return;
            end

            % 从系统获取一个临时文件
            tempMdlFilePath = tempname;
            tempMdlFilePath = append(tempMdlFilePath, '.xml');
            % 将当前模型保存到临时文件, 以xml格式
            save_system(opts.modelName, tempMdlFilePath, 'OverwriteIfChangedOnDisk', true, 'ExportToXML', true);
            % 以文本格式读取临时文件
            tempMdlText = fileread(tempMdlFilePath);
            % 删除临时文件
            delete(tempMdlFilePath);

            disp('初始化完成, 开始清除变量...');

            % 清除工作区中的无用变量
            for i = 1:length(vars)
                varName = vars{i};
                isClear = true;
                % 如果变量名在CtrlPar或HWPar中被使用,则不清除
                for j = 1:length(ctrlParData.param)
                    if ~isClear
                        break;
                    end
                    if contains(ctrlParData.param{j}, varName)
                        isClear = false;
                        break;
                    end
                end
                for j = 1:length(hwParData.param)
                    if ~isClear
                        break;
                    end
                    if contains(hwParData.param{j}, varName)
                        isClear = false;
                        break;
                    end
                end
                % 如果变量名在模型文本中被使用,则不清除
                if isClear && contains(tempMdlText, varName)
                    isClear = false;
                end

                if isClear
                    disp(['是否清除变量: ' varName]);
                    evalin('base', ['clear ' varName]);
                    clearedVars{end+1, 1} = varName;
                end
            end
        end


        %% 跟踪信号流的相关功能
        function [srcBlock, srcPortNum] = getLastBlock(opts)
            
            arguments
                opts.block = '';
                opts.portNum = 1;
                opts.lookUnderMask = false;
            end
        
            block = opts.block;
            portNum = opts.portNum;
            lookUnderMask = opts.lookUnderMask;
        
            % 处理 block
            block = mySlxOp.checkBlock(block);
            if isempty(block)
                error('block must contain at least one element.');
            end
            block = block{1};  % 取出第一个 block
            
            srcBlock = {};
            srcPortNum = {};
            % 如果 block 是 Simulink.BlockDiagram
            if isprop(block, 'BlockDiagramType') || isfield(block, 'BlockDiagramType') 
                return;
            % 如果 block 是 From 模块
            elseif strcmp(block.BlockType, 'From')
                tag = get_param(block.Handle, 'GotoTag');
                fatherBlock = get_param(block.Handle, 'Parent');
                gotoBlock = find_system(fatherBlock, 'SearchDepth', 1, 'BlockType', 'Goto', 'GotoTag', tag);
        
                if isempty(gotoBlock)
                    error('gotoBlock not found.');
                end
        
                gotoBlock = mySlxOp.checkBlock(gotoBlock);
                srcBlock = gotoBlock;  % 直接返回整个 cell 数组
                srcPortNum = num2cell(ones(length(gotoBlock), 1)); % 端口号全为 1
        
            % 如果是 Inport 模块
            elseif strcmp(block.BlockType, 'Inport')
                parentBlock = get_param(block.Handle, 'Parent');
                parentBlock = mySlxOp.checkBlock(parentBlock);
                parentBlock = parentBlock{1}; % 取出父模块
        
                parentBlockPortNum = get_param(block.Handle, 'Port');
                srcBlock = {parentBlock};
                srcPortNum = {double(parentBlockPortNum)};
        
            % 处理 lookUnderMask 逻辑
            elseif lookUnderMask
                [srcBlock, srcPortNum] = mySlxOp.getLastBlock('block', block, 'portNum', portNum, 'lookUnderMask', false);
                srcBlock = mySlxOp.checkBlock(srcBlock);
                if isempty(srcBlock)
                    error('No previous block found.');
                end
                srcBlock = srcBlock{1};  % 取第一个 block
                srcPortNum = srcPortNum{1};  % 取第一个 portNum
                if (strcmp(srcBlock.BlockType, 'SubSystem') && ~mySlxOp.isMatlabFunction(srcBlock))
                    srcBlock = find_system(srcBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Outport', 'Port', num2str(srcPortNum));
                    if isempty(srcBlock)
                        error('No Outport found in the SubSystem.');
                    end
                    srcBlock = mySlxOp.checkBlock(srcBlock);
                    srcPortNum = num2cell(ones(length(srcBlock), 1)); % 端口号全为 1
                end
        
            % 其他情况：获取普通块的输入端口连接
            else
                try
                    inports = get_param(block.Handle, 'PortHandles');
                    if isempty(inports.Inport) || length(inports.Inport) < portNum
                        error('Invalid port number for block: %s', block.Name);
                    end
                    inport = inports.Inport(portNum);
                    line = get_param(inport, 'Line');
        
                    if line == -1
                        error('No line connected to port %d of block %s', portNum, block.Name);
                    end
        
                    srcPort = get_param(line, 'SrcPortHandle');
                    if srcPort == -1
                        error('No source port found for the line.');
                    end
        
                    srcBlock = get_param(srcPort, 'Parent');
                    srcBlock = get_param(srcBlock, 'Handle');
                    srcBlock = mySlxOp.checkBlock(srcBlock);
                    srcPortNum = get_param(srcPort, 'PortNumber');
        
                    if ~isnumeric(srcPortNum)
                        srcPortNum = double(srcPortNum);
                    end
                catch ME
                    warning(ME.identifier, '%s', ME.message);
                    srcBlock = {};
                    srcPortNum = {};
                end                
            end
        
            % 确保输出是 cell 类型
            if ~iscell(srcBlock)
                srcBlock = {srcBlock};
            end
            if ~iscell(srcPortNum)
                srcPortNum = {srcPortNum};
            end
        end


        function [desBlock, desPortNum] = getNextBlock(opts)
            

            arguments
                opts.block = gcbh;
                opts.portNum = 1;
                opts.desNum = 'all';
                opts.lookUnderMask = false;
            end

            block = opts.block;
            portNum = opts.portNum;
            desNum = opts.desNum;
            lookUnderMask = opts.lookUnderMask;
        
            % 处理 block
            block = mySlxOp.checkBlock(block);
            if isempty(block)
                error('block must contain at least one element.');
            end
            block = block{1};  % 取出第一个 block


            desBlock = {};
            desPortNum = {};
            % 如果 block 是 Simulink.BlockDiagram
            if isprop(block, 'BlockDiagramType') || isfield(block, 'BlockDiagramType') 
                return;
            % 如果 block 是 Goto 模块
            elseif strcmp(block.BlockType, 'Goto')
                tag = get_param(block.Handle, 'GotoTag');
                fatherBlock = get_param(block.Handle, 'Parent');
                fromBlock = find_system(fatherBlock, 'SearchDepth', 1, 'BlockType', 'From', 'GotoTag', tag);
        
                if isempty(fromBlock)
                    error('fromBlock not found.');
                end
        
                fromBlock = mySlxOp.checkBlock(fromBlock);
                desBlock = fromBlock; % 直接返回所有匹配的 fromBlock
                desPortNum = num2cell(ones(length(fromBlock), 1)); % 端口号全为 1
        
            % 如果 block 是 Outport 模块
            elseif strcmp(block.BlockType, 'Outport')
                parentBlock = get_param(block.Handle, 'Parent');
                parentBlock = mySlxOp.checkBlock(parentBlock);
                parentBlock = parentBlock{1}; % 取出父模块
        
                parentBlockPortNum = get_param(block.Handle, 'Port');
                desBlock = {parentBlock};
                desPortNum = {double(parentBlockPortNum)};
            
            % 如果 lookUnderMask 为 true，查找子系统内部的连接
            elseif lookUnderMask
                [desBlock, desPortNum] = mySlxOp.getNextBlock('block', block, 'portNum', portNum, 'desNum', desNum, 'lookUnderMask', false);
                desBlock = mySlxOp.checkBlock(desBlock);
                if isempty(desBlock)
                    error('No next block found.');
                end
                tempBlock = desBlock{1};  % 取第一个 block
                tempPortNum = desPortNum{1};  % 取第一个端口号
                if strcmp(tempBlock.BlockType, 'SubSystem') && ~mySlxOp.isMatlabFunction(tempBlock)
                    tempBlock = find_system(tempBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Inport', 'Port', num2str(tempPortNum));
                    if isempty(tempBlock)
                        error('No Inport found in the SubSystem.');
                    end
                    desBlock = mySlxOp.checkBlock(tempBlock);
                    desPortNum = num2cell(ones(length(tempBlock), 1)); % 端口号全为 1
                end
        
            % 其他情况：获取普通块的输出端口连接
            else
                try
                    % 获取 block 的输出端口
                    outports = get_param(block.Handle, 'PortHandles');
                    if isempty(outports.Outport) || length(outports.Outport) < portNum
                        error('Invalid port number for block: %s', block.Name);
                    end
                    outport = outports.Outport(portNum);
                    line = get_param(outport, 'Line');
        
                    if isempty(line) || line == -1
                        error('No line connected to port %d of block %s', portNum, block.Name);
                    end
        
                    desPort = get_param(line, 'DstPortHandle');
                    if isempty(desPort)
                        error('No destination port found for block %s', block.Name);
                    end
        
                    % 处理 desNum: 'all' 返回所有端口，否则返回指定端口
                    if ischar(desNum) && strcmp(desNum, 'all')
                        selectedDesPorts = desPort; % 选取所有端口
                    elseif isnumeric(desNum) && length(desPort) >= desNum
                        selectedDesPorts = desPort(desNum); % 仅选取索引 desNum
                    else
                        error('Invalid desNum: must be ''all'' or a valid numeric index.');
                    end
        
                    % 获取所有目标块和端口号
                    desBlock = cell(size(selectedDesPorts));
                    desPortNum = cell(size(selectedDesPorts));
        
                    for i = 1:length(selectedDesPorts)
                        desBlock{i} = get_param(selectedDesPorts(i), 'Parent');
                        desBlock{i} = get_param(desBlock{i}, 'Handle');
                        desBlock(i) = mySlxOp.checkBlock(desBlock{i});
                        desPortNum{i} = get_param(selectedDesPorts(i), 'PortNumber');
                        if ~isnumeric(desPortNum{i})
                            desPortNum{i} = double(desPortNum{i});
                        end
                    end
                catch ME
                    warning(ME.identifier, '%s', ME.message);
                    desBlock = {};
                    desPortNum = {};
                end
            end
        
            % 确保输出是 cell 类型
            if ~iscell(desBlock)
                desBlock = {desBlock};
            end
            if ~iscell(desPortNum)
                desPortNum = {desPortNum};
            end
        end


        %% 信号线的相关功能
        function transLineName(opts)
        % 将一个block的输入信号线的名字转换为输出信号线的名字, 或者反之
            arguments
                opts.block = '';
                opts.direction = 'in';
            end

            block = opts.block;
            direction = opts.direction;

            block = mySlxOp.checkBlock(block);

            for i = 1: length(block)
                thisBlock = block{i};
                % 获取输入端口的名字
                inports = get_param(thisBlock.Handle, 'PortHandles');
                inports = inports.Inport;
                inport = inports(1);
                importName = get_param(inport, 'Name');
                % 获取输出端口的名字
                outports = get_param(thisBlock.Handle, 'PortHandles');
                outports = outports.Outport;
                outport = outports(1);
                outportName = get_param(outport, 'Name');
                % 如果direction为 in, 则将inport的名字赋给outport
                if strcmp(direction, 'in')
                    newName = strrep(importName, '<', '');
                    newName = strrep(newName, '>', '');
                    set_param(outport, 'Name', newName);
                else
                    newName = strrep(outportName, '<', '');
                    newName = strrep(newName, '>', '');
                    set_param(inport, 'Name', newName);
                end
            end
        end


        function [lineNames, lineDataTypes] = getObsSigofSys(opts)

            arguments
                opts.block = '';
                opts.line = '';
            end

            block = opts.block;
            line = opts.line;

            block = mySlxOp.checkBlock(block);
            line = mySlxOp.checkLine(line);


            for i = 1:length(block)
                thisBlock = block{i};
                if mySlxOp.isSubsystem(thisBlock)
                    thisBlockLine = find_system(thisBlock.Handle, 'FindAll', 'on', 'type', 'line');
                    thisBlockLine = mySlxOp.checkLine(thisBlockLine);
                    line = [line; thisBlockLine];
                end
            end

            % 获取所有的 "MustResolveToSignalObject" 属性为 true 的 line
            isReserved = false(length(line), 1);
            for i = 1:length(line)
                thisLine = line{i};
                if thisLine.MustResolveToSignalObject
                    isReserved(i) = true;
                end
            end
            line = line(isReserved);

            lineNames = cell(length(line), 1);
            lineDataTypes = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                lineName = get_param(thisLine.Handle, 'Name');

                % 尝试从基础工作空间中获取变量
                isExist = false;
                try
                    lineData = evalin('base', lineName);
                    isExist = true;
                catch
                    lineDataType = '';
                end
                if isExist
                    try
                        lineDataType = lineData.DataType;
                    catch
                        lineDataType = class(lineData);
                    end
                end
                lineNames{i} = lineName;
                lineDataTypes{i} = lineDataType;
            end 
        end


        function createSelectedSig(opts)
        % 创建选中的信号线的标准信号
            arguments
                opts.checkDataType = true;
            end
            checkDataType = opts.checkDataType;

            line = mySlxOp.checkLine();

            if isempty(line)
                return;
            end

            if checkDataType
                lineDataType = mySlxOp.getLineDataType('line', line);
                for i = 1:length(line)
                    thisLine = line{i};
                    sigName = get_param(thisLine.Handle, 'Name');
                    mySlxOp.createStdSig(sigName, lineDataType{i});
                    thisLine.MustResolveToSignalObject = true;
                end
            else
                for i = 1:length(line)
                    thisLine = line{i};
                    sigName = get_param(thisLine.Handle, 'Name');
                    mySlxOp.createStdSig(sigName);
                    thisLine.MustResolveToSignalObject = true;
                end
            end
        end

        
        function deleteSelectedSig(opts)

        %   删除选中的信号线
            arguments
                opts.line = '';
            end

            line = opts.line;

            line = mySlxOp.checkLine(line);

            if isempty(line)
                return;
            end

            for i = 1:length(line)
                thisLine = line{i};
                sigName = get_param(thisLine.Handle, 'Name');
                try
                    evalin('base', ['clear ', sigName]);
                catch
                end
                thisLine.MustResolveToSignalObject = false;
            end
        end


        function getSelectedLineName(opts)
        %   获取选中的线的名字
            arguments
                opts.line = '';
            end

            line = opts.line;

            line = mySlxOp.checkLine(line);

            if isempty(line)
                return;
            end

            for i = 1:length(line)
                thisLine = line{i};
                sigName = get_param(thisLine.Handle, 'Name');
                disp(sigName);
            end
        end

        
        function appendSelectedLineName(opts)
        %  给选中的信号线的名字添加后缀
            arguments
                opts.line = '';
                opts.suffix = '';
            end

            line = opts.line;
            suffix = opts.suffix;

            line = mySlxOp.checkLine(line);

            if isempty(line)
                return;
            end
            if isempty(suffix)
                suffix = input('请输入后缀: ', 's');
            end
            if isempty(suffix)
                return;
            end

            for i = 1:length(line)
                thisLine = line{i};
                sigName = get_param(thisLine.Handle, 'Name');
                sigNameSplit = split(sigName, '_');
                sigNameSplit = sigNameSplit(:);
                if strcmp(sigNameSplit{end}, suffix)
                    continue;
                end
                sigNameSplit = [sigNameSplit; suffix];
                newSigName = strjoin(sigNameSplit, '_');
                set_param(thisLine.Handle, 'Name', newSigName);
            end
        end


        function allLineOut = logAllLine(opts)
            
            arguments
                opts.onlyRead = false;
            end

            onlyRead = opts.onlyRead;

            persistent allLine;

            if isempty(allLine)
                onlyRead = false;
            end

            if onlyRead
                allLineOut = allLine;
                return;
            end

            % 获取当前顶层模型
            topModelPath = bdroot;
            topModelPath = getfullname(topModelPath);

            % 获取当前模型的所有线
            allLines = find_system(topModelPath, 'FindAll', 'on', 'type', 'line');
            allLines = mySlxOp.checkLine(allLines);

            fullId = mySlxOp.getLineFullId('line', allLines);

            % 创建仿真器
            % simModel = simulation(topModelPath);
            % 查看顶层模型是否已经被其他程序(函数)运行处于仿真状态
            isOtherSiming = true;
            simStatus = get_param(topModelPath, 'SimulationStatus');
            if strcmp(simStatus, 'stopped')
                isOtherSiming = false;
                warning('off', 'all');
                set_param(topModelPath, 'SimulationCommand', 'start');
                set_param(topModelPath, 'SimulationCommand', 'pause');
                warning('on', 'all');
            end

            lineDataType = cell(length(allLines), 1);

            for i = 1:length(allLines)
                thisLine = allLines{i};
                srcPort = thisLine.getSourcePort();

                dataType = srcPort.CompiledPortDataType;
                % 检查 dataType 是否是一个 Simulink.Bus类型
                if (mySlxOp.isSimulinkBusType(dataType))
                    dataType = append("Bus:", dataType);
                end
                % 检查 dataType 是否是一个 枚举类型
                if (mySlxOp.isSimulinkEnumType(dataType))
                    dataType = append("Enum:", dataType);
                end
                lineDataType{i} = dataType;
            end

            if ~isOtherSiming
                % 关闭仿真器
                set_param(topModelPath, 'SimulationCommand', 'stop');
            end

            % 清除基础工作区中的变量"out"
            evalin('base', 'clear out');

            allLine.dataType = lineDataType;
            allLine.fullId = fullId;
            allLineOut = allLine;
        end


        function fullId = getLineFullId(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = mySlxOp.checkLine(line);

            if isempty(line)
                return;
            end

            fullId = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                parentPath = get_param(thisLine.Handle, 'Parent');
                sourcePort = thisLine.SourcePort;

                fullId{i} = append(parentPath, '/', sourcePort);
            end
            fullId = fullId(:);
        end


        function [lineDataType] = getLineDataType(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = mySlxOp.checkLine(line);

            if isempty(line)
                return;
            end
            allLine = mySlxOp.logAllLine('onlyRead', true);
            lineFullId = mySlxOp.getLineFullId('line', line);

            % 检查allLine是否包含全部的lineFullId
            isOk = mySlxOp.checkAllLineLog('line', line);
            if ~isOk
                allLine = mySlxOp.logAllLine('onlyRead', false);
            end
            isOk = mySlxOp.checkAllLineLog('line', line);
            if ~isOk
                error(append("Error [getLineDataType]: there is a line not in allLineLog, please run mySlxOp.logAllLine() and check."));
            end

            lineDataType = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                thisLineFullId = lineFullId{i};
                index = find(contains(allLine.fullId, thisLineFullId));
                lineDataType{i} = allLine.dataType{index};
            end
        end


        % 检测allLineLog是否包含所需的line
        function isOk = checkAllLineLog(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = mySlxOp.checkLine(line);

            if isempty(line)
                return;
            end

            allLine = mySlxOp.logAllLine('onlyRead', true);
            lineFullId = mySlxOp.getLineFullId('line', line);

            isOk = true;
            for i = 1:length(line)
                thisLine = line{i};
                thisLineFullId = lineFullId{i};
                if ~any(contains(allLine.fullId, thisLineFullId))
                    isOk = false;
                    break;
                end
            end
        end


        %% GoTo / From 模块的相关功能
        function goFromflushLineName(opts)

            arguments
                opts.block = '';
            end

            block = opts.block;

            block = mySlxOp.checkBlock(block);

            if isempty(block)
                return;
            end

            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Goto')
                    % 获取Goto模块的名字
                    gotoName = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取Goto的输入端口
                    inports = get_param(thisBlock.Handle, 'PortHandles');
                    inports = inports.Inport;
                    inport = inports(1);
                    % 获取Goto的输入端口的连接线
                    line = get_param(inport, 'Line');
                    % 设置Line的名字为Goto模块的名字
                    set_param(line, 'Name', gotoName);
                end
                if strcmp(thisBlock.BlockType, 'From')
                    % 获取From模块的名字
                    fromName = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取From的输出端口
                    outports = get_param(thisBlock.Handle, 'PortHandles');
                    outports = outports.Outport;
                    outport = outports(1);
                    % 获取From的输出端口的连接线
                    line = get_param(outport, 'Line');
                    % 设置Line的名字为From模块的名字
                    set_param(line, 'Name', fromName);
                end
            end
        end





        %% 控制参数Excel表格处理的相关功能
        function loadExcelPar(opts)
            
            arguments
                opts.filePaths = '';
                opts.headerNames = '';
            end

            filePaths = opts.filePaths;
            headerNames = opts.headerNames;

            if isempty(filePaths)
                % 等待用户选择文件, 可多选
                [filenames, pathnames] = uigetfile('*.xlsx', '选择Excel文件', 'MultiSelect', 'on');
                if isequal(filenames, 0)
                    disp('用户取消了选择');
                    return;
                end
                filenames = cellstr(filenames);
                filePaths = cell(length(filenames), 1);
                for i = 1:length(filenames)
                    filePaths{i} = fullfile(pathnames, filenames{i});
                end
            else
                if ischar(filePaths) || isstring(filePaths)
                    filePaths = {filePaths};
                end
                filenames = cell(length(filePaths), 1);
                for i = 1:length(filePaths)
                    [~, filenames{i}, ~] = fileparts(filePaths{i});
                end
            end
            if ~isempty(headerNames)
                if (ischar(headerNames) || isstring(headerNames))
                    headerNames = {headerNames};
                end
            end

            for i = 1:length(filePaths)
                % 读取Excel文件
                data = readcell(fullfile(filePaths{i}));
                % 去除前2列
                newdata = data(:, 3:end);
                % 获取newdata的Header
                disp("------------------------------------");
                header = newdata(1, :);
                for j = 1:length(header)
                    disp(header{j});
                end
                disp("------------------------------------");
                disp(append("本文件: ", filenames{i}, " ", "参数名如上."));
                if isempty(headerNames)
                    disp("请选择要导入的参数名");
                    % 等待用户输入参数名
                    selectedHeader = input('请输入参数名: ', 's');
                else
                    selectedHeader = headerNames{i};
                end
                if ~contains(header, selectedHeader)
                    disp(append("Error: ", filenames{i}, " 文件 ", selectedHeader, " 不存在."));
                    continue;
                else
                    disp(append("已选择参数: ", selectedHeader));
                end
                % 获取选择的参数列
                selectedData = newdata(2:end, find(contains(header, selectedHeader)));
                dataName = data(2:end, 2);

                for j = 1:length(dataName)
                    try
                        thisDataName = dataName{j};
                        % 如果thisDataName包含"BreakPoints"字符串
                        isBreakPoints = contains(thisDataName, "Breakpoints");
                        if (isBreakPoints)
                            thisDataName = strrep(thisDataName, "Breakpoints", "");
                        end

                        workSpaceVar = evalin('base', thisDataName);

                        evalFunc = append("[", string(selectedData{j}), "]");

                        % 同步数据维度
                        if (isprop(workSpaceVar, 'Breakpoints') && isBreakPoints)
                            dim = size(workSpaceVar.Breakpoints.Value);
                        elseif isprop(workSpaceVar, 'Table')
                            dim = size(workSpaceVar.Table.Value);
                        elseif isprop(workSpaceVar, 'Value') || isfield(workSpaceVar, 'Value')
                            dim = size(workSpaceVar.Value);
                        elseif isnumeric(workSpaceVar)
                            dim = size(workSpaceVar);
                        end
                        if (length(dim) >= 2)
                            % 如果维度大于2, 则将evalFunc转换为多维数组
                            evalFunc = append("reshape(", evalFunc, ", ", "[", num2str(dim), "]", ")");
                        end

                        % 同步数据类型
                        if (isprop(workSpaceVar, 'Breakpoints') && isBreakPoints)
                            dataType = workSpaceVar.Breakpoints.DataType;
                        elseif isprop(workSpaceVar, 'Table')
                            dataType = workSpaceVar.Table.DataType;
                        elseif isprop(workSpaceVar, 'Value') || isfield(workSpaceVar, 'Value')
                            dataType = workSpaceVar.DataType;
                        elseif isnumeric(workSpaceVar)
                            dataType = class(workSpaceVar);
                        end
                        evalFunc = append(dataType, "(", evalFunc, ")");

                        % 赋值
                        if (isprop(workSpaceVar, 'Breakpoints') && isBreakPoints)
                            workSpaceVar.Breakpoints.Value = eval(evalFunc);
                        elseif isprop(workSpaceVar, 'Table')
                            workSpaceVar.Table.Value = eval(evalFunc);
                        elseif isprop(workSpaceVar, 'Value') || isfield(workSpaceVar, 'Value')
                            workSpaceVar.Value = eval(evalFunc);
                        elseif isnumeric(workSpaceVar)
                            workSpaceVar = eval(evalFunc);
                        end
                        assignin('base', thisDataName, workSpaceVar);
                    catch
                        disp(append("Error: ", dataName{j}));
                        continue;
                    end
                end
            end
        end
    
    
        function writeParExcelMsg(opts)

            arguments
                opts.slxPath = '';
                opts.xlsxPath = '';
            end
            
            slxPath = opts.slxPath;
            xlsxPath = opts.xlsxPath;

            if isempty(slxPath)
                slxPath = getfullname(bdroot);
                % 如果当前没有打开的模型
                if isempty(slxPath)
                    disp('当前没有打开的模型');
                    return;
                end
            end

            if isempty(xlsxPath)
                % 让用户选择文件
                [filename, pathname] = uigetfile('*.xlsx', '选择Excel文件');
                if isequal(filename, 0)
                    disp('用户取消了选择');
                    return;
                end
                xlsxPath = fullfile(pathname, filename);
            end

            % 读取Excel文件
            fileData = readcell(xlsxPath);
            % 第一行为表头
            header = fileData(1, :);
            data = fileData(2:end, :);
            % 表头 = 'param' 的列是变量名列, 获取变量名
            varNameCol = find(contains(header, 'param'));
            varName = data(:, varNameCol);
            % 表头 = '所属模块' 的列是所属模块列, 获取所属模块列
            moduleCol = find(contains(header, '所属模块'));
            if isempty(moduleCol)
                moduleCol = length(header) + 1;
                header{moduleCol} = '所属模块';
                data = [data, cell(size(data, 1), 1)];
            end
            % 表头 = '默认值' 的列是默认值列, 获取默认值列
            defaultValueCol = find(contains(header, '默认值'));
            if isempty(defaultValueCol)
                defaultValueCol = length(header) + 1;
                header{defaultValueCol} = '默认值';
                data = [data, cell(size(data, 1), 1)];
            end
            module = data(:, moduleCol);
            defaultValue = data(:, defaultValueCol);

            % 遍历变量名, 找到Slx模型中使用了该变量的block
            for i = 1:length(varName)
                name = varName{i};
                % 如果name以 Breakpoints 字符串结尾, 则去掉
                if endsWith(name, 'Breakpoints')
                    name = strrep(name, 'Breakpoints', '');
                end
                searchValue = name;
                % 在slx模型中搜索使用了该变量的block
                matchedBlocks = find_system(...
                    slxPath, ...
                    'FindAll', 'on', ...
                    'LookUnderMasks', 'all', ...
                    'RegExp', 'on', ...
                    'BlockDialogParams', searchValue ...
                );
                % 如果没有找到, 记录
                if isempty(matchedBlocks)
                    matchedBlocks = find_system(...
                        slxPath, ...
                        'FindAll', 'on', ...
                        'LookUnderMasks', 'all', ...
                        'IncludeCommented', 'on', ...
                        'RegExp', 'on', ...
                        'BlockDialogParams', searchValue ...
                    );
                    if isempty(matchedBlocks)
                        module{i} = '未使用';
                    else
                        module{i} = '被完全注释掉了';
                    end
                else
                    matchedBlocks = getfullname(matchedBlocks);
                    if ~iscell(matchedBlocks)
                        matchedBlocks = {matchedBlocks};
                    end
                    for j = 1:length(matchedBlocks)
                        matchedBlock = matchedBlocks{j};
                        % 最多保留前三层路径
                        matchedBlock = strsplit(matchedBlock, '/');
                        matchedBlock = matchedBlock(1:min(3, length(matchedBlock)));
                        matchedBlock = strjoin(matchedBlock, '/');
                        matchedBlocks{j} = matchedBlock;
                    end
                    % 去除重复的项
                    matchedBlocks = unique(matchedBlocks);
                    % 使用换行符连接
                    module{i} = strjoin(matchedBlocks, '\n');
                end
            end
            % 遍历变量名, 写入默认值
            for i = 1:length(varName)
                name = varName{i};
                try
                    actName = name;
                    if endsWith(name, 'Breakpoints')
                        actName = strrep(actName, 'Breakpoints', '');
                    end
                    var = evalin('base', actName);
                    if (isprop(var, 'Breakpoints') && endsWith(name, 'Breakpoints'))
                        varValue = var.Breakpoints.Value;
                        defaultValue{i} = strjoin(string(varValue), ',');
                    elseif isprop(var, 'Table')
                        varValue = var.Table.Value;
                        defaultValue{i} = strjoin(string(varValue), ',');
                    elseif isprop(var, 'Value') || isfield(var, 'Value')
                        varValue = var.Value;
                        defaultValue{i} = strjoin(string(varValue), ',');
                    elseif isnumeric(var)
                        defaultValue{i} = strjoin(string(var), ',');
                    end
                catch
                    disp(append("Error: ", "变量 ", name, " 处理失败."));
                    continue;
                end
            end

            % 将结果写入文件
            newData = data;
            newData(:, moduleCol) = module;
            newData(:, defaultValueCol) = defaultValue;
            newFileData = [header; newData];
            writecell(newFileData, xlsxPath);
        end


        function transPortNameFromTag(opts)
            
            arguments
                opts.block = '';
            end
            
            block = opts.block;

            block = mySlxOp.checkBlock(block);

            if isempty(block)
                block = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
                if isempty(block)
                    return;
                end
                if ~iscell(block)
                    block = {block};
                end
            end

            for i = 1:length(block)
                try
                    block{i} = getfullname(block{i});
                catch
                    block{i} = getfullname(block{i}.Handle);
                end
            end
            for i = 1:length(block)
                block{i} = get_param(block{i}, 'Object');
            end

            for i = 1:length(block)
                thisBlock = block{i};
                % 查看是否是From的block
                if strcmp(thisBlock.BlockType, 'From')
                    % 获取其连接的block
                    [desBlock, desPortMum] = mySlxOp.getNextBlock('block', thisBlock);
                    desBlock = desBlock{1};
                    desPortMum = desPortMum{1};
                    desBlock = get_param(desBlock, 'Object');
                    % 查看desBlock是不是个subsystem
                    if ~strcmp(desBlock.BlockType, 'SubSystem')
                        continue;
                    end
                    % 获取From的tag
                    tag = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取目的block的输入block, 端口号为desPortMum
                    inportBlocks = find_system(desBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Inport', 'Port', num2str(desPortMum));
                    if isempty(inportBlocks)
                        continue;
                    end
                    if ~iscell(inportBlocks)
                        inportBlocks = {inportBlocks};
                    end
                    inportBlocks = inportBlocks{1};
                    % 设置inportBlocks的名字为tag
                    set_param(inportBlocks, 'Name', tag);
                % 查看是否是Goto的block
                elseif strcmp(thisBlock.BlockType, 'Goto')
                    % 获取其连接的block
                    [srcBlock, srcPortMum] = mySlxOp.getLastBlock('block', thisBlock);
                    srcBlock = srcBlock{1};
                    srcPortMum = srcPortMum{1};
                    srcBlock = get_param(srcBlock, 'Object');
                    % 查看srcBlock是不是个subsystem
                    if ~strcmp(srcBlock.BlockType, 'SubSystem')
                        continue;
                    end
                    % 获取Goto的tag
                    tag = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取源block的输出block, 端口号为srcPortMum
                    outportBlocks = find_system(srcBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Outport', 'Port', num2str(srcPortMum));
                    if isempty(outportBlocks)
                        continue;
                    end
                    if ~iscell(outportBlocks)
                        outportBlocks = {outportBlocks};
                    end
                    outportBlocks = outportBlocks{1};
                    % 设置outportBlocks的名字为tag
                    set_param(outportBlocks, 'Name', tag);
                end
            end
        end







        %% Inca报文数据处理函数

        function varData = mdfDataGet(varName, filePath)
            % 读取mdf文件
            mdfData = mySlxOp.readMyMdfData(filePath);
        
            for i = 1:length(mdfData)
                thisTableVarName = mdfData{i}.Properties.VariableNames;
                thisTableVarName = thisTableVarName(:);
                thisTableVarName = string(thisTableVarName);
                % 查看是否包含变量名
                if any(contains(thisTableVarName, varName))
                    % 如果包含，则返回该变量的数据
                    varData.name = varName;
                    varData.data = mdfData{i}.(varName);
                    timeAxisName = mdfData{i}.Properties.DimensionNames{1};
                    varData.time = mdfData{i}.(timeAxisName);
                    varData.time = seconds(varData.time);
                    return;
                end
            end
        end

        
        function out = rtgDataGet(varName, filePath)
            if ~exist('varName', 'var') || isempty(varName)
                varName = "DataTrace1-TraceData";
            end

            if isfile(filePath)
                % 以Text模式读取数据
                textData = fileread(filePath);

                % 以换行符分割文本数据
                textList = splitlines(textData);
                textList = textList(:);

                % 找到全部 以 "varName[*]" 开头的行
                varLines = startsWith(textList, append(varName, "["));
                if ~any(varLines)
                    error("未找到变量: %s", varName);
                end
                varLines = varLines(:);
                varTextList = textList(varLines);
                varTextList = varTextList(:);

                % 使用正则表达式提取[]中的内容
                varNum = regexp(varTextList, '\[(.*?)\]', 'tokens');
                for i = 1:length(varNum)
                    tempStr(i) = string(varNum{i}{1});
                end
                tempStr = tempStr(:);
                varNum = tempStr;
                % 将提取的内容转换为数字
                varNum = str2double(varNum);
                % 从小到大排序
                [varNum, sortIndex] = sort(varNum);
                varTextList = varTextList(sortIndex);

                data = [];
                for i = 1:length(varTextList)
                    % 以 ','分割
                    tempData = split(varTextList(i), ',');
                    tempData = tempData(2:end);
                    % 将字符串转换为数字
                    tempData = str2double(tempData);
                    tempData = tempData(:);
                    data = [data; tempData];
                end
                time = 10e-3 * (0:length(data)-1);
                time = time(:);

                out.data = data;
                out.time = time;
                out.varName = varName;
            else
                error("文件不存在: %s", filePath);
            end
        end


        %% 信号层次结构的相关功能
        function sigList = parseSignalHierarchy(SignalHierarchy)
            % parseSignalHierarchy 解析信号层次结构
            % sigList = parseSignalHierarchy(SignalHierarchy)
            
            sigList = cell(0);
            signalName = SignalHierarchy.SignalName;
            children = SignalHierarchy.Children;
            if isempty(children)
                sigList = {signalName};
                return;
            end
            for i = 1:length(children)
                child = children(i);
                childSigList = mySlxOp.parseSignalHierarchy(child);
                if ~isempty(signalName)
                    for j = 1:length(childSigList)
                        sigList = [sigList; {append(signalName, '.', childSigList{j})}];
                    end
                else
                    sigList = [sigList; childSigList];
                end
            end
        end


        function sigList = getBlockSignalHierarchy(opts)
            
            arguments
                opts.block = '';
                opts.direction = '';
                opts.isUsed = false;
            end

            block = opts.block;
            direction = opts.direction;
            isUsed = opts.isUsed;

            block = mySlxOp.checkBlock(block);

            sigList = cell(0);
            for i = 1:length(block)
                thisBlock = block{i};
                % 获取block的输入端口, 输出端口
                inports = get_param(thisBlock.Handle, 'PortHandles');
                inports = inports.Inport;
                inports = inports(:);
                outports = get_param(thisBlock.Handle, 'PortHandles');
                outports = outports.Outport;
                outports = outports(:);
                if isempty(inports) && isempty(outports)
                    continue;
                elseif isempty(inports)
                    port = outports;
                elseif isempty(outports)
                    port = inports;
                elseif strcmp(direction, 'in')
                    port = inports;
                elseif strcmp(direction, 'out')
                    port = outports;
                else
                    port = [inports; outports];
                end
                port = mySlxOp.checkBlock(port);

                for j = 1:length(port)
                    thisPort = port{j};
                    signalHierarchy = thisPort.SignalHierarchy;
                    sigListTemp = mySlxOp.parseSignalHierarchy(signalHierarchy);
                    propagatedSignals = thisPort.PropagatedSignals;
                    if isempty(propagatedSignals) && isempty(thisPort.SignalHierarchy.SignalName)
                        propagatedSignals = 'NoNameSignal';
                        for k = 1:length(sigListTemp)
                            sigListTemp{k} = append(propagatedSignals, '.', sigListTemp{k});
                        end
                    elseif isempty(propagatedSignals)
                    else
                        for k = 1:length(sigListTemp)
                            sigListTemp{k} = append(propagatedSignals, '.', sigListTemp{k});
                        end
                    end
                    sigList = [sigList; sigListTemp];
                end
                for j = 1:length(sigList)
                    if endsWith(sigList{j}, '.')
                        sigList{j} = sigList{j}(1:end-1);
                    end
                end
                if isUsed
                    parentBlock = get_param(thisBlock.Handle, 'Parent');
                    parentBlock = mySlxOp.checkBlock(parentBlock);
                    if isempty(parentBlock)
                        continue;
                    end
                    sigName = sigList;
                    isUsedFlg = false(length(sigName), 1);
                    for j = 1:length(sigName)
                        if ~contains(sigName{j}, '.')
                            isUsedFlg(j) = true;
                            continue;
                        end
                        sigNameSplit = split(sigName{j}, '.');
                        sigName{j} = sigNameSplit{end};
                        sigName{j} = strcat('<', sigName{j}, '>');
                        % 搜索全部BusSelector, 如果有BusSelector使用了该信号, 则认为该信号被使用
                        busSelector = find_system(parentBlock{1}.Handle, 'FindAll', 'on', 'Type', 'Block', 'BlockType', 'BusSelector');
                        for k = 1:length(busSelector)
                            busSelectorPorts = get_param(busSelector(k), 'PortHandles');
                            busSelectorPorts = busSelectorPorts.Outport;
                            for l = 1:length(busSelectorPorts)
                                busSelectorPort = busSelectorPorts(l);
                                busSelectorPortSig = get_param(busSelectorPort, 'Name');
                                if strcmp(busSelectorPortSig, sigName{j})
                                    isUsedFlg(j) = true;
                                    break;
                                end
                            end
                            if isUsedFlg(j)
                                break;
                            end
                        end
                    end
                    sigList = sigList(isUsedFlg);
                end
            end
            
            
        end


        function allSigList = listSubSystemPortSignalHierarchy(opts)

            arguments
                opts.block = '';
                opts.direction = '';
                opts.portNum = '';
            end

            block = opts.block;
            direction = opts.direction;
            portNum = opts.portNum;

            block = mySlxOp.checkBlock(block);

            allSigList = cell(0);
            for i = 1:length(block)
                thisBlock = block{i};
                if ~strcmp(thisBlock.BlockType, 'SubSystem')
                    continue;
                end
                disp(thisBlock.Name);
                % 获取block的输入block, 输出block
                inports = find_system(thisBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Inport');
                outports = find_system(thisBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Outport');
                if ~iscell(inports)
                    inports = mat2cell(inports, ones(1, numel(inports)));
                end
                if ~iscell(outports)
                    outports = mat2cell(outports, ones(1, numel(outports)));
                end
                inports = inports(:);
                outports = outports(:);
                if strcmp(direction, 'in')
                    if isempty(portNum)
                        port = inports;
                    else
                        port = inports(portNum);
                    end
                elseif strcmp(direction, 'out')
                    if isempty(portNum)
                        port = outports;
                    else
                        port = outports(portNum);
                    end
                else
                    port = [inports; outports];
                end
                if isempty(port)
                    continue;
                end
                for j = 1:length(port)
                    port{j} = get_param(port{j}, 'Object');
                end
                for j = 1:length(port)
                    thisPort = port{j};
                    disp(thisPort.Name);
                    sigList = mySlxOp.getBlockSignalHierarchy('block', thisPort);
                    disp(sigList);
                    allSigList = [allSigList; sigList];
                end
            end
            
        end
    

        function allSubsystem = getAllSubsystem(opts)
            
            arguments
                opts.block = '';
            end

            block = opts.block;

            block = mySlxOp.checkBlock(block);

            allSubsystem = cell(0);
            for i = 1:length(block)
                thisBlock = block{i};
                if ~strcmp(thisBlock.BlockType, 'SubSystem') || mySlxOp.isMatlabFunction(thisBlock)
                    continue;
                end
                allSubsystem = [allSubsystem; {thisBlock}];
            end
        end
    
        
        %% Can FD Unpack/pack的相关功能
        function canBlock_upDateCanBlockPortName()
            block = mySlxOp.checkBlock();
            for i = 1:length(block)
                thisBlock = block{i};
                if ~strcmp(thisBlock.BlockType, 'S-Function')
                    continue;
                end

                try
                    thisBlockFunctionName = get_param(thisBlock.Handle, 'FunctionName');
                catch
                    countinue;
                end
                
                if strcmp(thisBlockFunctionName, 'scanfdpack')
                    port = get_param(thisBlock.Handle, 'PortHandles');
                    port = port.Inport;
                    port = port(:);
                elseif strcmp(thisBlockFunctionName, 'scanfdunpack')
                    port = get_param(thisBlock.Handle, 'PortHandles');
                    port = port.Outport;
                    port = port(:);
                elseif strcmp(thisBlockFunctionName, 'scanpack')
                    port = get_param(thisBlock.Handle, 'PortHandles');
                    port = port.Inport;
                    port = port(:);
                elseif strcmp(thisBlockFunctionName, 'scanunpack')
                    port = get_param(thisBlock.Handle, 'PortHandles');
                    port = port.Outport;
                    port = port(:);
                else
                    continue;
                end

                if isempty(port)
                    continue;
                end
                port = mySlxOp.parseBlock(port);
                MaskWSVariables = get_param(thisBlock.Handle, 'MaskWSVariables');
                if isempty(MaskWSVariables)
                    continue;
                end
                index = 0;
                for j = 1:length(MaskWSVariables)
                    if strcmp(MaskWSVariables(j).Name, 'SignalInfo')
                        index = j;
                        break;
                    end
                end
                names = cell(length(port), 1);
                for j = 1:length(port)
                    names{j} = MaskWSVariables(index).Value{j, 1};
                end
                for j = 1:length(port)
                    linkedLine = get_param(port{j}.Handle, 'Line');
                    set_param(linkedLine, 'Name', names{j});
                end
            end
        end
    
        
        function canBlock_createDbcBusByCanBlock()
            block = mySlxOp.checkBlock();
            for i = 1:length(block)
                thisBlock = block{i};
                if ~strcmp(thisBlock.BlockType, 'S-Function')
                    continue;
                end
                try
                    thisBlockFunctionName = get_param(thisBlock.Handle, 'FunctionName');
                catch
                    countinue;
                end
                if strcmp(thisBlockFunctionName, 'scanfdpack')
                elseif strcmp(thisBlockFunctionName, 'scanfdunpack')
                elseif strcmp(thisBlockFunctionName, 'scanpack')
                elseif strcmp(thisBlockFunctionName, 'scanunpack')
                else
                    continue;
                end
                MaskWSVariables = get_param(thisBlock.Handle, 'MaskWSVariables');
                if isempty(MaskWSVariables)
                    continue;
                end
                index = 0;
                for j = 1:length(MaskWSVariables)
                    if strcmp(MaskWSVariables(j).Name, 'SignalInfo')
                        index = j;
                        break;
                    end
                end
                names = cell(length(MaskWSVariables(index).Value), 1);
                for j = 1:length(names)
                    names{j} = MaskWSVariables(index).Value{j, 1};
                end
                busName = get_param(bdroot, 'Name');
                busName = append(busName, '_Bus');
                busVar = Simulink.Bus;
                busVar.Elements = Simulink.BusElement.empty;
                for j = 1:length(names)
                    busElement = Simulink.BusElement;
                    busElement.Name = names{j};
                    try
                        thisDataType = mySlxOp.genDataTypeByVarName(names{j});
                        busElement.DataType = thisDataType;
                    catch
                        
                    end
                    busVar.Elements(j) = busElement;
                end
                assignin('base', busName, busVar);
            end
        end


        %% CAN -> DBC   Simulink.Bus的相关功能
        function createDbcBusByBusBlock(opts)
            
            arguments
                opts.block = '';
            end

            block = opts.block;

            block = mySlxOp.checkBlock(block);

            for i = 1:length(block)
                thisBlock = block{i};
                if ~strcmp(thisBlock.BlockType, 'BusCreator') && ~strcmp(thisBlock.BlockType, 'BusSelector')
                    continue;
                end
                busName = get_param(thisBlock.Handle, 'Name');
                % 去除空格和换行符
                busName = strrep(busName, ' ', '');
                busName = strrep(busName, newline, '');
                elementNames = mySlxOp.getBusBlockElementNames('block', thisBlock);
                busVar = Simulink.Bus;
                busVar.Elements = Simulink.BusElement.empty;
                for j = 1:length(elementNames)
                    busElement = Simulink.BusElement;
                    busElement.Name = elementNames{j};
                    busElement.Dimensions = 1;
                    try
                        thisDataType = mySlxOp.genDataTypeByVarName(elementNames{j});
                        busElement.DataType = thisDataType;
                    catch
                        
                    end
                    busVar.Elements(j) = busElement;
                end
                % % 将busVar的代码生成设置为已导出, 并且头文件名为<busName>.h
                % busVar.HeaderFile = append(busName, '.h');
                % busVar.DataScope = 'Exported';
                assignin('base', busName, busVar);
            end
        end





        %% block 属性相关功能

        function blockPropReplace(opts)
        % blockPropReplace 替换选中模块的属性中的文本
        % 
        % 小心使用, 可能会替换掉意料之外的文本, 注意输出信息
        % 
        % blockPropReplace(opts)
            % opts: 结构体, 包含以下字段:
            %   block: 模块路径, 默认为当前选中的模块
            %   searchText: 搜索文本, 默认为空
            %   replaceText: 替换文本, 默认为空

            arguments
                opts.block = '';
                opts.searchText = '';
                opts.replaceText = '';
            end
            
            % 获取选中的模块
            blocks = mySlxOp.checkBlock();
            if isempty(blocks)
                return;
            end
            searchText = opts.searchText;
            replaceText = opts.replaceText;
            if isempty(searchText)
                disp('请提供搜索文本');
                return;
            end
            % 从选中的模块中搜寻包含搜寻文本的属性
            for i = 1:length(blocks)
                block = blocks{i};
                % 获取模块的属性
                propertiesName = fieldnames(block);
                % 遍历属性，查找包含搜寻文本的属性
                try
                    for j = 1:length(propertiesName)
                        property = block.(propertiesName{j});
                        if ischar(property) && contains(property, searchText)
                            % 替换文本
                            orText = block.(propertiesName{j});
                            newText = strrep(property, searchText, replaceText);
                            block.(propertiesName{j}) = newText;
                            disp(append("替换模块:", """", block.Name, """", "的属性", """", propertiesName{j}, """", "From:", """", orText, """", "->", """", newText, """"));
                        end
                    end
                catch
                end
            end
        end



        %% 画图专用函数
        function betterFig()
            % 设置图形属性
            % 设置坐标轴字体大小
            set(gca, 'FontSize', 18);
            % 设置坐标轴线宽
            set(gca, 'LineWidth', 1.5);
        
            % 全部曲线线宽设置为2
            h = findobj(gca, 'Type', 'line');
            set(h, 'LineWidth', 2);
        
            % 设置坐标轴标签字体大小
            set(get(gca, 'XLabel'), 'FontSize', 18);
            set(get(gca, 'YLabel'), 'FontSize', 18);
            % 设置标题字体大小
            set(get(gca, 'Title'), 'FontSize', 24);
            % 设置图例字体大小
            set(get(gca, 'Legend'), 'FontSize', 16);
            box on; % 显示边框
            grid on; % 显示网格
            
            % 窗口最大化
            % set(gcf, 'WindowState', 'maximized');
        end

        function hilightPeakPoint(X, Y, color, exceptValue)
            % hilightPeakPoint 高亮显示峰值点
            % hilightPeakPoint(X, Y)
            % X: 时间序列
            % Y: 信号序列

            [~, locs] = findpeaks(Y);
            meanY = mean(abs(Y));
            if ~exist('color', 'var')
                color = 'r';
            end
            if ~exist('exceptValue', 'var')
                exceptValue = 0;
            end
            % 去除小于均值的点
            locs = locs(abs(Y(locs)) > max(meanY, exceptValue));
            hold on;
            % 高亮显示峰值点
            plot(X(locs), Y(locs), 'ro', 'MarkerSize', 10, 'LineWidth', 2, 'Color', color, 'HandleVisibility', 'off');
            % 显示峰值点的值(X和Y)
            for i = 1:length(locs)
                text(X(locs(i)), Y(locs(i)), num2str(Y(locs(i))), 'Color', color, 'FontSize', 12, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
            end
            hold off;
        end



        %% 通用数据处理函数
        function [fftX, fftY] = fftDataSingle(X, Y)
            % fftDataSingle 对数据进行单边幅值谱FFT处理
            % X: 时间向量（必须均匀采样）
            % Y: 信号向量（实数）
            % fftX: 单边频率轴
            % fftY: 单边幅值谱

            X = X(:);  % 保证是列向量
            Y = Y(:);

            % 采样率
            dt = mean(diff(X));         % 采样间隔
            Fs = 1 / dt;                % 采样频率
            N = length(Y);              % 样本数

            % FFT计算
            Y_fft = fft(Y);
            P2 = abs(Y_fft / N);        % 双边谱归一化
            P1 = P2(1:floor(N/2)+1);    % 单边谱
            P1(2:end-1) = 2 * P1(2:end-1);  % 除DC和Nyquist外乘2

            % 频率轴
            f = Fs * (0:floor(N/2)) / N;

            % 输出
            fftX = f;
            fftY = P1;
        end


        function [fftX, fftY] = fftDataDouble(X, Y)
            % fftDataDouble 对数据进行FFT处理，返回双边幅值谱
            % X: 时间向量（必须均匀采样）
            % Y: 信号向量
            % fftX: 双边频率轴（包含正频率和负频率）
            % fftY: 双边幅值谱（对称）

            X = X(:);  % 强制列向量
            Y = Y(:);

            % 基本参数
            dt = mean(diff(X));   % 采样时间间隔
            Fs = 1 / dt;          % 采样频率
            N = length(Y);        % 采样点数

            % FFT
            Y_fft = fft(Y);
            fftY = abs(Y_fft / N);  % 归一化幅值谱（双边）

            % 构造双边频率轴
            if mod(N, 2) == 0
                % 偶数点数：频率从 -Fs/2 到 Fs/2
                f = (-N/2:N/2-1) * Fs / N;
            else
                % 奇数点数
                f = (-(N-1)/2:(N-1)/2) * Fs / N;
            end

            % 将谱移位，使0频率居中
            fftY = fftshift(fftY);
            fftX = f;
        end



        function [isOk, A, B] = debounceCal(X, Y, slopThrs)
            % debounceCal 消抖计算
            % X: 时间向量
            % Y: 信号向量
            % threshold: 阈值

            X = X(:);  % 强制列向量
            Y = Y(:);

            if ~exist('slopThrs', 'var')
                slopThrs = 1;
            end

            % 使用 y = Ax + B 的线性拟合
            % 计算线性拟合的斜率和截距
            coeffs = polyfit(X, Y, 1);
            A = coeffs(1);  % 斜率
            B = coeffs(2);  % 截距
            % 当斜率小于 slopThrs 时，认为是消抖
            if abs(A) < slopThrs
                isOk = true;
            else
                isOk = false;
            end
        end

    %% mat文件处理
    function saveMatByStruct(opts)
    % saveMatByStruct 保存基础工作区中的数据到mat文件, 以Struct的形式保存
        arguments
            opts.filePath (1,1) string = "";
            opts.fileName (1,1) string = "data";
        end

        if strcmp(opts.filePath, "")
            f = figure('Renderer' , 'painters' , 'Position' , [-100 -100 0 0]);
            [fileName, fileDir] = uiputfile('*.mat', 'Save MAT file', opts.fileName + ".mat");
            close(f);
            if isequal(fileName, 0) || isequal(fileDir, 0)
                return;
            end
            opts.filePath = fullfile(fileDir, fileName);
        end

        % 从基础工作区获取数据
        dataName = evalin('base', 'who');
        data = struct('name', {}, 'data', {}, 'class', {});
        for i = 1:numel(dataName)
            % 获取数据
            thisName = dataName{i};
            thisData = evalin('base', dataName{i});
            tempData = mySlxOp.getStruct(thisData, thisName);
            thisDataStruct = tempData;
            data(i) = thisDataStruct;
        end
        data = data(:);
        % 保存数据到mat文件
        save(opts.filePath, "data");
    end

    function outStruct = getStruct(var, name)
        outStruct = struct('name', {}, 'data', {}, 'class', {});
        if ~isobject(var)
            outStructTemp = struct('name', name, 'data', var, 'class', class(var));
            outStruct = [outStruct; outStructTemp];
            return;
        end
        for q = 1:numel(var)
            thisVar = var(q);
            try
                fieldnames = fields(thisVar);
            catch
                outStructTemp = struct('name', name, 'data', thisVar, 'class', class(thisVar));
                outStruct = [outStruct; outStructTemp];
                continue;
            end
            for i = 1:numel(fieldnames)
                fieldName = fieldnames{i};
                thisField = thisVar.(fieldName);
                tempData = mySlxOp.getStruct(thisField, fieldName);
                data.(fieldName) = tempData;
            end
            outStructTemp = struct('name', name, 'data', data, 'class', class(thisVar));
            outStruct = [outStruct; outStructTemp];
        end
    end


    %% 路径处理函数
        function path = getZinSightPath()
            % getZinSightPath 获取ZinSight文件夹的路径
            % 获取当前文件的路径
            currentPath = mfilename('fullpath');
            % 当前文件是ZinSight文件夹下的子文件(多层文件夹下)
            index = strfind(currentPath, '502_Matlab');
            if isempty(index)
                error('当前文件不在ZinSight文件夹下');
            end
            % 获取ZinSight文件夹的路径
            path = currentPath(1:index-2);
        end

    end

    % 私有方法
    methods (Static, Access = private)


        %% Private Methods
        function [direction, portNum] = autoDetectDP(block)
            block = mySlxOp.parseBlock(block);
            if isempty(block)
                error('block must contain one element.');
            end
            if ~isscalar(block)
                error('block must contain exactly one element.');
            end

            direction = [];
            portNum = [];

            thisBlock = block{1};
            inports = get_param(thisBlock.Handle, 'PortHandles');
            inports = inports.Inport;
            inports = inports(:);
            outports = get_param(thisBlock.Handle, 'PortHandles');
            outports = outports.Outport;
            outports = outports(:);
            if ~iscell(inports)
                inports = mat2cell(inports, ones(1, numel(inports)));
            end
            if ~iscell(outports)
                outports = mat2cell(outports, ones(1, numel(outports)));
            end
            inports = inports(:);
            outports = outports(:);
            thisDirection = 'in';
            thisPortNum = 1;
            if isempty(inports) && isempty(outports)
                return;
            elseif isscalar(inports) && isscalar(outports)
                thisDirection = 'in';
                thisPortNum = 1;
            elseif isscalar(inports)
                thisDirection = 'in';
                thisPortNum = 1;
            elseif isscalar(outports)
                thisDirection = 'out';
                thisPortNum = 1;
            elseif isempty(inports)
                thisDirection = 'out';
                thisPortNum = 1:length(outports);
                thisPortNum = thisPortNum(:);
            elseif isempty(outports)
                thisDirection = 'in';
                thisPortNum = 1:length(inports);
                thisPortNum = thisPortNum(:);
            end
            direction = thisDirection;
            portNum = thisPortNum;
        end


        function isDirect = isDirectThroughBlock(block)
            block = mySlxOp.parseBlock(block);
            if ~isscalar(block)
                error('block must contain exactly one element.');
            end
            isDirect = cell(length(block), 1);
            for i = 1:length(isDirect)
                isDirect{i} = false;
            end
            if isempty(block)
                return;
            end
            for i = 1:length(block)
                thisBlock = block{i};
                inports = get_param(thisBlock.Handle, 'PortHandles');
                inports = inports.Inport;
                inports = inports(:);
                outports = get_param(thisBlock.Handle, 'PortHandles');
                outports = outports.Outport;
                outports = outports(:);
                if ~iscell(inports)
                    inports = mat2cell(inports, ones(1, numel(inports)));
                end
                if ~iscell(outports)
                    outports = mat2cell(outports, ones(1, numel(outports)));
                end
                inports = inports(:);
                outports = outports(:);
                if isempty(inports) && isscalar(outports)
                    isDirect{i} = true;
                elseif isempty(outports) && isscalar(inports)
                    isDirect{i} = true;
                elseif isscalar(inports) && isscalar(outports)
                    isDirect{i} = true;
                else
                    isDirect{i} = false;
                end
            end
            isDirect = cell2mat(isDirect);
        end

        
        function endBlock = traceBlock(varargin)
            p = inputParser;

            % 可选参数
            addParameter(p, 'block', '', @(x) ischar(x) || isstring(x) || iscell(x) || ishandle(x) || isobject(x));
            addParameter(p, 'direction', '', @(x) ischar(x) || isstring(x));
            addParameter(p, 'portNum', '', @(x) isnumeric(x));
            addParameter(p, 'endBlockType', '', @(x) ischar(x) || isstring(x));

            % 解析输入参数
            parse(p, varargin{:});

            % 获取参数值
            block = p.Results.block;
            direction = p.Results.direction;
            portNum = p.Results.portNum;
            endBlockType = p.Results.endBlockType;

            block = mySlxOp.checkBlock(block, true);
            if ~isscalar(block)
                error('block must contain exactly one element.');
            end
            if isempty(direction) || isempty(portNum)
                [direction, portNum] = mySlxOp.autoDetectDP(block);
            elseif isscalar(direction) && isscalar(portNum)
                direction = repmat(direction, length(block), 1);
                portNum = repmat(portNum, length(block), 1);
            end
            if isempty(endBlockType)
                endBlockType = "No";
            end

            block = block{1};


            endBlock = cell(0);
            endBlockTemp = block;
            endPortNumTemp = portNum;
            if ~iscell(endBlockTemp)
                endBlockTemp = {endBlockTemp};
            end
            if ~iscell(endPortNumTemp)
                endPortNumTemp = {endPortNumTemp};
            end
            while true
                tempBlock = endBlockTemp;
                tempPortNum = endPortNumTemp;
                endBlockTemp = cell(0);
                endPortNumTemp = cell(0);
                isEnd = false(length(tempBlock), 1);
                isEnd = mat2cell(isEnd, ones(1, numel(isEnd)));
                for i = 1:length(tempBlock)
                    thisBlock = tempBlock{i};
                    thisPortNum = tempPortNum{i};
                    if strcmp(thisBlock.BlockType, endBlockType) || ~mySlxOp.isDirectThroughBlock(thisBlock)
                        isEnd{i} = true;
                        endBlockTemp = [endBlockTemp; {thisBlock}];
                        endPortNumTemp = [endPortNumTemp; {thisPortNum}];
                        continue;
                    end
                    if strcmp(direction, 'in')
                        [thisBlockTemp, thisPortNumTemp] = mySlxOp.getLastBlock('block', thisBlock, 'portNum', thisPortNum, 'lookUnderMask', true);
                    elseif strcmp(direction, 'out')
                        [thisBlockTemp, thisPortNumTemp] = mySlxOp.getNextBlock('block', thisBlock, 'portNum', thisPortNum, 'lookUnderMask', true);
                    else
                        error('Invalid direction.');
                    end
                    if isempty(thisBlockTemp)
                        isEnd{i} = true;
                        endBlockTemp = [endBlockTemp; {thisBlock}];
                        endPortNumTemp = [endPortNumTemp; {thisPortNum}];
                        continue;
                    else
                        endBlockTemp = [endBlockTemp; thisBlockTemp];
                        endPortNumTemp = [endPortNumTemp; thisPortNumTemp];
                    end
                end
                if all(cell2mat(isEnd))
                    break;
                end
            end
            endBlock = endBlockTemp;
        end
    

        function isMatlabFunction = isMatlabFunction(block)
            block = mySlxOp.parseBlock(block);
            isMatlabFunction = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'SubSystem')
                    if (strcmp(thisBlock.ErrorFcn, 'Stateflow.Translate.translate'))
                        temp{i} = true;
                    end
                end
            end
            if all(cell2mat(temp))
                isMatlabFunction = true;
            end
        end


        function isSubsystem = isSubsystem(block)
            block = mySlxOp.parseBlock(block);
            isSubsystem = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'SubSystem') && ~mySlxOp.isMatlabFunction(thisBlock)
                    temp{i} = true;
                end
            end
            if all(cell2mat(temp))
                isSubsystem = true;
            end
        end


        function dataType = genDataTypeByVarName(varName)
            % 数据类型索引名
            dataTypeIndexName = {...
                "bo", ...
                "i", ...
                "u", ...
                "f", ...
                "st", ...
            };
            dataTypeIndexNameC = dataTypeIndexName;
            for i = 1:length(dataTypeIndexName)
                dataTypeIndexNameC{i} = append("c", dataTypeIndexName{i});
            end
            dataTypeIndexName = dataTypeIndexName(:);
            % 数据类型列表
            dataTypeList = {...
                'boolean', ...
                'int16', ...
                'uint16', ...
                'single', ...
                'uint16', ...
            };
            dataTypeList = dataTypeList(:);

            name = varName;
            dataType = '';

            if isempty(dataType)
                try
                    var = evalin('base', name);
                    dataType = var.DataType;
                catch
                end
            end

            if isempty(dataType)
                try
                    % 将 name 以 '_' 分割
                    nameSplit = split(name, '_');
                    % 取第三份
                    if length(nameSplit) < 3
                        parLastName = nameSplit{end};
                    else
                        parLastName = nameSplit{3};
                    end
                    % 如果 parLastName 以 dataTypeIndexName 中的任意一个开头(区分大小写), 则取出对应的数据类型
                    for i = 1:length(dataTypeIndexName)
                        if startsWith(parLastName, dataTypeIndexName{i})
                            dataType = dataTypeList{i};
                            break;
                        end
                        if startsWith(parLastName, dataTypeIndexNameC{i})
                            dataType = dataTypeList{i};
                            break;
                        end
                    end
                catch
                    % 如果 name 不符合规范, 则报错
                    errorMsg = append("变量名 <", name, "> 不规范, 请手动指定数据类型.");
                    error(errorMsg);
                end
            end
        end


        function isEnum = isSimulinkEnumType(dataTypeName)
            % 判断一个字符串是否为Simulink.IntEnumType的枚举类型
        
            try
                mc = meta.class.fromName(dataTypeName);
                if isempty(mc)
                    isEnum = false;
                    return;
                end
        
                % 检查是否继承自Simulink.IntEnumType
                isEnum = any(strcmp({mc.SuperclassList.Name}, 'Simulink.IntEnumType'));
            catch
                isEnum = false;
            end
        end
        

        function isBus = isSimulinkBusType(dataTypeName)
            % 判断一个字符串是否为Simulink.Bus类型
        
            try
                % 读取基础工作区的变量
                busObj = evalin('base', dataTypeName);
                % 检查是否是Simulink.Bus对象
                isBus = isa(busObj, 'Simulink.Bus');
            catch
                isBus = false;
            end
        end
        

        function data = readMyMdfData(filePath)

            persistent dataBuf;
            persistent lastFilePath;
        
            if isempty(dataBuf)
                dataBuf = [];
                lastFilePath = '';
            end
        
            % 检查文件名是否相同
            if strcmp(lastFilePath, filePath) && ~isempty(dataBuf)
                data = dataBuf;
                return;
            end
            data = mdfRead(filePath);
            lastFilePath = filePath;
            dataBuf = data;
        end

    end
end