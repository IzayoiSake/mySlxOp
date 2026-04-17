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
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            constantBlocks = [];
            for i = 1:length(block)
                thisBlock = block{i};
                thisConstantBlocks = myOp.slx.constantBlock.getAll(...
                    'block', thisBlock ...
                );
                constantBlocks = [constantBlocks; thisConstantBlocks];
            end

            for i = 1:length(constantBlocks)
                thisConstantBlock = constantBlocks{i};
                set_param(thisConstantBlock.Handle, 'Value', 'false');
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
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisConstBlocks = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
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
            end
            block = myOp.slx.general.checkBlock(opts.block);

            constantBlocks = myOp.slx.constantBlock.getAll(...
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
    end
end