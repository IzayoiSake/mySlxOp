classdef inOutPort

    methods(Static)

        function varargout = checkBlock(opts)
        % CHECKBLOCK  检查并返回 Inport 和 Outport 模块
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            validBlocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Inport') || ...
                   strcmp(thisBlock.BlockType, 'Outport')
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
        % GETALL  获取所有 Inport 和 Outport 模块
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisInOutPortBlocks = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
                    'SearchDepth', opts.searchDepth, ...
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
                opts.searchDepth = Inf;
                opts.simplifyLevel = 1;
            end
            blocks = myOp.slx.inOutPort.getAll(...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
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
                simplyName = myOp.slx.inOutPort.simplifyPortName(...
                    'block', thisBlock, ...
                    'simplifyLevel', opts.simplifyLevel ...
                );
                thisBlock.Name = simplyName;
                id = myOp.slx.block.getId("block", thisBlock);
                cmd = myhiliteCmd(id, id);
                idxString = myhiliteCmd(id, string(i));
                type = get_param(thisBlock.Handle, 'BlockType');
                msg = append(idxString, ". ✅️ ", string(type), "模块: ", cmd, " 已刷新端口名称为 ", simplyName, "。");
                disp(msg);
            end
        end

        function varargout = simplifyPortName(opts)
        % SIMPLIFYPORTNAME  简化 Inport 和 Outport 模块的端口名称
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
                opts.simplifyLevel = 1;
            end
            block = myOp.slx.inOutPort.getAll(...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
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
                if (length(nameStruct) >= 3) && (opts.simplifyLevel == 1)
                    newName = join(nameStruct(2:end), "_");
                elseif (length(nameStruct) >= 2) && (opts.simplifyLevel == 2)
                    newName = join(nameStruct(3:end), "_");
                elseif (length(nameStruct) == 2) && (opts.simplifyLevel == 2)
                    newName = portName(2:end);
                else
                    newName = portName;
                end
                newName = string(newName);
                if nargout == 0
                    thisBlock.Name = newName;
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    numb = myhiliteCmd(id, string(i));
                    msg = append(numb, ". ✅️ ", string(thisBlock.BlockType), "模块: ", cmd, " 已简化端口名称为 ", newName, "。");
                    disp(msg);
                end
                newNames(i) = newName;
            end
            if nargout > 0
                varargout{1} = newNames;
            end
        end

        function varargout = setHeight(opts)
        % SETHEIGHT  设置 Inport 和 Outport 模块的高度
            arguments
                opts.block = '';
                opts.height {mustBeNumeric(opts.height)} = 14;
            end
            blocks = myOp.slx.inOutPort.checkBlock(...
                'block', opts.block ...
            );
            for i = 1:length(blocks)
                thisBlock = blocks{i};
                pos = thisBlock.Position;
                mid = ( pos(4) + pos(2) ) / 2;
                thisBlock.Position = [pos(1), mid - opts.height / 2, pos(3), mid + opts.height / 2];
            end
            if nargout == 1
                varargout{1} = blocks;
            else
                for i = 1:length(blocks)
                    thisBlock = blocks{i};
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    idxString = myhiliteCmd("idx", string(i));
                    type = get_param(thisBlock.Handle, 'BlockType');
                    msg = append(idxString, ". ", string(type), "模块: ", cmd, " 已设置高度为 ", num2str(opts.height), "。");
                    disp(msg);
                end
            end
        end

        function varargout = setWidth(opts)
        % SETWIDTH  设置 Inport 和 Outport 模块的宽度
            arguments
                opts.block = '';
                opts.width {mustBeNumeric(opts.width)} = 30;
            end
            blocks = myOp.slx.inOutPort.checkBlock(...
                'block', opts.block ...
            );
            for i = 1:length(blocks)
                thisBlock = blocks{i};
                pos = thisBlock.Position;
                mid = ( pos(3) + pos(1) ) / 2;
                thisBlock.Position = [mid - opts.width / 2, pos(2), mid + opts.width / 2, pos(4)];
            end
            if nargout == 1
                varargout{1} = blocks;
            else
                for i = 1:length(blocks)
                    thisBlock = blocks{i};
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    idxString = myhiliteCmd("idx", string(i));
                    type = get_param(thisBlock.Handle, 'BlockType');
                    msg = append(idxString, ". ", string(type), "模块: ", cmd, " 已设置宽度为 ", num2str(opts.width), "。");
                    disp(msg);
                end
            end
        end

        function varargout = setWH(opts)
        % SETWH  设置 Inport 和 Outport 模块的宽高
            arguments
                opts.block = '';
                opts.width {mustBeNumeric(opts.width)} = 30;
                opts.height {mustBeNumeric(opts.height)} = 14;
                opts.searchDepth = Inf;
            end
            blocks = myOp.slx.inOutPort.getAll(...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );
            for i = 1:length(blocks)
                thisBlock = blocks{i};
                pos = thisBlock.Position;
                midX = ( pos(3) + pos(1) ) / 2;
                midY = ( pos(4) + pos(2) ) / 2;
                thisBlock.Position = [midX - opts.width / 2, midY - opts.height / 2, midX + opts.width / 2, midY + opts.height / 2];
            end
            if nargout == 1
                varargout{1} = blocks;
            else
                for i = 1:length(blocks)
                    thisBlock = blocks{i};
                    id = myOp.slx.block.getId("block", thisBlock);
                    cmd = myhiliteCmd(id, id);
                    idxString = myhiliteCmd("idx", string(i));
                    type = get_param(thisBlock.Handle, 'BlockType');
                    msg = append(idxString, ". ", string(type), "模块: ", cmd, " 已设置宽高为 ", num2str(opts.width), " x ", num2str(opts.height), "。");
                    disp(msg);
                end
            end
        end

    end
end