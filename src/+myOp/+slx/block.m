classdef block

    methods(Static)

        function ports = getBlockPort(opts)
            %   获取 block 的端口信息
            %   ports = blockGetBlockPort()
            %   输入:
            %       block - 模型中的 block 路径或句柄或者 block 对象, 如果不指定则默认为当前选择的 block
            %   输出:
            %       ports - block 端口信息的结构体数组

            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, {'Inport'; 'Outport'; ''})} = '';
                opts.portNum {mustBeNonnegative(opts.portNum)} = 0;
            end

            block = opts.block;

            block = myOp.slx.general.checkBlock(block);

            ports = cell(0);
            for i = 1:length(block)
                thisBlock = block{i};
                % 获取端口信息
                portInfo = get_param(thisBlock.Handle, 'PortHandles');

                % 输入端口
                inPorts = portInfo.Inport;
                if isequal(opts.portType, 'Inport') || isequal(opts.portType, '')
                    if length(inPorts) < opts.portNum
                        error('指定的端口号超过了输入端口的数量。');
                    end
                    for j = 1:length(inPorts)
                        thisInport = inPorts(j);
                        if isequal(opts.portNum, j) || isequal(opts.portNum, 0)
                            thisInport = myOp.slx.general.checkBlock(thisInport);
                            ports = [ports; thisInport];
                        end
                    end
                end

                % 输出端口
                outPorts = portInfo.Outport;
                if isequal(opts.portType, 'Outport') || isequal(opts.portType, '')
                    if length(outPorts) < opts.portNum
                        error('指定的端口号超过了输出端口的数量。');
                    end
                    for j = 1:length(outPorts)
                        thisOutport = outPorts(j);
                        if isequal(opts.portNum, j) || isequal(opts.portNum, 0)
                            thisOutport = myOp.slx.general.checkBlock(thisOutport);
                            ports = [ports; thisOutport];
                        end
                    end
                end
            end
        end
    
        function line = getBlockLine(opts)
            %   获取 block 的连线信息
            %   line = blockGetBlockLine()
            %   输入:
            %       block - 模型中的 block 路径或句柄或者 block 对象, 如果不指定则默认为当前选择的 block
            %   输出:
            %       line - block 连线信息的结构体数组

            arguments
                opts.block = '';
                opts.lineType {mustBeMember(opts.lineType, {'Inport'; 'Outport'; ''})} = '';
                opts.lineNum {mustBeNonnegative(opts.lineNum)} = 0;
            end

            block = opts.block;

            block = myOp.slx.general.checkBlock(block);

            line = cell(0);
            for i = 1:length(block)
                thisBlock = block{i};

                thisBlockPorts = myOp.slx.block.getBlockPort("block", thisBlock, "portType", opts.lineType, "portNum", opts.lineNum);
                for j = 1:length(thisBlockPorts)
                    thisPort = thisBlockPorts{j};
                    portLine = get_param(thisPort.Handle, 'Line');
                    if isequal(portLine, -1)
                        continue;
                    end
                    portLine = myOp.slx.general.checkLine(portLine);
                    line = [line; portLine(:)];
                end

                % 获取连线信息
                % lineInfo = get_param(thisBlock.Handle, 'LineHandles');

                % inLines = lineInfo.Inport;
                % outLines = lineInfo.Outport;

                % inLines = myOp.slx.general.checkLine(inLines);
                % outLines = myOp.slx.general.checkLine(outLines);

                % if isequal(opts.lineType, 'Inport') || isequal(opts.lineType, '')
                %     if length(inLines) < opts.lineNum
                %         error('指定的连线号超过了输入连线的数量。');
                %     end
                %     if isequal(opts.lineNum, 0)
                %         inLines = inLines(:);
                %     else
                %         inLines = inLines(opts.lineNum);
                %     end
                % else
                %     inLines = cell(0);
                % end

                % if isequal(opts.lineType, 'Outport') || isequal(opts.lineType, '')
                %     if length(outLines) < opts.lineNum
                %         error('指定的连线号超过了输出连线的数量。');
                %     end
                %     if isequal(opts.lineNum, 0)
                %         outLines = outLines(:);
                %     else
                %         outLines = outLines(opts.lineNum);
                %     end
                % else
                %     outLines = cell(0);
                % end

                % line = [line; inLines(:); outLines(:)];
            end
        end
    
        function [parNames, parValues] = getBlockPars(opts)
        %  获取block里使用的Simulink参数
        %   [parNames, parValues] = busBlockGetBlockPars(opts)
        %   输入:
        %       block - 模型中的 block 路径或句柄或者 block
        %               对象, 如果不指定则默认为当前选择的 block
        %   输出:
        %       parNames - 所有 Bus 被使用的元素的名称的 cell 数组
        %       parValues - 所有 Bus 被使用的元素的数据类型的 cell 数组

            arguments
                opts.block = '';
            end
            block = opts.block;

            block = myOp.slx.general.checkBlock(block);

            % 控制参数的数据类型
            ctrlParDataTypes = myOp.slx.std.getCtParDataType();
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
            parNames = myOp.slx.std.ctParSort(parNames);
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

        function transLineName(opts)
        % 将一个block的输入信号线的名字转换为输出信号线的名字, 或者反之
            arguments
                opts.block = '';
                opts.direction {mustBeMember(opts.direction, ["in2out"; "out2in"; ""])} = '';
            end

            block = opts.block;
            direction = opts.direction;

            block = myOp.slx.general.checkBlock(block);

            for i = 1:length(block)
                thisBlock = block{i};
                % 获取输入端口的名字
                inports = get_param(thisBlock.Handle, 'PortHandles');
                inports = inports.Inport;
                inportNames = arrayfun(@(x) get_param(x, 'Name'), inports, 'UniformOutput', false);
                % 获取输出端口的名字
                outports = get_param(thisBlock.Handle, 'PortHandles');
                outports = outports.Outport;
                outportNames = arrayfun(@(x) get_param(x, 'Name'), outports, 'UniformOutput', false);
                % 如果direction为 in, 则将inport的名字赋给outport
                commenLen = min(length(inports), length(outports));
                directions = strings(commenLen, 1);
                for j = 1:commenLen
                    if isequal(direction, '')
                        inportName = inportNames{j};
                        outportName = outportNames{j};
                        if isequal(inportName, outportName)
                            directions(j) = 'same';
                        elseif isempty(inportName)
                            directions(j) = 'out2in';
                        elseif isempty(outportName)
                            directions(j) = 'in2out';
                        elseif ~isempty(inportName) && ~isempty(outportName) && ~isequal(inportName, outportName)
                            directions(j) = 'conflict';
                        end
                    elseif isequal(direction, 'in2out')
                        directions(j) = 'in2out';
                    elseif isequal(direction, 'out2in')
                        directions(j) = 'out2in';
                    end
                end
                for j = 1:commenLen
                    direction = directions(j);
                    if isequal(direction, "same")
                        continue;
                    elseif isequal(direction, "conflict")
                        warning(append("端口 ", num2str(j), " 的输入输出名字冲突, 无法转换, 跳过此端口。"));
                        continue;
                    end
                    inport = inports(j);
                    outport = outports(j);
                    inportName = inportNames{j};
                    outportName = outportNames{j};
                    if strcmp(direction, 'in2out')
                        newName = myOp.slx.line.normalizeName(name = inportName);
                        line = get_param(outport, 'Line');
                        set_param(line, 'Name', newName);
                        id = myOp.slx.block.getId("block", thisBlock);
                        msg = append("✅️ 已将 block '", myhiliteCmd(id, id), "' 的第 ", num2str(j), " 个 <输入端口> 的名字 '", inportName, "' 传递给 <输出信号线>。");
                        disp(msg);
                    else
                        newName = myOp.slx.line.normalizeName(name = outportName);
                        line = get_param(inport, 'Line');
                        set_param(line, 'Name', newName);
                        msg = append("✅️ 已将 block '", myhiliteCmd(id, id), "' 的第 ", num2str(j), " 个 <输出端口> 的名字 '", outportName, "' 传递给 <输入信号线>。");
                        disp(msg);
                    end
                end
            end
        end

        function [srcBlock, srcPortNum] = getLastBlock(opts)
            
            arguments
                opts.block = '';
                opts.portNum = 1;
                opts.lookUnderMask = true;
            end
        
            block = opts.block;
            portNum = opts.portNum;
            lookUnderMask = opts.lookUnderMask;
        
            % 处理 block
            block = myOp.slx.general.checkBlock(block);
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
                gotoBlock = myOp.slx.goFrom.getMatched("block", block);
        
                if isempty(gotoBlock)
                    error('gotoBlock not found.');
                end
        
                gotoBlock = myOp.slx.general.checkBlock(gotoBlock);
                srcBlock = gotoBlock;  % 直接返回整个 cell 数组
                srcPortNum = num2cell(ones(length(gotoBlock), 1)); % 端口号全为 1
        
            % 如果是 Inport 模块
            elseif strcmp(block.BlockType, 'Inport')
                parentBlock = get_param(block.Handle, 'Parent');
                parentBlock = myOp.slx.general.checkBlock(parentBlock);
                parentBlock = parentBlock{1}; % 取出父模块
        
                parentBlockPortNum = get_param(block.Handle, 'Port');
                srcBlock = {parentBlock};
                srcPortNum = {double(parentBlockPortNum)};
        
            % 处理 lookUnderMask 逻辑
            elseif lookUnderMask
                [srcBlock, srcPortNum] = myOp.slx.block.getLastBlock('block', block, 'portNum', portNum, 'lookUnderMask', false);
                if isempty(srcBlock)
                    error('No Outport found in the SubSystem.');
                end
                if myOp.slx.priTools.isSubsystem(srcBlock)
                    srcBlock = find_system(srcBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Outport', 'Port', num2str(srcPortNum));
                    if isempty(srcBlock)
                        error('No Outport found in the SubSystem.');
                    end
                    srcPortNum = num2cell(ones(length(srcBlock), 1)); % 端口号全为 1
                end
                
                srcBlock = myOp.slx.general.checkBlock(srcBlock);
        
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
                    srcBlock = myOp.slx.general.checkBlock(srcBlock);
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
            end

            block = opts.block;
            portNum = opts.portNum;
            desNum = opts.desNum;
        
            % 处理 block
            block = myOp.slx.general.checkBlock(block);
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
                fromBlock = myOp.slx.goFrom.getMatched("block", block);
        
                if isempty(fromBlock)
                    return;
                end
        
                fromBlock = myOp.slx.general.checkBlock(fromBlock);
                desBlock = fromBlock; % 直接返回所有匹配的 fromBlock
                desPortNum = num2cell(ones(length(fromBlock), 1)); % 端口号全为 1
        
            % 如果 block 是 Outport 模块
            elseif strcmp(block.BlockType, 'Outport')
                parentBlock = get_param(block.Handle, 'Parent');
                parentBlock = myOp.slx.general.checkBlock(parentBlock);
                parentBlock = parentBlock{1}; % 取出父模块
        
                parentBlockPortNum = get_param(block.Handle, 'Port');
                desBlock = {parentBlock};
                desPortNum = {double(parentBlockPortNum)};
            
            % 如果 lookUnderMask 为 true，查找子系统内部的连接
            elseif lookUnderMask
                [desBlock, desPortNum] = myOp.slx.block.getNextBlock('block', block, 'portNum', portNum, 'desNum', desNum, 'lookUnderMask', false);
                desBlock = myOp.slx.general.checkBlock(desBlock);
                if isempty(desBlock)
                    return;
                end
                tempBlock = desBlock{1};  % 取第一个 block
                tempPortNum = desPortNum{1};  % 取第一个端口号
                if strcmp(tempBlock.BlockType, 'SubSystem') && ~myOp.slx.matlabFunction.isMatlabFunction(tempBlock)
                    tempBlock = find_system(tempBlock.Handle, 'SearchDepth', 1, 'BlockType', 'Inport', 'Port', num2str(tempPortNum));
                    if isempty(tempBlock)
                        return;
                    end
                    desBlock = myOp.slx.general.checkBlock(tempBlock);
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
                        desBlock(i) = myOp.slx.general.checkBlock(desBlock{i});
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

        function [blocks] = getAll(opts)
        % GETALL  获取所有模块
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisBlocks = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
                    'SearchDepth', opts.searchDepth, ...
                    'Type', 'Block' ...
                );
                if isempty(thisBlocks)
                    continue;
                end
                thisBlocks = myOp.slx.general.checkBlock(...
                    thisBlocks ...
                );
                blocks = [blocks; thisBlocks];
            end
        end

        function varargout = getSampleTime(opts)
            arguments
                opts.block = '';
            end
            for i = 1:nargout
                varargout{i} = [];
            end
            block = myOp.slx.general.checkBlock(opts.block);
            sampleTimes = cell(length(block), 1);
            for i = 1:length(block)
                thisBlock = block{i};
                sampleTime = get_param(thisBlock.Handle, 'CompiledSampleTime');
                if isequal(sampleTime, [-1, -1])
                    % 有可能是个Chart里面的子块, 一步步寻找父块的采样时间
                    searchBlock = thisBlock;
                    while true
                        searchBlock = get_param(searchBlock.Handle, 'Parent');
                        if isempty(searchBlock)
                            thisBlockPath = getfullname(thisBlock.Handle);
                            msg = myhiliteCmd(thisBlockPath, thisBlockPath);
                            warning('⚠️ 无法找到块 %s 的采样时间', msg);
                            break;
                        end
                        searchBlock = get_param(searchBlock, 'object');
                        isChart = myOp.slx.priTools.isChart(searchBlock);
                        if isChart
                            sampleTime = get_param(searchBlock.Handle, 'CompiledSampleTime');
                            if isequal(sampleTime, [-1, -1])
                                continue;
                            else
                                break;
                            end
                        else
                            continue;
                        end
                    end
                end
                sampleTimes{i} = sampleTime;
            end
            if nargout == 1
                varargout{1} = sampleTimes;
            elseif nargout == 2
                msgAll = [];
                for i = 1:length(block)
                    thisBlock = block{i};
                    sampleTime = sampleTimes{i};
                    thisBlockPath = getfullname(thisBlock.Handle);
                    idx = myhiliteCmd(thisBlockPath, string(i));
                    msg = myhiliteCmd(thisBlockPath, thisBlockPath);
                    msg = append('🌙 ', msg, ' 的采样时间: ', mat2str(sampleTime));
                    msg = append(idx, '. ', msg);
                    msgAll = append(msgAll, msg, newline);
                end
                varargout{1} = sampleTimes;
                varargout{2} = msgAll;
            else
                for i = 1:length(block)
                    thisBlock = block{i};
                    sampleTime = sampleTimes{i};
                    thisBlockPath = getfullname(thisBlock.Handle);
                    idx = myhiliteCmd(thisBlockPath, string(i));
                    msg = myhiliteCmd(thisBlockPath, thisBlockPath);
                    msg = append('🌙 ', msg, ' 的采样时间: ', mat2str(sampleTime));
                    msg = append(idx, '. ', msg);
                    disp(msg);
                end
            end
                
        end
        
        function varargout = getId(opts)
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            ids = cell(length(block), 1);
            for i = 1:length(block)
                thisBlock = block{i};
                % 绝对路径
                path = thisBlock.Path;
                name = thisBlock.Name;
                id = append(path, '/', name);
                id = string(id);
                ids{i} = id;
            end
            if nargout == 1
                varargout{1} = ids;
            else
                for i = 1:length(block)
                    thisBlock = block{i};
                    id = ids{i};
                    msg = myhiliteCmd(id, id);
                    sNum = myhiliteCmd(id, string(i));
                    msg = append(sNum, '. ', msg);
                    disp(msg);
                end
            end
        end

        function varargout = sortByPosition(opts)
        % SORTBYPOSITION  根据模块在 Simulink 模型中的位置对模块进行排序
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            if isempty(block)
                if nargout == 1
                    varargout{1} = {};
                end
                return;
            end

            positions = zeros(length(block), 4);
            for i = 1:length(block)
                thisBlock = block{i};
                position = get_param(thisBlock.Handle, 'Position');
                positions(i, :) = position;
            end
            % 获取全部模块最左侧和最顶部的位置
            leftPos = min(positions(:, 1));
            topPos = min(positions(:, 2));
            originPoint = [leftPos, topPos];
            % 计算每个模块的中心位置
            centerPos = [positions(:, 1) + positions(:, 3) / 2, positions(:, 2) + positions(:, 4) / 2];
            % 计算每个模块中心位置与最左上角位置的距离
            distances = sqrt((centerPos(:, 1) - originPoint(1)).^2 + (centerPos(:, 2) - originPoint(2)).^2);
            % 根据距离对模块进行排序
            [~, sortIdx] = sort(distances);
            sortBlocks = block(sortIdx);
            if nargout == 1
                varargout{1} = sortBlocks;
            else
                sortBlockIds = myOp.slx.block.getId('block', sortBlocks);
                for i = 1:length(sortBlockIds)
                    displayName = strrep(string(sortBlockIds{i}), newline, ' ');
                    msg = myhiliteCmd(sortBlockIds{i}, displayName);
                    serialNum = myhiliteCmd(sortBlockIds{i}, string(i));
                    msg = append(serialNum, '. ', msg);
                    disp(msg);
                end
            end
        end
    
        function varargout = changeValue(opts)
        % CHANGEVALUE  修改模块的参数值
            arguments
                opts.block = '';
                opts.parName = '';
                opts.parValueReplace = '';
                opts.parValue = '';
                opts.scope {mustBeMember(opts.scope, {'current'; 'all'})} = 'current';
            end
            if isequal(opts.scope, 'current')
                block = myOp.slx.general.checkBlock(opts.block);
            else
                block = myOp.slx.block.getAll('block', opts.block);
            end
            parName = opts.parName;
            parValueReplace = opts.parValueReplace;
            parValue = opts.parValue;
            if isequal(parName, '') && isequal(parValueReplace, '')
                error('请至少指定 parName 或 parValueReplace 中的一个参数。');
            end

            for i = 1:length(block)
                thisBlock = block{i};
                try
                    if isequal(parValueReplace, '')
                        oldParValue = get_param(thisBlock.Handle, parName);
                        newParValue = parValue;
                        if isequal(oldParValue, newParValue)
                            continue;
                        end
                        set_param(thisBlock.Handle, parName, parValue);
                    elseif isequal(parName, '')
                        prop = properties(thisBlock.Handle);
                        for j = 1:length(prop)
                            propName = prop{j};
                            try
                                oldParValue = get_param(thisBlock.Handle, propName);
                                newParValue = strrep(oldParValue, parValueReplace, parValue);
                                if isequal(oldParValue, newParValue)
                                    continue;
                                end
                                set_param(thisBlock.Handle, propName, parValue);
                                id = myOp.slx.block.getId('block', thisBlock);
                                msg = myhiliteCmd(id, id);
                                msg = append('✅ 已将模块 ', msg, ' 的参数 ', propName, ' 从 ', parValueReplace, ' 修改为 ', parValue);
                                disp(msg);
                            catch
                                continue;
                            end
                        end
                    else
                        oldParValue = get_param(thisBlock.Handle, parName);
                        newParValue = strrep(oldParValue, parValueReplace, parValue);
                        if isequal(oldParValue, newParValue)
                            continue;
                        end
                        set_param(thisBlock.Handle, parName, newParValue);
                    end 
                    id = myOp.slx.block.getId('block', thisBlock);
                    msg = myhiliteCmd(id, id);
                    msg = append('✅ 已将模块 ', msg, ' 的参数 ', parName, ' 从 ', oldParValue, ' 修改为 ', newParValue);
                    disp(msg);
                catch ME
                    warning(ME.identifier, '%s', ME.message);
                    id = myOp.slx.block.getId('block', thisBlock);
                    msg = myhiliteCmd(id, id);
                    msg = append('⚠️ 无法修改模块 ', msg, ' 的参数 ', parName);
                    disp(msg);
                end
            end
        end

    end
end