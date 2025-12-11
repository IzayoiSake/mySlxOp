classdef line

    methods(Static)

        function newName = normalizeName(opts)
        % normalizeName - 规范化连接线的信号名
        % Syntax: newName = myOp.slx.line.normalizeName(opts)
        % Inputs:
        %    opts - 结构体，包含以下字段：
        %       name - (string) 连接线的信号名(可以是string数组)
        % Outputs:
        %    newName - (string) 规范化后的信号名
        % Example:
        %    newName = myOp.slx.line.normalizeName("my signal name")
            arguments
                opts.name (:, 1) string
            end

            % 非法字符替换掉
            invalidString = [
                " ";
                "<";
                ">";
                "/";
            ];
            replaceString = "";

            % 规范化信号名
            newName = replace(opts.name, invalidString, replaceString);
        end


        function [lineNames, lineDataTypes] = line_getObsSigofSys(opts)

            arguments
                opts.block = '';
                opts.line = '';
            end

            block = opts.block;
            line = opts.line;

            block = myOp.slx.general.checkBlock(block);
            line = myOp.slx.general.checkLine(line);

            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.priTools.isSubsystem(thisBlock)
                    thisBlockLine = find_system(thisBlock.Handle, 'FindAll', 'on', 'type', 'line');
                    thisBlockLine = myOp.slx.general.checkLine(thisBlockLine);
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


        function line_createSelectedSig(opts)
        % 创建选中的信号线的标准信号
            arguments
                opts.checkDataType = true;
            end
            checkDataType = opts.checkDataType;

            line = myOp.slx.general.checkLine();

            if isempty(line)
                return;
            end

            if checkDataType
                lineDataType = myOp.slx.line.line_getLineDataType('line', line);
                for i = 1:length(line)
                    thisLine = line{i};
                    sigName = get_param(thisLine.Handle, 'Name');
                    myOp.slx.std.createStdSig(sigName, lineDataType{i});
                    thisLine.MustResolveToSignalObject = true;
                end
            else
                for i = 1:length(line)
                    thisLine = line{i};
                    sigName = get_param(thisLine.Handle, 'Name');
                    myOp.slx.std.createStdSig(sigName);
                    thisLine.MustResolveToSignalObject = true;
                end
            end
        end

        
        function line_deleteSelectedSig(opts)

        %   删除选中的信号线
            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

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


        function line_getSelectedLineName(opts)
        %   获取选中的线的名字
            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end
            line = myOp.slx.line.line_sortByPosition('line', line);
            for i = 1:length(line)
                thisLine = line{i};
                sigName = get_param(thisLine.Handle, 'Name');
                disp(sigName);
            end
        end

        
        function line_appendSelectedLineName(opts)
        %  给选中的信号线的名字添加后缀
            arguments
                opts.line = '';
                opts.suffix = '';
            end

            line = opts.line;
            suffix = opts.suffix;

            line = myOp.slx.general.checkLine(line);

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


        function allLineOut = line_logAllLine(opts)
            
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
            allLines = myOp.slx.general.checkLine(allLines);

            fullId = myOp.slx.line.line_getLineFullId('line', allLines);

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
            lineDimensions = cell(length(allLines), 1);

            for i = 1:length(allLines)
                thisLine = allLines{i};
                % 获取线的数据类型
                try
                    srcPort = thisLine.getSourcePort();

                    dataType = srcPort.CompiledPortDataType;
                    % 检查 dataType 是否是一个 Simulink.Bus类型
                    if (myOp.slx.priTools.isSimulinkBusType(dataType))
                        dataType = append("Bus:", dataType);
                    end
                    % 检查 dataType 是否是一个 枚举类型
                    if (myOp.slx.priTools.isSimulinkEnumType(dataType))
                        dataType = append("Enum:", dataType);
                    end
                    lineDataType{i} = dataType;
                catch
                    lineDataType{i} = '';
                end
                % 获取线的维度
                try
                    srcPort = thisLine.getSourcePort();
                    dimensions = srcPort.CompiledPortDimensions;
                    dimensions = dimensions(2:end);
                    lineDimensions{i} = dimensions;
                catch
                    lineDimensions{i} = [];
                end
            end

            if ~isOtherSiming
                % 关闭仿真器
                set_param(topModelPath, 'SimulationCommand', 'stop');
            end

            % 清除基础工作区中的变量"out"
            evalin('base', 'clear out');

            allLine.dataType = lineDataType;
            allLine.dimensions = lineDimensions;
            allLine.fullId = fullId;
            allLineOut = allLine;
        end


        function fullId = line_getLineFullId(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

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


        function [lineDataType] = line_getLineDataType(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end
            allLine = myOp.slx.line.line_logAllLine('onlyRead', true);
            lineFullId = myOp.slx.line.line_getLineFullId('line', line);

            % 检查allLine是否包含全部的lineFullId
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                allLine = myOp.slx.line.line_logAllLine('onlyRead', false);
            end
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                error(append("Error [line_getLineDataType]: there is a line not in allLineLog, please run myOp.slx.line.line_logAllLine() and check."));
            end

            lineDataType = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                thisLineFullId = lineFullId{i};
                index = find(contains(allLine.fullId, thisLineFullId));
                lineDataType{i} = allLine.dataType{index};
            end
        end


        function [lineDimensions] = line_getLineDimensions(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end
            allLine = myOp.slx.line.line_logAllLine('onlyRead', true);
            lineFullId = myOp.slx.line.line_getLineFullId('line', line);

            % 检查allLine是否包含全部的lineFullId
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                allLine = myOp.slx.line.line_logAllLine('onlyRead', false);
            end
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                error(append("Error [line_getLineDimensions]: there is a line not in allLineLog, please run myOp.slx.line.line_logAllLine() and check."));
            end

            lineDimensions = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                thisLineFullId = lineFullId{i};
                index = find(contains(allLine.fullId, thisLineFullId));
                lineDimensions{i} = allLine.dimensions{index};
            end
        end


        function isOk = line_checkAllLineLog(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end

            allLine = myOp.slx.line.line_logAllLine('onlyRead', true);
            lineFullId = myOp.slx.line.line_getLineFullId('line', line);

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


        function line_fixName(opts)
        % line_fixName  修正信号线名称中的非法字符
        %   line_fixName(OPTIONS) 遍历指定的 Simulink 信号线句柄

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end

            for i = 1:length(line)
                thisLine = line{i};
                lineName = get_param(thisLine.Handle, 'Name');
                if isempty(lineName)
                    continue;
                end
                % 定义非法字符及其替换字符
                illegalChars = {"<"; ">"};
                replaceChar = '';
                % 替换非法字符
                for j = 1:length(illegalChars)
                    lineName = strrep(lineName, illegalChars{j}, replaceChar);
                end
                % 设置新的线名称
                set_param(thisLine.Handle, 'Name', lineName);
            end
        end


        function line = line_sortByPosition(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end

            positions = zeros(length(line), 4); % 每行存储一个线的位置 [left, top, right, bottom]

            for i = 1:length(line)
                thisLine = line{i};
                pos = get_param(thisLine.Handle, 'Points');
                left = min(pos(:, 1));
                right = max(pos(:, 1));
                top = min(pos(:, 2));
                bottom = max(pos(:, 2));
                positions(i, :) = [left, top, right, bottom];
            end

            % 按照 top 从小到大排序, 如果 top 相同则按照 left 从小到大排序
            [~, sortIdx] = sortrows(positions, [2, 1]);
            line = line(sortIdx);
        end
    

        function line_addOvrdParFunc(opts)

            arguments
                opts.line = '';
                opts.isParamAdd = true;
            end

            line = opts.line;
            isParamAdd = opts.isParamAdd;

            line = myOp.slx.general.checkLine(line);

            if isParamAdd
                myOp.slx.line.line_logAllLine("onlyRead", true);
            end

            for i = 1:length(line)
                thisLine = line{i};
                % 获取源端口和目标端口
                srcPort = get_param(thisLine.Handle, 'SrcPortHandle');
                dstPort = get_param(thisLine.Handle, 'DstPortHandle');
                try
                    srcPort = myOp.slx.general.parseBlock(srcPort);
                catch
                    srcPort = {};
                end
                try
                    dstPort = myOp.slx.general.parseBlock(dstPort);
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
                parentBlocks = myOp.slx.general.parseBlock(parentBlocks);
                
                for j = 1:length(parentBlocks)
                    parentBlock = parentBlocks{j};
                    % 查看是否是一个名字以 "Ovrd" 开头的 SubSystem
                    if myOp.slx.priTools.isSubsystem(parentBlock) && startsWith(parentBlock.Name, 'Ovrd')
                        % 搜寻switch模块
                        switchBlock = find_system(parentBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Switch');
                        if isempty(switchBlock)
                            continue;
                        end
                        switchBlock = myOp.slx.general.parseBlock(switchBlock);
                        switchBlock = switchBlock{1};
                        switchBlock = myOp.slx.general.parseBlock(switchBlock);
                        % 获取switch模块的输入端口连接的block
                        consBlock = myOp.slx.block.getLastBlock('block', switchBlock, 'portNum', 1);
                        consOvrdBlock = myOp.slx.block.getLastBlock('block', switchBlock, 'portNum', 2);

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
                                    dataType = myOp.slx.line.line_getLineDataType('line', thisLine);
                                    dataType = dataType{1};
                                    if strcmp(dataType, 'Error')
                                        dataType = 'double';
                                    end
                                    dimensions = myOp.slx.line.line_getLineDimensions('line', thisLine);
                                    myOp.slx.std.createStdParam(parName, 0, dataType, 'dimensions', dimensions{1});
                                end
                                % 从基础工作区中查看是否parOvrdName存在
                                if evalin('base', ['exist(''', parOvrdName, ''', ''var'')']) == 0
                                    dataType = 'boolean';
                                    myOp.slx.std.createStdParam(parOvrdName, 0, dataType);
                                end
                            end

                        catch ME
                            continue;
                        end
                    else
                        continue;
                    end
                end
            end
        end


        function ports = line_getLinkedPort(opts)

            arguments
                opts.line = '';
                opts.direction {mustBeMember(opts.direction, {'src', 'dst', ''})} = '';
            end

            line = opts.line;
            direction = opts.direction;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                ports = {};
                return;
            end

            ports = cell(length(line), 1);
            for i = 1:length(line)
                thisLine = line{i};
                srcPort = get_param(thisLine.Handle, 'SrcPortHandle');
                dstPort = get_param(thisLine.Handle, 'DstPortHandle');
                srcPort = myOp.slx.general.parseBlock(srcPort);
                dstPort = myOp.slx.general.parseBlock(dstPort);
                if isequal(direction, 'src')
                    thisPort = srcPort;
                elseif isequal(direction, 'dst')
                    thisPort = dstPort;
                else
                    thisPort = [srcPort; dstPort];
                end
                % 从元胞数组转成数组形式
                thisPort = cell2mat(thisPort);
                ports{i} = thisPort;
            end
        end
    

        function blocks = line_getLinkedBlock(opts)

            arguments
                opts.line = '';
                opts.direction {mustBeMember(opts.direction, {'src', 'dst', ''})} = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end

            ports = myOp.slx.line.line_getLinkedPort('line', line, 'direction', opts.direction);
            blocks = cell(length(ports), 1);
            for i = 1:length(ports)
                thisPorts = ports{i};
                thisBlocks = cell(length(thisPorts), 1);
                for j = 1:length(thisPorts)
                    thisPort = thisPorts(j);
                    parentPath = get_param(thisPort.Handle, 'Parent');
                    thisBlock = myOp.slx.general.parseBlock(parentPath);
                    thisBlocks{j} = thisBlock{1};
                end
                thisBlocks = cell2mat(thisBlocks);
                blocks{i} = thisBlocks;
            end
        end
    
    end
end 