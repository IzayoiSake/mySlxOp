classdef inOutPort

    methods(Static)

        function blocks = checkBlock(opts)
        % CHECKBLOCK  检查并返回 Inport 和 Outport 模块
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Inport') || ...
                   strcmp(thisBlock.BlockType, 'Outport')
                    blocks{end+1} = thisBlock; %#ok<AGROW>
                end
            end
            blocks = blocks(:);
        end
    
        function blocks = getAll(opts)
        % GETALL  获取所有 Inport 和 Outport 模块
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisInOutPortBlocks = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
                    'Type', 'Block' ...
                );
                if isempty(thisInOutPortBlocks)
                    continue;
                end
                thisInOutPortBlocks = myOp.slx.inOutPort.checkBlock(...
                    'block', thisInOutPortBlocks ...
                );
                blocks = [blocks; thisInOutPortBlocks];
            end
            blocks = blocks(:);
        end
    
        function varargout = flushLineName(opts)
        % FLUSHLINENAME  刷新 Inport 和 Outport 模块的线名称
            arguments
                opts.block = '';
            end
            blocks = myOp.slx.inOutPort.checkBlock(...
                'block', opts.block ...
            );
            for i = 1:length(blocks)
                thisBlock = blocks{i};
                if strcmp(thisBlock.BlockType, 'Inport')
                    line = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Outport", "lineNum", 1);
                    line = line{1};
                    line.Name = thisBlock.Name;
                elseif strcmp(thisBlock.BlockType, 'Outport')
                    line = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Inport", "lineNum", 1);
                    line = line{1};
                    line.Name = thisBlock.Name;
                end
            end
        end
    
        function varargout = flushPortName(opts)
        % FLUSHPORTNAME  刷新 Inport 和 Outport 模块的端口名称
            arguments
                opts.block = '';
            end
            blocks = myOp.slx.inOutPort.checkBlock(...
                'block', opts.block ...
            );
            for i = 1:length(blocks)
                thisBlock = blocks{i};
                if strcmp(thisBlock.BlockType, 'Inport')
                    line = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Outport", "lineNum", 1);
                    line = line{1};
                    lineName = myOp.slx.line.getPrpgtSigName("line", line);
                    if isequal(lineName, "")
                        continue;
                    end
                    thisBlock.Name = lineName;
                elseif strcmp(thisBlock.BlockType, 'Outport')
                    line = myOp.slx.block.getBlockLine("block", thisBlock, "lineType", "Inport", "lineNum", 1);
                    line = line{1};
                    lineName = myOp.slx.line.getPrpgtSigName("line", line);
                    if isequal(lineName, "")
                        continue;
                    end
                    thisBlock.Name = lineName;
                end
            end
        end

        function varargout = simplifyPortName(opts)
        % SIMPLIFYPORTNAME  简化 Inport 和 Outport 模块的端口名称
            arguments
                opts.block = '';
            end
            block = myOp.slx.inOutPort.checkBlock(...
                'block', opts.block ...
            );
            newNames = strings(length(block), 1);
            for i = 1:length(block)
                thisBlock = block{i};
                portName = thisBlock.Name;
                % 查看端口名称是否标准命名 标准格式为(***_***_***)
                portName = string(portName);
                nameStruct = split(portName, "_");
                nameStruct = string(nameStruct);
                nameStruct = nameStruct(:);
                nameStruct = nameStruct(nameStruct ~= "");
                if length(nameStruct) >= 3
                    newName = join(nameStruct(3:end), "_");
                elseif length(nameStruct) == 2
                    newName = portName(2:end);
                else
                    newName = portName;
                end
                newName = string(newName);
                if nargout == 0
                    thisBlock.Name = newName;
                end
                newNames(i) = newName;
            end
            if nargout > 0
                varargout{1} = newNames;
            end
        end

    end
end