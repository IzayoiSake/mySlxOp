classdef subSysBlock

    methods(Static)

        function portName_inOut2Line(opts)

            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, {'Inport', 'Outport', ''})} = '';
            end
            block = opts.block;
            portType = opts.portType;
            block = myOp.slx.general.checkBlock(block);

            subSysBlcok = [];
            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.priTools.isSubsystem(thisBlock) || myOp.slx.priTools.isMatlabFunction(thisBlock)
                    subSysBlcok = [subSysBlcok, thisBlock];
                end
            end

            for i = 1:length(subSysBlcok)
                thisBlock = subSysBlcok(i);
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
                        outportName = thisBlockOutports{j}.Name;
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
            block = myOp.slx.general.checkBlock(block);

            subSysBlcok = [];
            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.priTools.isSubsystem(thisBlock) || myOp.slx.priTools.isMatlabFunction(thisBlock)
                    subSysBlcok = [subSysBlcok, thisBlock];
                end
            end

            for i = 1:length(subSysBlcok)
                thisBlock = subSysBlcok(i);
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
                                thisBlockInportBlocks{j}.Name = inportLineName;
                            catch
                            end
                        end
                    end
                end
                if isequal(portType, 'Outport') || isequal(portType, '')
                    for j = 1:length(thisBlockOutports)
                        outportName = thisBlockOutports{j}.Name;
                        outportBlockName = thisBlockOutportBlocks{j}.Name;
                        outportLineName = thisBlockOutLines{j}.Name;
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

    end
end