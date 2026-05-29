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
                lineDataType = myOp.slx.line.getLineDataType('line', line);
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


        function deleteSelectedSig(opts)
        %   删除选中的信号线
            arguments
                opts.line = '';
                opts.block = '';
                opts.scope {mustBeMember(opts.scope, ["Selected"; "SelectedAll"])} = 'Selected';
            end

            line = opts.line;
            if isequal(opts.scope, "Selected")
                line = myOp.slx.general.checkLine(line);
            elseif isequal(opts.scope, "SelectedAll")
                line = myOp.slx.line.getAll('line', line, 'block', opts.block);
            end
            

            if isempty(line)
                return;
            end

            for i = 1:length(line)
                thisLine = line{i};
                sigName = get_param(thisLine.Handle, 'Name');
                if thisLine.MustResolveToSignalObject == true
                    try
                        evalin('base', ['clear ', sigName]);
                    catch
                    end
                    thisLine.MustResolveToSignalObject = false;
                    thisLineId = myOp.slx.line.getId('line', thisLine);
                    msg = myhiliteCmd(thisLineId{1}, thisLineId{1});
                    msg = append("⚠️ 已删除信号线 ", msg, " 的信号。");
                    disp(msg);
                end
            end
        end


        function setLineName(opts)
        %   设置选中的线的名字
            arguments
                opts.line = '';
                opts.block = '';
                opts.searchDepth = Inf;
                opts.name = '';
            end

            line = myOp.slx.line.getAll(...
                'line', opts.line, ...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );

            for i = 1:length(line)
                thisLine = line{i};
                prpgtName = myOp.slx.line.getPrpgtSigName('line', thisLine);
                if isequal(opts.name, '')
                    newName = prpgtName;
                else
                    newName = opts.name;
                end
                try
                    set_param(thisLine.Handle, 'Name', newName);
                    id = myOp.slx.line.getId('line', thisLine);
                    numb = myhiliteCmd(id{1}, string(i));
                    idStr = myhiliteCmd(id{1}, id{1});
                    msg = append("✅ ", numb, ". 已将信号线 ", idStr, " 的名字设置为 ", newName, "。");
                    disp(msg);
                catch
                    id = myOp.slx.line.getId('line', thisLine);
                    idStr = myhiliteCmd(id{1}, id{1});
                    numb = myhiliteCmd(id{1}, string(i));
                    msg = append("❌ ", numb, ". 无法将信号线 ", idStr, " 的名字设置为 ", newName, "。");
                    disp(msg);
                end
            end

        end


        function names = getLineName(opts)
        %   获取选中的线的名字
            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end
            % line = myOp.slx.line.line_sortByPosition('line', line);
            names = cell(length(line), 1);
            for i = 1:length(line)
                thisLine = line{i};
                sigName = get_param(thisLine.Handle, 'Name');
                names{i} = sigName;
            end

            if nargout == 0
                % 显示超链接
                msg = "✨ 选中的信号线名称如下:\n";
                for i = 1:length(names)
                    thisName = names{i};
                    thisPath = getfullname(line{i}.Handle);
                    if isequal(thisName, "")
                        thisName = "(无名称)";
                    end
                    thisLinePath = myOp.slx.line.getId("line", line{i});
                    thisLinePath = thisLinePath{1};
                    cmdPath = strrep(thisLinePath, newline, ''' newline ''');
                    newMsg = sprintf('🔗 <a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, thisName);
                    msg = append(msg, newMsg, "\n");
                end
                fprintf(msg);
                clear names;
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

            allThing = myOp.slx.simLog.logAll('onlyRead', opts.onlyRead);
            allLineOut = allThing.line;
        end


        function varargout = getId(opts)

            arguments
                opts.line = '';
            end

            for i = 1:nargout
                varargout{i} = [];
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
                srcPort = get_param(thisLine.Handle, 'SrcPortHandle');
                dstPort = get_param(thisLine.Handle, 'DstPortHandle');
                if ~isequal(srcPort, -1)
                    port = srcPort;
                    portType = 'out';
                elseif ~isequal(dstPort, -1)
                    port = dstPort(1);
                    portType = 'in';
                else
                    port = -1;
                    portType = '';
                end
                if port == -1
                    msg = sprintf('<a href="matlab:myhilite([%.64g])">%s</a>', thisLine.Handle, parentPath);
                    msg = append("错误: 该信号线 ", msg, " 没有连接到任何端口, 因此无效.");
                    error(msg);
                end
                block = get_param(port, 'Parent');
                portNum = get_param(port, 'PortNumber');
                blockName = get_param(block, 'Name');
                blockPath = get_param(block, 'Parent');

                fullId{i} = append(blockPath, '/', blockName, ':', portType, ':', num2str(portNum));
            end
            fullId = fullId(:);
            if nargout == 1
                varargout{1} = fullId;
            elseif nargout == 2
                msgAll = [];
                for i = 1:length(line)
                    thisLine = line{i};
                    thisFullId = fullId{i};
                    cmdPath = strrep(thisFullId, newline, ''' newline ''');
                    msg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, thisFullId);
                    msg = append("⭐ 信号线完整id: ", msg);
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = append(idx, ". ", msg);
                    msgAll = append(msgAll, msg, "\n");
                end
                varargout{1} = fullId;
                varargout{2} = msgAll;
            else
                for i = 1:length(line)
                    thisLine = line{i};
                    thisFullId = fullId{i};
                    cmdPath = strrep(thisFullId, newline, ''' newline ''');
                    msg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, thisFullId);
                    msg = append("⭐ 信号线完整id: ", msg);
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = append(idx, ". ", msg);
                    disp(msg);
                end
            end
        end


        function varargout = getLinePath(opts)
            arguments
                opts.line = '';
            end

            for i = 1:nargout
                varargout{i} = [];
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);
            if isempty(line)
                return;
            end
            lineId = myOp.slx.line.getId('line', line);

            linePath = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                thisLineId = lineId{i};
                lineName = get_param(thisLine.Handle, 'Name');
                if ~isequal(lineName, "")
                    linePath{i} = append(lineName, ':', thisLineId);
                else
                    linePath{i} = thisLineId;
                end
            end
            if nargout == 1
                varargout{1} = linePath;
            elseif nargout == 2
                msgAll = [];
                for i = 1:length(line)
                    thisLineId = lineId{i};
                    thisLinePath = linePath{i};
                    cmdPath = strrep(thisLineId, newline, ''' newline ''');
                    msg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, thisLinePath);
                    msg = append("⭐ 信号线路径: ", msg);
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = append(idx, ". ", msg);
                    msgAll = append(msgAll, msg, "\n");
                end
                varargout{1} = linePath;
                varargout{2} = msgAll;
            else
                for i = 1:length(line)
                    thisLineId = lineId{i};
                    thisLinePath = linePath{i};
                    cmdPath = strrep(thisLineId, newline, ''' newline ''');
                    msg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, thisLinePath);
                    msg = append("⭐ 信号线路径: ", msg);
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = append(idx, ". ", msg);
                    disp(msg);
                end
            end
        end


        function varargout = getLineHandle(opts)

            arguments
                opts.line = '';
                opts.id = '';
            end
            for i = 1:nargout
                varargout{i} = [];
            end

            line = opts.line;
            id = opts.id;

            if isequal(id, '')
                line = myOp.slx.general.checkLine(line);
            else
                line = myOp.slx.line.getAll('line', id);
            end

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end

            handle = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                handle{i} = thisLine.Handle;
            end
            if nargout == 1
                varargout{1} = handle;
            elseif nargout == 2
                msgAll = [];
                for i = 1:length(line)
                    thisLine = line{i};
                    thisHandle = handle(i);
                    thisPath = myOp.slx.line.getId('line', thisLine);
                    cmdPath = strrep(thisPath{1}, newline, ''' newline ''');
                    msg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(thisHandle));
                    msg = append("⭐ 信号线句柄: ", msg);
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = append(idx, ". ", msg);
                    msgAll = append(msgAll, msg, "\n");
                end
                varargout{1} = handle;
                varargout{2} = msgAll;
            else
                for i = 1:length(line)
                    thisLine = line{i};
                    thisHandle = handle(i);
                    thisPath = myOp.slx.line.getId('line', thisLine);
                    cmdPath = strrep(thisPath{1}, newline, ''' newline ''');
                    msg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(thisHandle));
                    msg = append("⭐ 信号线句柄: ", msg);
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = append(idx, ". ", msg);
                    disp(msg);
                end
            end
        end


        function [lineDataType] = getLineDataType(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end
            allLine = myOp.slx.line.line_logAllLine('onlyRead', true);
            lineFullId = myOp.slx.line.getId('line', line);

            % 检查allLine是否包含全部的lineFullId
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                allLine = myOp.slx.line.line_logAllLine('onlyRead', false);
            end
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                error(append("Error [getLineDataType]: there is a line not in allLineLog, please run myOp.slx.line.line_logAllLine() and check."));
            end

            lineDataType = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                thisLineFullId = lineFullId{i};
                index = find(contains(allLine.fullId, thisLineFullId));
                lineDataType{i} = allLine.dataType{index};
            end
        end


        function [lineDimensions] = getLineDimensions(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end
            allLine = myOp.slx.line.line_logAllLine('onlyRead', true);
            lineFullId = myOp.slx.line.getId('line', line);

            % 检查allLine是否包含全部的lineFullId
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                allLine = myOp.slx.line.line_logAllLine('onlyRead', false);
            end
            isOk = myOp.slx.line.line_checkAllLineLog('line', line);
            if ~isOk
                error(append("Error [getLineDimensions]: there is a line not in allLineLog, please run myOp.slx.line.line_logAllLine() and check."));
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
            lineFullId = myOp.slx.line.getId('line', line);

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
    

        function addOvrdParFunc(opts)

            arguments
                opts.line = '';
                opts.isParamAdd {mustBeNumericOrLogical(opts.isParamAdd)} = true;
                opts.isParamOvrd {mustBeNumericOrLogical(opts.isParamOvrd)} = true;
            end

            line = opts.line;
            isParamAdd = opts.isParamAdd;
            isParamOvrd = opts.isParamOvrd;

            line = myOp.slx.general.checkLine(line);

            if isParamAdd
                myOp.slx.line.line_logAllLine("onlyRead", true);
            end

            for i = 1:length(line)
                thisLine = line{i};
                % 获取连接的block
                parentBlocks = myOp.slx.line.getLinkedBlock('line', thisLine);
                parentBlocks = parentBlocks{1};
                % 筛选子系统
                parentBlocks = myOp.slx.subSysBlock.checkBlock('block', parentBlocks);
                
                for j = 1:length(parentBlocks)
                    parentBlock = parentBlocks{j};
                    % 查看是否是一个名字以 "Ovrd" 开头的 SubSystem
                    if startsWith(parentBlock.Name, 'Ovrd')
                        % 搜寻switch模块
                        isArray = false;
                        switchBlock = myOp.slx.switchBlock.getAll('block', parentBlock, 'searchDepth', 1);
                        forEachSubBlock = myOp.slx.subSysBlock.getAll('block', parentBlock, 'searchDepth', 1, 'subType', 'ForEach');
                        if ~isempty(forEachSubBlock)
                            forEachSubBlock = forEachSubBlock{1};
                            consBlock = myOp.slx.block.getLastBlock('block', forEachSubBlock, 'portNum', 1);
                            consOvrdBlock = myOp.slx.block.getLastBlock('block', forEachSubBlock, 'portNum', 2);
                            isArray = true;
                        elseif isempty(switchBlock)
                            % 查找 Operator 为 'Not' 的 logical Operator 模块
                            notBlock = myOp.slx.general.find_system(parentBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Logic', 'Operator', 'NOT');
                            % 查找 Operator 为 'Or' 的 logical Operator 模块
                            orBlock = myOp.slx.general.find_system(parentBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Logic', 'Operator', 'OR');
                            if isempty(notBlock) || isempty(orBlock)
                                continue;
                            elseif length(notBlock) ~= 1 || length(orBlock) ~= 1
                                continue;
                            else
                                notBlock = myOp.slx.general.parseBlock(notBlock);
                                notBlock = notBlock{1};
                                orBlock = myOp.slx.general.parseBlock(orBlock);
                                orBlock = orBlock{1};
                                % 获取not模块的输入端口连接的block
                                consOvrdBlock = myOp.slx.block.getLastBlock('block', notBlock, 'portNum', 1);
                                % 获取or模块的第一个输入端口连接的block
                                consBlock = myOp.slx.block.getLastBlock('block', orBlock, 'portNum', 1);
                            end
                        else
                            switchBlock = myOp.slx.general.parseBlock(switchBlock);
                            switchBlock = switchBlock{1};
                            switchBlock = myOp.slx.general.parseBlock(switchBlock);
                            % 获取switch模块的输入端口连接的block
                            consBlock = myOp.slx.block.getLastBlock('block', switchBlock, 'portNum', 1);
                            consOvrdBlock = myOp.slx.block.getLastBlock('block', switchBlock, 'portNum', 2);
                        end
                        
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
                                if isParamOvrd || (evalin('base', ['exist(''', parName, ''', ''var'')']) == 0) 
                                    dataType = myOp.slx.line.getLineDataType('line', thisLine);
                                    dataType = dataType{1};
                                    if strcmp(dataType, 'Error')
                                        dataType = 'double';
                                    end
                                    dimensions = myOp.slx.line.getLineDimensions('line', thisLine);
                                    myOp.slx.std.createStdParam(parName, 0, dataType, 'dimensions', dimensions{1});
                                end
                                % 从基础工作区中查看是否parOvrdName存在
                                if isParamOvrd || (evalin('base', ['exist(''', parOvrdName, ''', ''var'')']) == 0)
                                    dataType = 'boolean';
                                    if isArray
                                        myOp.slx.std.createStdParam(parOvrdName, 0, dataType, "dimensions", dimensions{1});
                                    else
                                        myOp.slx.std.createStdParam(parOvrdName, 0, dataType);
                                    end
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


        function ports = getLinkedPort(opts)

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
    

        function [blocks, portNum] = getLinkedBlock(opts)

            arguments
                opts.line = '';
                opts.direction {mustBeMember(opts.direction, {'src', 'dst', ''})} = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                return;
            end

            ports = myOp.slx.line.getLinkedPort('line', line, 'direction', opts.direction);
            blocks = cell(length(ports), 1);
            portNum = cell(length(ports), 1);
            for i = 1:length(ports)
                thisPorts = ports{i};
                thisPortNums = zeros(length(thisPorts), 1);
                thisBlocks = cell(length(thisPorts), 1);
                for j = 1:length(thisPorts)
                    thisPort = thisPorts(j);
                    parentPath = get_param(thisPort.Handle, 'Parent');
                    thisBlock = myOp.slx.general.parseBlock(parentPath);
                    thisBlocks{j} = thisBlock{1};
                    thisPortNums(j) = get_param(thisPort.Handle, 'PortNumber');
                end
                thisBlocks = cell2mat(thisBlocks);
                blocks{i} = thisBlocks;
                portNum{i} = thisPortNums;
            end
        end
    

        function lines = getAll(opts)

            arguments
                opts.block = '';
                opts.line = '';
                opts.searchDepth = Inf;
            end

            block = opts.block;
            line = opts.line;

            block = myOp.slx.general.checkBlock(block);
            line = myOp.slx.general.checkLine(line);

            if ~isempty(line)
                lines = line;
            else
                lines = {};
            end
            
            for i = 1:length(block)
                thisBlock = block{i};
                thisLines = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
                    'SearchDepth', opts.searchDepth, ...
                    'Type', 'Line' ...
                );
                thisLines = myOp.slx.general.checkLine(thisLines);
                lines = [lines; thisLines];
            end
            lines = lines(:);
        end


        function lines = getAllLoggedLines(opts)

            arguments
                opts.block = '';
                opts.line = '';
            end

            allLines = myOp.slx.line.getAll(...
                'block', opts.block, ...
                'line', opts.line ...
            );

            mask = cellfun(@(x) ~isempty(x) && isprop(x, 'DataLogging') && isequal(x.DataLogging, true), allLines);
            lines = allLines(mask);

        end


        function traces = trace(opts)

            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            traces = {};
            if isempty(line)
                return;
            end
            if length(line) ~= 1
                msg = "⚠️ 注意: 目前 myOp.slx.line.trace 仅支持单条信号线追踪, 输入的信号线超过1条, 将仅追踪第1条.";
                warning(msg);
            end
            line = line{1};

            % 

            traces = cell2mat(traces);
        end


        function varargout = getPrpgtSigName(opts)
            arguments
                opts.line = '';
            end

            line = opts.line;

            line = myOp.slx.general.checkLine(line);

            if isempty(line)
                names = "";
                srcLine = {};
                varargout{1} = names;
                varargout{2} = srcLine;
                return;
            end

            names = strings(length(line), 1);
            srcLine = cell(length(line), 1);

            for i = 1:length(line)
                thisLine = line{i};
                srcPort = get_param(thisLine.Handle, 'SrcPortHandle');
                srcPort = myOp.slx.general.parseBlock(srcPort);
                srcPort = srcPort{1};
                srcBlock = get_param(srcPort.Handle, 'Parent');
                srcBlock = myOp.slx.general.parseBlock(srcBlock);
                srcBlock = srcBlock{1};
                trace = myTraceSignal(...
                    'direction', 'b', ...
                    'block', srcBlock, ...
                    'porttype', 'o', ...
                    'portNum', srcPort.PortNumber ...
                );
                traceLine = trace.trace.lines;
                if isempty(traceLine)
                    names(i) = "";
                    srcLine{i} = thisLine;
                    continue;
                end
                % 先检查traceLine里是否能拿到信号.
                traceLine = myOp.slx.general.parseLine(traceLine);
                % 颠倒顺序
                traceLine = traceLine(:);
                traceLine = flipud(traceLine);
                hasSigName = false;
                for j = 1:length(traceLine)
                    thisTraceLine = traceLine{j};
                    sigName = get_param(thisTraceLine.Handle, 'Name');
                    if ~isequal(sigName, "")
                        if (startsWith(sigName, "<") || endsWith(sigName, ">"))
                            sigName = strrep(sigName, "<", "");
                            sigName = strrep(sigName, ">", "");
                        end
                        idx = cellfun(@(x) isequal(strrep(strrep(x.Name, "<", ""), ">", ""), sigName), traceLine);
                        names(i) = sigName;
                        srcLine{i} = traceLine{idx};
                        hasSigName = true;
                        break;
                    end
                end
                % 如果traceLine没有信号名, 尝试检查traceBlock
                if ~hasSigName
                    traceBlockType = trace.trace.blocktypes;
                    % 检查traceBlockType里是否有 "RateTransition" 模块
                    idx = cellfun(@(x) isequal(x, "RateTransition"), traceBlockType);
                    if any(idx)
                        rtBlock = trace.trace.blocks(idx);
                        rtBlock = myOp.slx.general.parseBlock(rtBlock);
                        for j = 1:length(rtBlock)
                            thisRtBlock = rtBlock{j};
                            % 获取这个rtBlock的输入端口连接的线路
                            rtLine = myOp.slx.block.getBlockLine("block", thisRtBlock, "lineType", "Inport", "lineNum", 1);
                            [sigName, srcLine{i}] = myOp.slx.line.getPrpgtSigName('line', rtLine);
                            if ~isequal(sigName, "")
                                names(i) = sigName;
                                hasSigName = true;
                                break;
                            end
                        end
                    end 
                end
                if ~hasSigName
                    names(i) = "";
                    srcLine{i} = thisLine;
                end
            end

            if nargout == 0
                % 显示超链接
                msg = "✨ 选中的信号线传播的信号名称如下:";
                msg = append(msg, newline);
                for i = 1:length(names)
                    thisName = names(i);
                    id = myOp.slx.line.getId('line', line(i));
                    srcId = myOp.slx.line.getId('line', srcLine{i});
                    cmd = myhiliteCmd(id, id);
                    numb = myhiliteCmd(id, string(i));
                    thisName = myhiliteCmd(srcId, thisName);
                    newMsg = append(numb, ". ❤️ ", thisName, " (", cmd, ")");
                    msg = append(msg, newMsg, newline);
                end
                disp(msg);
            else
                varargout{1} = names;
                varargout{2} = srcLine;
            end

        end


        function varargout = getSampleTime(opts)

            arguments
                opts.line = '';
            end

            for i = 1:nargout
                varargout{i} = [];
            end

            line = opts.line;
            line = myOp.slx.general.checkLine(line);
            sampleTime = cell(length(line), 1);
            if isempty(line)
                return;
            end
            for i = 1:length(line)
                thisLine = line{i};
                [linkedBlocks, linkedPortNums] = myOp.slx.line.getLinkedBlock("line", thisLine, "direction", "src");
                if ~isempty(linkedBlocks)
                    linkedBlock = linkedBlocks{1};
                    linkedBlock = linkedBlock(1);
                    linkedPortNum = linkedPortNums{1};
                    linkedPortNum = linkedPortNum(1);
                    traceDst = myTraceSignal(...
                        'direction', 'dst', ...
                        'block', linkedBlock, ...
                        'porttype', 'o', ...
                        'portNum', linkedPortNum ...
                    );
                    traceDstBlocks = traceDst.trace.blocks;
                else
                    traceDstBlocks = {};
                end

                [linkedBlocks, linkedPortNums] = myOp.slx.line.getLinkedBlock("line", thisLine, "direction", "dst");
                if ~isempty(linkedBlocks)
                    linkedBlock = linkedBlocks{1};
                    linkedBlock = linkedBlock(1);
                    linkedPortNum = linkedPortNums{1};
                    traceSrc = myTraceSignal(...
                        'direction', 'src', ...
                        'block', linkedBlock, ...
                        'porttype', 'i', ...
                        'portNum', linkedPortNum ...
                    );
                    traceSrcBlocks = traceSrc.trace.blocks;
                    traceSrcBlocks = myOp.slx.general.parseBlock(traceSrcBlocks);
                else
                    traceSrcBlocks = {};
                end
                if ~isempty(traceDstBlocks)
                    traceDstBlocks = myOp.slx.general.parseBlock(traceDstBlocks);
                end
                if ~isempty(traceSrcBlocks)
                    traceSrcBlocks = myOp.slx.general.parseBlock(traceSrcBlocks);
                end
                traceAllBlocks = [traceDstBlocks; traceSrcBlocks];

                % 开始计算采样时间
                isOk = false;
                % 首先找到非 RateTransition, subsystem, ModelReference 的 block
                idx1 = cellfun(@(x) ~myOp.slx.priTools.isSubsystem(x), traceAllBlocks);
                idx2 = cellfun(@(x) ~myOp.slx.RateTransition.isRateTransition(x), traceAllBlocks);
                idx = idx1 & idx2;
                targetBlock = traceAllBlocks(idx);
                if ~isempty(targetBlock)
                    for j = 1:length(targetBlock)
                        thisTargetBlock = targetBlock{j};
                        thisSt = get_param(thisTargetBlock.Handle, 'CompiledSampleTime');
                        if ~isempty(thisSt)
                            if ~iscell(thisSt)
                                sampleTime{i} = thisSt;
                                isOk = true;
                                break;
                            else
                                continue;
                            end
                        else
                            continue;
                        end
                    end
                end
                % 如果没有找到, 则找 RateTransition 的 block
                if ~isOk
                    % 先找 src 方向的 RateTransition
                    idx = cellfun(@(x) myOp.slx.RateTransition.isRateTransition(x), targetBlock);
                    targetBlock = traceSrcBlocks(idx);
                    if ~isempty(targetBlock)
                        for j = 1:length(targetBlock)
                            thisTargetBlock = targetBlock{j};
                            thisSt = get_param(thisTargetBlock.Handle, 'CompiledSampleTime');
                            thisStOut = get_param(thisTargetBlock.Handle, 'OutPortSampleTime');
                            thisStOut = eval(thisStOut);
                            thisStOut = [thisStOut, 0];
                            sampleTime{i} = thisStOut;
                            isOk = true;
                            break;
                        end
                    end
                end
                % 如果还没有找到, 则找 dst 方向的 RateTransition
                if ~isOk
                    idx = cellfun(@(x) myOp.slx.RateTransition.isRateTransition(x), targetBlock);
                    targetBlock = traceDstBlocks(idx);
                    if ~isempty(targetBlock)
                        for j = 1:length(targetBlock)
                            thisTargetBlock = targetBlock{j};
                            thisSt = get_param(thisTargetBlock.Handle, 'CompiledSampleTime');
                            thisStOut = get_param(thisTargetBlock.Handle, 'InPortSampleTime');
                            thisStOut = eval(thisStOut);
                            thisStOut = [thisStOut, 0];
                            if ~iscell(thisSt)
                                sampleTime{i} = thisSt;
                                isOk = true;
                            else
                                % 从thisSt里排除thisStOut
                                for k = 1:length(thisSt)
                                    if ~isequal(thisSt{k}, thisStOut)
                                        sampleTime{i} = thisSt{k};
                                        isOk = true;
                                        break;
                                    end
                                end
                            end
                            if isOk
                                break;
                            end
                        end
                    end
                end
                % 如果还没有找到, 则找 subsystem 的 block
                if ~isOk
                    idx = cellfun(@(x) myOp.slx.priTools.isSubsystem(x), targetBlock);
                    targetBlock = traceAllBlocks(idx);
                    if ~isempty(targetBlock)
                        for j = 1:length(targetBlock)
                            thisTargetBlock = targetBlock{j};
                            thisSt = get_param(thisTargetBlock.Handle, 'CompiledSampleTime');
                            if ~isempty(thisSt)
                                if ~iscell(thisSt)
                                    sampleTime{i} = thisSt;
                                    isOk = true;
                                    break;
                                else
                                    continue;
                                end
                            else
                                continue;
                            end
                        end
                    end
                end
                if ~isOk
                    thisLinePath = myOp.slx.line.getId("line", thisLine);
                    thisLinePath = thisLinePath{1};
                    cmdPath = strrep(thisLinePath, newline, ''' newline ''');
                    errorMsg = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, thisLinePath);
                    error(append("❌️ 错误: 无法获取信号线 ", errorMsg, " 的采样时间."));
                end
            end
            if nargout == 1
                varargout{1} = sampleTime;
            elseif nargout >= 2
                msgAll = [];
                for i = 1:length(sampleTime)
                    thisSt = sampleTime{i};
                    thisLine = line{i};
                    thisLineId = myOp.slx.line.getId("line", thisLine);
                    thisLinePath = myOp.slx.line.getLinePath("line", thisLine);
                    thisLinePath = thisLinePath{1};

                    idx = myhiliteCmd(thisLineId, string(i));
                    msg = sprintf('✨ 信号线 %s 的采样时间为: ', myhiliteCmd(thisLineId, thisLinePath));

                    if isempty(thisSt)
                        msg = append(msg, "(空)");
                    elseif iscell(thisSt)
                        stStrs = cell(length(thisSt), 1);
                        for j = 1:length(thisSt)
                            stStrs{j} = mat2str(thisSt{j});
                        end
                        stStr = strjoin(stStrs, ', ');
                        msg = append(msg, stStr);
                    else
                        stStr = mat2str(thisSt);
                        msg = append(msg, stStr);
                    end
                    msg = append(idx, ". ", msg);
                    msgAll = append(msgAll, msg, newline);
                end
                varargout{1} = sampleTime;
                varargout{2} = msgAll;
            else
                for i = 1:length(sampleTime)
                    thisSt = sampleTime{i};
                    thisLine = line{i};
                    thisLineId = myOp.slx.line.getId("line", thisLine);
                    thisLinePath = myOp.slx.line.getLinePath("line", thisLine);
                    thisLinePath = thisLinePath{1};
                    
                    idx = myhiliteCmd(thisLineId, string(i));
                    msg = sprintf('✨ 信号线 %s 的采样时间为: ', myhiliteCmd(thisLineId, thisLinePath));

                    if isempty(thisSt)
                        msg = append(msg, "(空)");
                    elseif iscell(thisSt)
                        stStrs = cell(length(thisSt), 1);
                        for j = 1:length(thisSt)
                            stStrs{j} = mat2str(thisSt{j});
                        end
                        stStr = strjoin(stStrs, ', ');
                        msg = append(msg, stStr);
                    else
                        stStr = mat2str(thisSt);
                        msg = append(msg, stStr);
                    end
                    msg = append(idx, ". ", msg);
                    disp(msg);
                end
            end
        end

        
        function varargout = checkSignalHierarchy(opts)
            % checkSignalHierarchy 解析信号层次结构
            % sigList = checkSignalHierarchy(SignalHierarchy)

            arguments
                opts.line = '';
                opts.depth (1,1) double = Inf; % 🟢 新增: 指定最大搜索深度，默认为 Inf (无限制)
            end
            
            line = myOp.slx.general.checkLine(opts.line);
            sigList = {};
            if isempty(line)
                if nargout >= 1
                    varargout{1} = sigList;
                end
                return;
            end

            for i = 1:length(line)
                thisLineSigList = [];
                thisLine = line{i};
                port = myOp.slx.line.getLinkedPort('line', thisLine, 'direction', 'src');
                if isempty(port)
                    sigList{i} = {};
                    continue;
                end
                port = port{1};
                sigHierarchy = get_param(port.Handle, 'SignalHierarchy');
                
                % 🟡 传入 depth 参数进行层级控制
                thisLineSigList = myOp.slx.line.parseSignalHierarchy(sigHierarchy, opts.depth);
                sigList{i} = thisLineSigList;
            end
            if nargout >= 1
                varargout{1} = sigList;
            else
                for i = 1:length(sigList)
                    thisSigList = sigList{i};
                    thisLine = line{i};
                    thisLinePath = myOp.slx.line.getLinePath("line", thisLine);
                    thisLinePath = string(thisLinePath);
                    cmdPath = strrep(thisLinePath, newline, ''' newline ''');
                    idx = sprintf('<a href="matlab:myhilite([''%s''])">%s</a>', cmdPath, string(i));
                    msg = sprintf('✨ 信号线 <a href="matlab:myhilite([''%s''])">%s</a> 的信号层次结构为: ', cmdPath, thisLinePath);
                    msg = append(idx, ". ", msg);
                    if isempty(thisSigList)
                        msg = append(msg, "(空)");
                    else
                        sigStr = strjoin(thisSigList, newline);
                        msg = append(msg, newline, sigStr);
                    end
                    disp(msg);
                end
            end
        end


        function clearResolvedSig(opts)

            arguments
                opts.line = '';
                opts.block = '';
                opts.searchDepth = Inf;
            end

            line = myOp.slx.line.getAll(...
                'line', opts.line, ...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );

            if isempty(line)
                return;
            end

            lineChanged = {};
            for i = 1:length(line)
                thisLine = line{i};
                if thisLine.MustResolveToSignalObject
                    thisLine.MustResolveToSignalObject = false;
                    lineChanged{end+1} = thisLine;
                end
            end
            for i = 1:length(lineChanged)
                thisLine = lineChanged{i};
                thisLineId = myOp.slx.line.getId("line", thisLine);
                thisLineId = thisLineId{1};
                thisLineName = myOp.slx.line.getPrpgtSigName("line", thisLine);
                msg = myhiliteCmd(thisLineId, thisLineName);
                num = myhiliteCmd(thisLineId, string(i));
                msg = append(num, '. ', '✨ 已清除信号线 ', msg, ' 的 MustResolveToSignalObject 属性. ');
                disp(msg);
            end
        end

        
        function clearDataLogging(opts)
            arguments
                opts.line = '';
                opts.block = '';
                opts.searchDepth = Inf;
            end
            line = myOp.slx.line.getAll(...
                'line', opts.line, ...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );
            if isempty(line)
                return;
            end
            myOp.slx.line.changeValue(...
                'line', line, ...
                'propName', 'DataLogging', ...
                'replaceValue', true, ...
                'value', false ...
            );
        
        end


        function changeValue(opts)
            arguments
                opts.line = '';
                opts.block = '';
                opts.propName = '';
                opts.replaceValue = '';
                opts.value = '';
                opts.searchDepth = 0;
            end
            line = myOp.slx.line.getAll(...
                'line', opts.line, ...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );
            if isequal(opts.value, "") && isequal(opts.propName, "") && isequal(opts.replaceValue, "")
                msg = ("⚠️ 注意: 输入的 value 和 propName 和 replaceValue 均为空, 如果确认要继续执行, 请点击是");
                d = questdlg(msg, '确认', '是', '否', '否');
                if ~isequal(d, '是')
                    return;
                end
            end

            for i = 1:length(line)
                thisLine = line{i};
                if isequal(opts.propName, "")
                    propNames = properties(thisLine);
                else
                    propNames = {opts.propName};
                end

                for j = 1:length(propNames)
                    propName = propNames{j};
                    try
                        oldValue = [];
                        if isequal(opts.replaceValue, "")
                            newValue = opts.value;
                        else
                            oldValue = thisLine.(propName);
                            if isstring(oldValue) || ischar(oldValue)
                                [isMatched, newValue] = myOp.slx.line.calcReplacedValue(oldValue, opts.replaceValue, opts.value);
                                if ~isMatched
                                    continue;
                                end
                            else
                                newValue = opts.value;
                            end
                        end
                        if isequal(oldValue, newValue)
                            continue;
                        end
                        thisLine.(propName) = newValue;
                        myOp.slx.line.dispChangeValueMsg(thisLine, i, propName, oldValue, newValue, opts.replaceValue);
                    catch
                    end
                end
            end
        end


        function clearLineName(opts)
            arguments
                opts.line = '';
                opts.block = '';
                opts.searchDepth = Inf;
            end
            line = myOp.slx.line.getAll(...
                'line', opts.line, ...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );
            if isempty(line)
                return;
            end
            for i = 1:length(line)
                thisLine = line{i};
                oldName = get_param(thisLine.Handle, 'Name');
                if isequal(oldName, "")
                    continue;
                end
                try
                    set_param(thisLine.Handle, 'Name', '');
                    thisLineId = myOp.slx.line.getId("line", thisLine);
                    thisLineId = thisLineId{1};
                    msg = myhiliteCmd(thisLineId, oldName);
                    num = myhiliteCmd(thisLineId, string(i));
                    msg = append(num, '. ', '✨ 已清除信号线 ', msg, ' 的名称. ');
                    disp(msg);
                catch
                    thisLineId = myOp.slx.line.getId("line", thisLine);
                    thisLineId = thisLineId{1};
                    msg = myhiliteCmd(thisLineId, oldName);
                    num = myhiliteCmd(thisLineId, string(i));
                    msg = append(num, '. ', '⚠️ 注意: 无法清除信号线 ', msg, ' 的名称. ');
                    disp(msg);
                end
            end
        end

    end

    methods(Access = private, Static)

        function [isMatched, newValue] = calcReplacedValue(oldValue, replaceValue, value)
            if ~contains(oldValue, replaceValue)
                isMatched = false;
                newValue = oldValue;
                return;
            end
            isMatched = true;
            newValue = strrep(oldValue, replaceValue, value);
        end

        function dispChangeValueMsg(thisLine, idx, propName, oldValue, newValue, replaceValue)
            id = myOp.slx.line.getId("line", thisLine);
            id = id{1};
            cmd = myhiliteCmd(id, id);
            numb = myhiliteCmd(id, string(idx));
            if isequal(replaceValue, "")
                msg = append(numb, '. ', '✨ 已修改信号线 ', cmd, ' 的属性 <', propName, '> 为 <', string(newValue), '>.');
            else
                msg = append(numb, '. ', '✨ 已修改信号线 ', cmd, ' 的属性 <', propName, '> 从 <', string(oldValue), '> 替换 <', string(replaceValue), '> 为 <', string(newValue), '>.');
            end
            disp(msg);
        end

        function sigList = parseSignalHierarchy(SignalHierarchy, maxDepth)
            % parseSignalHierarchy 解析信号层次结构 (迭代版本)
            
            if nargin < 2
                maxDepth = Inf;
            end

            % 初始化输出为字符串列向量，比空矩阵 [] 拼接更稳健
            sigList = []; 

            % 🔵 1. 初始化栈 (Stack)
            % 栈内每个元素是一个结构体，保存当前节点、已累积的前缀路径、当前深度
            stack = struct('node', SignalHierarchy, 'prefix', "", 'depth', 1);

            while ~isempty(stack)
                % 弹栈 (取最后一个元素并移除)
                currItem = stack(end);
                stack(end) = [];

                node = currItem.node;
                prefix = currItem.prefix;
                depth = currItem.depth;

                signalName = string(node.SignalName);

                % 🟣 2. 拼接当前层级的信号路径
                if signalName == ""
                    nextPrefix = prefix;
                elseif prefix == ""
                    nextPrefix = signalName;
                else
                    nextPrefix = prefix + "." + signalName;
                end

                % 🟢 3. 截断条件：判断是否到达叶子节点，或已达到最大指定深度
                children = node.Children;
                if isempty(children) || depth >= maxDepth
                    if nextPrefix ~= ""
                        sigList = [sigList; nextPrefix];
                    end
                else
                    % 🟡 4. 子节点压栈
                    % 重点：为了保持与原递归函数完全一致的输出顺序（从上到下），这里必须【倒序压栈】
                    for i = length(children):-1:1
                        newItem.node = children(i);
                        newItem.prefix = nextPrefix;
                        newItem.depth = depth + 1;
                        stack(end+1) = newItem; %#ok<AGROW> 
                    end
                end
            end
        end

    end
end 