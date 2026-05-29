classdef busBlock

    methods(Static)

        function varargout = checkBlock(opts)
        % CHECKBLOCK  检查并返回 Bus (Selector/Creator) 模块
            arguments
                opts.block = '';
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            if isempty(block)
                varargout{1} = {};
                return;
            end
            validBlocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'BusSelector') || strcmp(thisBlock.BlockType, 'BusCreator')
                    validBlocks{end+1} = thisBlock; %#ok<AGROW>
                end
            end
            validBlocks = validBlocks(:);
            if nargout == 1
                varargout{1} = validBlocks;
            else
                for i = 1:length(validBlocks)
                    thisBlock = validBlocks{i};
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    idxString = myhiliteCmd("idx", string(i));
                    type = get_param(thisBlock.Handle, 'BlockType');
                    msg = append(idxString, ". ", string(type), "模块: ", cmd);
                    disp(msg);
                end
            end
        end

        function varargout = getAll(opts)
        % GETALL  获取系统中所有的 Bus (Selector/Creator) 模块
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
                thisBlocks = myOp.slx.busBlock.checkBlock(...
                    'block', thisBlocks ...
                );
                blocks = [blocks; thisBlocks];
            end
            blocks = blocks(:);
            if nargout == 1
                varargout{1} = blocks;
            else
                for i = 1:length(blocks)
                    thisBlock = blocks{i};
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    idxString = myhiliteCmd("idx", string(i));
                    type = get_param(thisBlock.Handle, 'BlockType');
                    msg = append(idxString, ". ", string(type), "模块: ", cmd);
                    disp(msg);
                end
            end
        end

        function outNames = getElementNames(opts)
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
        
            block = myOp.slx.general.checkBlock(block);

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
        
        function dataType = getElementDataType(opts)
        %   获取BusSelector或BusCreator中使用的元素的数据类型
        %   dataType = busBlockGetElementDataType(opts)
        %
        %   输入:
        %       block - 模型中的 block 路径或句柄或者 block 对象, 如果不指定则默认为当前选择的 block
        %
        %   输出:
        %       dataType - 所有 Bus 被使用的元素的数据类型的 cell 数组

            arguments
                opts.block = '';
            end

            block = opts.block;

            block = myOp.slx.general.checkBlock(block);

            dataType = cell(0);
            for i = 1:length(block)
                thisBlock = block{i};
                % 如果是 Bus Selector
                if strcmp(thisBlock.BlockType, 'BusSelector')
                    lines = myOp.slx.block.getBlockLine(...
                        'block', thisBlock.Handle, ...
                        'lineType', 'Outport' ...
                    );
                    thisDataType = myOp.slx.line.getLineDataType("line", lines);
                    dataType = [dataType; thisDataType];
                end
                % 如果是 Bus Creator
                if strcmp(thisBlock.BlockType, 'BusCreator')
                    lines = myOp.slx.block.getBlockLine(...
                        'block', thisBlock.Handle, ...
                        'lineType', 'Inport' ...
                    );
                    thisDataType = myOp.slx.line.getLineDataType("line", lines);
                    dataType = [dataType; thisDataType];
                end
            end
        end
    
        function varargout = setElementNames(opts)
            arguments
                opts.block = '';
                opts.elementNames = {};
            end

            block = opts.block;
            elementNames = opts.elementNames;
            if isempty(elementNames)
                return;
            end

            block = myOp.slx.general.checkBlock(block);
            changedBlocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'BusSelector')
                    elementNamesStr = strjoin(elementNames, ',');
                    if ~strcmp(get_param(thisBlock.Handle, 'OutputSignals'), elementNamesStr)
                        changedBlocks{end+1} = thisBlock;
                        set_param(thisBlock.Handle, 'OutputSignals', elementNamesStr);
                    end
                end
                if strcmp(thisBlock.BlockType, 'BusCreator')
                    elementNamesStr = strjoin(elementNames, ',');
                    if ~strcmp(get_param(thisBlock.Handle, 'InputSignalNames'), elementNamesStr)
                        changedBlocks{end+1} = thisBlock;
                        set_param(thisBlock.Handle, 'InputSignalNames', elementNamesStr);
                    end
                end
            end
            if nargout == 1
                varargout{1} = changedBlocks;
            else
                for i = 1:length(changedBlocks)
                    thisBlock = changedBlocks{i};
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    idxString = myhiliteCmd("idx", string(i));
                    type = get_param(thisBlock.Handle, 'BlockType');
                    msg = append(idxString, ". ", string(type), "模块: ", cmd, " 的元素已更新");
                    disp(msg);
                end
            end
        end

        function busBlock_flushPortName(opts)

            arguments
                opts.block = '';
            end

            block = opts.block;
            block = myOp.slx.general.checkBlock(block);

            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'BusCreator')
                    thisDataType = thisBlock.OutDataTypeStr;
                    if contains(thisDataType, 'Bus:')
                        busName = extractAfter(thisDataType, 'Bus: ');
                        % 从基础工作区获取 bus 对象
                        busObj = evalin('base', busName);
                        elementNames = {busObj.Elements.Name};

                        inLines = myOp.slx.block.getBlockLine(...
                            'block', thisBlock.Handle, ...
                            'lineType', 'Inport' ...
                        );
                        for j = 1:length(inLines)
                            lineObj = inLines{j};
                            lineName = lineObj.Name;
                            correctName = elementNames{j};
                            correctName = myOp.slx.line.normalizeName("name", correctName);
                            lineName = myOp.slx.line.normalizeName("name", lineName);
                            if ~strcmp(lineName, correctName)
                                try
                                    lineObj.Name = correctName;
                                catch
                                end
                            end
                        end
                    end
                end
            end
        end

        function varargout = getSelectorSignalHierarchy(opts)
            arguments
                opts.block = '';
            end
            block = myOp.slx.busBlock.checkBlock("block", opts.block);
            selectorBlocks = {};
            
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'BusSelector')
                    selectorBlocks{end+1} = thisBlock;
                    selectorBlocks = selectorBlocks(:);
                end
            end
            block = selectorBlocks;
            selectorSignalHierarchy = cell(length(block), 1);
            for i = 1:length(block)
                thisBlock = block{i};
                lines = myOp.slx.block.getBlockLine(...
                        'block', thisBlock.Handle, ...
                        'lineType', 'Inport' ...
                );
                if isempty(lines)
                    continue;
                end
                line = lines{1};
                signalHierarchy = myOp.slx.line.checkSignalHierarchy("line", line);
                selectorSignalHierarchy{i} = signalHierarchy{1};
            end

            if nargout == 1
                varargout{1} = selectorSignalHierarchy;
            else
                blockId = myOp.slx.block.getId("block", block);
                for i = 1:length(block)
                    thisBlockId = blockId{i};
                    thisSignalHierarchy = selectorSignalHierarchy{i};
                    thisBlockIdName = strrep(thisBlockId, newline, " ");
                    name = myhiliteCmd(thisBlockId, thisBlockIdName);
                    num = myhiliteCmd(thisBlockId, string(i));
                    msg = sprintf("%s. 模块: %s; 的信号结构:", num, name);
                    disp(msg);
                    disp(thisSignalHierarchy);
                end
            end
        end

        function varargout = upDateBusSelectorArray(opts)
            arguments
                opts.block = '';
            end
            block = myOp.slx.busBlock.checkBlock("block", opts.block);
            blockSelector = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'BusSelector')
                    blockSelector{end+1} = thisBlock;
                    blockSelector = blockSelector(:);
                    % busObj = evalin('base', extractAfter(thisBlock.OutDataTypeStr, 'Bus: '));
                    % elementNames = {busObj.Elements.Name};
                    % elementNamesStr = strjoin(elementNames, ',');
                    % set_param(thisBlock.Handle, 'OutputSignals', elementNamesStr);
                end
            end
            block = blockSelector;
            % 获取 全部的模块的信号结构
            
        end

        function varargout = selectorOne2Multi(opts)
            arguments
                opts.block = '';
            end
            block = myOp.slx.busBlock.checkBlock("block", opts.block);
            searchBlocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'BusSelector')
                    searchBlocks{end+1} = thisBlock;
                    searchBlocks = searchBlocks(:);
                end
            end
            newBlocks = {};
            for i = 1:length(searchBlocks)
                thisBlock = searchBlocks{i};
                % 获取输出信号
                outputSignals = myOp.slx.busBlock.getElementNames("block", thisBlock);
                if length(outputSignals) <= 1
                    continue;
                end
                posOr = get_param(thisBlock.Handle, 'Position');
                heightOr = posOr(4) - posOr(2);
                widthOr = posOr(3) - posOr(1);
                segHeight = heightOr / length(outputSignals);
                thisNewBlocks = {};
                for j = 1:length(outputSignals)
                    % 添加 Bus Selector 模块，自动避免重名
                    baseBlockName = "Bus Selector";
                    baseBlockPath = thisBlock.Parent + "/" + baseBlockName;

                    hNewBlock = add_block( ...
                        'simulink/Signal Routing/Bus Selector', ...
                        baseBlockPath, ...
                        'MakeNameUnique', 'on');

                    % 获取 Simulink 实际生成的模块路径和名称
                    newBlockPath = string(getfullname(hNewBlock));
                    
                    % 设置新模块的位置
                    thisPos = get_param(hNewBlock, 'Position');
                    thisHeight = thisPos(4) - thisPos(2);
                    thisWidth = thisPos(3) - thisPos(1);
                    newPos = [...
                        posOr(1) + widthOr + 10, ...
                        posOr(2) + (j-1)*segHeight, ...
                        posOr(1) + widthOr + 10 + thisWidth, ...
                        posOr(2) + (j-1)*segHeight + thisHeight
                    ];
                    set_param(newBlockPath, 'Position', newPos);
                    % 设置新模块的输出信号
                    a = myOp.slx.busBlock.setElementNames("block", hNewBlock, "elementNames", outputSignals(j));
                    thisNewBlock = myOp.slx.general.parseBlock(newBlockPath);
                    thisNewBlocks{end+1} = thisNewBlock{1};
                    thisNewBlocks = thisNewBlocks(:);
                end
                newBlocks{end+1} = thisNewBlocks;
                newBlocks = newBlocks(:);
            end
            if nargout == 1
                varargout{1} = newBlocks;
            else
                for i = 1:length(newBlocks)
                    thisNewBlocks = newBlocks{i};
                    ftId = myOp.slx.block.getId("block", thisNewBlocks);
                    msg = append("拆分 Bus Selector 模块: ", ftId{1});
                    msg = append(string(i), ". ", msg);
                    disp(msg);
                    for j = 1:length(thisNewBlocks)
                        thisNewBlock = thisNewBlocks{j};
                        id = myOp.slx.block.getId("block", thisNewBlock);
                        cmd = myhiliteCmd(id, id);
                        idxString = myhiliteCmd("idx", string(j));
                        type = get_param(thisNewBlock.Handle, 'BlockType');
                        msg = append(idxString, ". ", string(type), "模块: ", cmd, " 已创建");
                        disp(msg);
                    end
                end
            end
        end

    end
end