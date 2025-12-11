classdef busBlock

    methods(Static)

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
                    thisDataType = myOp.slx.line.line_getLineDataType("line", lines);
                    dataType = [dataType; thisDataType];
                end
                % 如果是 Bus Creator
                if strcmp(thisBlock.BlockType, 'BusCreator')
                    lines = myOp.slx.block.getBlockLine(...
                        'block', thisBlock.Handle, ...
                        'lineType', 'Inport' ...
                    );
                    thisDataType = myOp.slx.line.line_getLineDataType("line", lines);
                    dataType = [dataType; thisDataType];
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
        
    end
end