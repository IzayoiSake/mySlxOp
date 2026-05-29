classdef switchBlock

    methods(Static)

        function blocks = getAll(opts)
        % GETALL  获取所有 switch 模块
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
                thisBlocks = myOp.slx.switchBlock.checkBlock(...
                    'block', thisBlocks ...
                );
                blocks = [blocks; thisBlocks];
            end
            blocks = blocks(:);
        end

        function blocks = checkBlock(opts)
        % CHECKBLOCK  检查并返回 Switch 模块
            arguments
                opts.block = '';
            end

            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Switch')
                    blocks{end+1} = thisBlock;
                end
            end
            blocks = blocks(:);
        end

    end
end