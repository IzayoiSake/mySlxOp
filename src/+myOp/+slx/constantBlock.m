classdef constantBlock

    methods(Static)

        function clearValue(opts)
        % CLEARVALUE  清除 Constant 模块的数值
        %   clearValue(OPTIONS) 遍历指定的 Simulink 模块句柄，
        %   将其中所有 Constant 模块的数值清除为字符串 '0'。
        %   输入参数 (OPTIONS 结构体)：
        %       block : char | cell | string
        %           待处理的模块路径或句柄。如果为空，则使用当前选择的模块。
        %
        %   输出参数：
        %       无（函数直接修改模型中 Constant 模块的数值）。

            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            constantBlocks = [];
            for i = 1:length(block)
                thisBlock = block{i};
                thisConstantBlocks = myOp.slx.constantBlock.getAll(...
                    'searchDepth', opts.searchDepth, ...
                    'block', thisBlock ...
                );
                constantBlocks = [constantBlocks; thisConstantBlocks];
            end

            for i = 1:length(constantBlocks)
                thisConstantBlock = constantBlocks{i};
                set_param(thisConstantBlock.Handle, 'Value', 'false');
                id = myOp.slx.block.getId("block", thisConstantBlock);
                msg = append("✅️ 已将 Constant 模块 '", myhiliteCmd(id, id), "' 的数值清除为 '0'。");
                disp(msg);
            end
        end
    
        function blocks = checkBlock(opts)
        % CHECKBLOCK  检查并返回 Constant 模块
            arguments
                opts.block = '';
            end

            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Constant')
                    blocks{end+1} = thisBlock; %#ok<AGROW>
                end
            end
            blocks = blocks(:);
        end
            
        function blocks = getAll(opts)
        % GETALL  获取所有 Constant 模块
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisConstBlocks = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
                    'SearchDepth', opts.searchDepth, ...
                    'Type', 'Block' ...
                );
                if isempty(thisConstBlocks)
                    continue;
                end
                thisConstBlocks = myOp.slx.constantBlock.checkBlock(...
                    'block', thisConstBlocks ...
                );
                blocks = [blocks; thisConstBlocks];
            end
            blocks = blocks(:);
        end
        
        function inheritSampleTime(opts)
        % INHERITSAMPLETIME  继承 Constant 模块的采样时间
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = myOp.slx.general.checkBlock(opts.block);

            constantBlocks = myOp.slx.constantBlock.getAll(...
                'searchDepth', opts.searchDepth, ...
                'block', block ...
            );
            blockIds = myOp.slx.block.getId(...
                'block', constantBlocks ...
            );
            for i = 1:length(constantBlocks)
                thisConstantBlock = constantBlocks{i};
                if ~isequal(get_param(thisConstantBlock.Handle, 'SampleTime'), '-1')
                    set_param(thisConstantBlock.Handle, 'SampleTime', '-1');
                    msg = append("✅️ 已将 Constant 模块 '", myhiliteCmd(blockIds{i}, blockIds{i}), "' 的采样时间设置为继承（-1）。");
                    disp(msg);
                end
            end
        end
    
        function varargout = setWH(opts)
        % SETWH  设置 Constant 模块的宽高
            arguments
                opts.block = '';
                opts.width = 180;
                opts.height = 24;
                opts.searchDepth = Inf;
            end
            blocks = myOp.slx.constantBlock.getAll(...
                'block', opts.block, ...
                'searchDepth', opts.searchDepth ...
            );

            blockIds = myOp.slx.block.getId(...
                'block', blocks ...
            );
            for i = 1:length(blocks)
                thisBlock = blocks{i};
                pos = get_param(thisBlock.Handle, 'Position');
                midX = (pos(1) + pos(3)) / 2;
                midY = (pos(2) + pos(4)) / 2;
                width = opts.width;
                height = opts.height;
                if width <= 0
                    width = pos(3) - pos(1);
                end
                if height <= 0
                    height = pos(4) - pos(2);
                end
                newPos = [midX - width/2, midY - height/2, midX + width/2, midY + height/2];
                set_param(thisBlock.Handle, 'Position', newPos);
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
                    pos = get_param(thisBlock.Handle, 'Position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    msg = append(idxString, ". ", string(type), "模块: ", cmd, " 已设置宽高为 ", num2str(width), " x ", num2str(height), "。");
                    disp(msg);
                end
            end
        end
        
    end
end