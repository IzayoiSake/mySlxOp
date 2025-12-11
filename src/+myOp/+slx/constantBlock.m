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
                thisConstantBlocks = find_system(...
                    thisBlock.Handle, ...
                    'LookUnderMasks', 'all', ...
                    'BlockType', 'Constant' ...
                );
                thisConstantBlocks = myOp.slx.general.parseBlock(thisConstantBlocks);
                constantBlocks = [constantBlocks; thisConstantBlocks];
            end

            for i = 1:length(constantBlocks)
                thisConstantBlock = constantBlocks{i};
                set_param(thisConstantBlock.Handle, 'Value', '0');
            end
        end
    
    end
end