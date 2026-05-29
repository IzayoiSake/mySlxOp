classdef subSysBlock

    methods(Static)

        function portName_inOut2Line(opts)

            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, {'Inport', 'Outport', ''})} = '';
            end
            block = opts.block;
            portType = opts.portType;
            block = myOp.slx.subSysBlock.checkBlock("block", block);

            subSysBlock = block;

            for i = 1:length(subSysBlock)
                thisBlock = subSysBlock(i);
                thisBlockInports = myOp.slx.block.getBlockPort("block", thisBlock, "portType", "Inport");
                thisBlockOutports = myOp.slx.block.getBlockPort("block", thisBlock, "portType", "Outport");
                thisBlockInportBlocks = find_system(thisBlock.Handle, 'SearchDepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'BlockType', 'Inport');
                thisBlockOutportBlocks = find_system(thisBlock.Handle, 'SearchDepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'BlockType', 'Outport');
                if ~isempty(thisBlockInportBlocks)
                    thisBlockInportBlocks = myOp.slx.general.parseBlock(thisBlockInportBlocks);
                end
                if ~isempty(thisBlockOutportBlocks)
                    thisBlockOutportBlocks = myOp.slx.general.parseBlock(thisBlockOutportBlocks);
                end
                if length(thisBlockInports) ~= length(thisBlockInportBlocks)
                    warning(append(thisBlock.Name, ': Inport数量不匹配'));
                    continue;
                end
                if length(thisBlockOutports) ~= length(thisBlockOutportBlocks)
                    warning(append(thisBlock.Name, ': Outport数量不匹配'));
                    continue;
                end
                thisBlockInLines = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Inport");
                thisBlockOutLines = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Outport");
                if isequal(portType, 'Inport') || isequal(portType, '')
                    for j = 1:length(thisBlockInports)
                        inportBlockName = thisBlockInportBlocks{j}.Name;
                        inportLineName = thisBlockInLines{j}.Name;
                        if ~isequal(inportLineName, '')
                            inportLineName = myOp.slx.line.normalizeName("name", inportLineName);
                        end
                        if ~strcmp(inportBlockName, inportLineName)
                            try
                                thisBlockInLines{j}.Name = inportBlockName;
                            catch
                            end
                        end
                    end
                end
                if isequal(portType, 'Outport') || isequal(portType, '')
                    for j = 1:length(thisBlockOutports)
                        outportBlockName = thisBlockOutportBlocks{j}.Name;
                        outportLineName = thisBlockOutLines{j}.Name;
                        if ~isequal(outportLineName, '')
                            outportLineName = myOp.slx.line.normalizeName("name", outportLineName);
                        end
                        if ~strcmp(outportBlockName, outportLineName)
                            try
                                thisBlockOutLines{j}.Name = outportBlockName;
                            catch
                            end
                        end
                    end
                end
            end
        end

        function portName_line2InOut(opts)

            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, {'Inport', 'Outport', ''})} = '';
            end
            block = opts.block;
            portType = opts.portType;
            block = myOp.slx.subSysBlock.checkBlock("block", block);

            subSysBlock = [];
            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.priTools.isSubsystem(thisBlock) || myOp.slx.matlabFunction.isMatlabFunction(thisBlock)
                    subSysBlock = [subSysBlock, thisBlock];
                end
            end

            for i = 1:length(subSysBlock)
                thisBlock = subSysBlock(i);
                thisBlockInports = myOp.slx.block.getBlockPort("block", thisBlock, "portType", "Inport");
                thisBlockOutports = myOp.slx.block.getBlockPort("block", thisBlock, "portType", "Outport");
                thisBlockInportBlocks = find_system(thisBlock.Handle, 'SearchDepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'BlockType', 'Inport');
                thisBlockOutportBlocks = find_system(thisBlock.Handle, 'SearchDepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'BlockType', 'Outport');
                if ~isempty(thisBlockInportBlocks)
                    thisBlockInportBlocks = myOp.slx.general.parseBlock(thisBlockInportBlocks);
                end
                if ~isempty(thisBlockOutportBlocks)
                    thisBlockOutportBlocks = myOp.slx.general.parseBlock(thisBlockOutportBlocks);
                end
                if length(thisBlockInports) ~= length(thisBlockInportBlocks)
                    warning(append(thisBlock.Name, ': Inport数量不匹配'));
                    continue;
                end
                if length(thisBlockOutports) ~= length(thisBlockOutportBlocks)
                    warning(append(thisBlock.Name, ': Outport数量不匹配'));
                    continue;
                end
                thisBlockInLines = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Inport");
                thisBlockOutLines = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Outport");
                if isequal(portType, 'Inport') || isequal(portType, '')
                    for j = 1:length(thisBlockInports)
                        inportBlockName = thisBlockInportBlocks{j}.Name;
                        inportLineName = myOp.slx.line.getPrpgtSigName("line", thisBlockInLines{j});
                        if ~isequal(inportLineName, '')
                            inportLineName = myOp.slx.line.normalizeName("name", inportLineName);
                        end
                        if ~strcmp(inportBlockName, inportLineName)
                            try
                                thisBlockInportBlocks{j}.Name = inportLineName;
                            catch
                            end
                        end
                    end
                end
                if isequal(portType, 'Outport') || isequal(portType, '')
                    for j = 1:length(thisBlockOutports)
                        outportBlockName = thisBlockOutportBlocks{j}.Name;
                        outportLineName = myOp.slx.line.getPrpgtSigName("line", thisBlockOutLines{j});
                        if ~isequal(outportLineName, '')
                            outportLineName = myOp.slx.line.normalizeName("name", outportLineName);
                        end
                        if ~strcmp(outportBlockName, outportLineName)
                            try
                                thisBlockOutportBlocks{j}.Name = outportLineName;
                            catch
                            end
                        end
                    end
                end
            end
        end

        function portName_simplify(opts)

            arguments
                opts.block = '';
            end
            block = opts.block;
            block = myOp.slx.subSysBlock.checkBlock(...
                'block', block ...
            );

            subSysBlock = block;

            for i = 1:length(subSysBlock)
                thisBlock = subSysBlock(i);
                portsBlock = myOp.slx.inOutPort.getAll("block", thisBlock);
                for j = 1:length(portsBlock)
                    thisPortBlock = portsBlock(j);
                    portName = thisPortBlock.Name;
                    simplePortName = myOp.slx.inOutPort.simplifyPortName(...
                        'portName', portName ...
                    );
                    if ~strcmp(portName, simplePortName)
                        try
                            thisPortBlock.Name = simplePortName;
                        catch
                        end
                    end
                end
            end
        end
    
        function blocks = checkBlock(opts)
        % CHECKBLOCK  检查并获取 subSystem 模块
            arguments
                opts.block = '';
                opts.subType {mustBeMember(opts.subType, {'', 'ForEach', 'ModelReference'})} = '';
            end
            blocks = myOp.slx.general.checkBlock(...
                opts.block  ...
            );
            tempBlocks = blocks;
            blocks = {};
            for i = 1:length(tempBlocks)
                thisBlock = tempBlocks{i};
                if ~myOp.slx.priTools.isSubsystem(thisBlock)
                    continue;
                end
                blocks{end+1} = thisBlock;
            end
            if isequal(opts.subType, 'ForEach')
                idx = false(length(blocks), 1);
                for i = 1:length(blocks)
                    thisBlock = blocks{i};
                    forEachBlocks = myOp.slx.general.find_system(...
                        thisBlock.Handle, ...
                        'searchDepth', 1, ...
                        'BlockType', 'ForEach' ...
                    );
                    if ~isempty(forEachBlocks)
                        idx(i) = true;
                    end
                end
                blocks = blocks(idx);
            end
            blocks = blocks(:);
        end

        function blocks = getAll(opts)
        % GETALL  获取所有 subSystem 模块
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
                opts.subType {mustBeMember(opts.subType, {'', 'ForEach', 'ModelReference'})} = '';
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
                thisBlocks = myOp.slx.subSysBlock.checkBlock(...
                    'block', thisBlocks, ...
                    'subType', opts.subType ...
                );
                blocks = [blocks; thisBlocks];
            end
            blocks = blocks(:);
        end

    end
end