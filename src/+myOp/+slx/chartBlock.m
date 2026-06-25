classdef chartBlock

    methods(Static)

        function isChart = isChart(block)
            block = myOp.slx.general.parseBlock(block);
            isChart = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                if isprop(thisBlock, "BlockType")
                    if strcmp(thisBlock.BlockType, 'SubSystem')
                        if strcmp(thisBlock.SFBlockType, 'Chart')
                            temp{i} = true;
                        end
                    end
                end
            end
            if all(cell2mat(temp))
                isChart = true;
            end
        end

        function blocks = checkBlock(opts)
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);
            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.chartBlock.isChart(thisBlock)
                    blocks{end+1} = thisBlock;
                end
            end
            blocks = blocks(:);
        end

        function blocks = getAll(opts)
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
                thisBlocks = myOp.slx.chartBlock.checkBlock(...
                    'block', thisBlocks ...
                );
                blocks = [blocks; thisBlocks];
            end
            blocks = blocks(:);
            
        end
        
    end
end