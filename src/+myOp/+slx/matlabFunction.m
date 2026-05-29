classdef matlabFunction

    methods(Static)

        function isMatlabFunction = isMatlabFunction(block)
            block = myOp.slx.general.parseBlock(block);
            isMatlabFunction = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                if isprop(thisBlock, 'BlockType')
                    if strcmp(thisBlock.BlockType, 'SubSystem')
                        % if (strcmp(thisBlock.ErrorFcn, 'Stateflow.Translate.translate'))
                        %     chart = thisBlock.find('-isa', 'Stateflow.EMChart');
                        %     if ~isequal(chart, '')
                        %         temp{i} = true;
                        %     end
                        % end
                        if strcmp(thisBlock.SFBlockType, 'MATLAB Function')
                            temp{i} = true;
                        end
                    end
                end
            end
            if all(cell2mat(temp))
                isMatlabFunction = true;
            end
        end

        function ports = getPortBlocks(opts)

        % GETPORTS  获取 MATLAB Function 模块的端口信息
            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, ["Inport"; "Outport"; "All"])} = 'All'
            end
            block = myOp.slx.general.checkBlock(opts.block);

            mfBlocks = myOp.slx.matlabFunction.checkBlock(...
                'block', block ...
            );

            ports = [];
            for i = 1:length(mfBlocks)
                thisBlock = mfBlocks{i};
                chart = myOp.slx.matlabFunction.getChartBlocks(...
                    'block', thisBlock ...
                );
                chart = chart{1};
                inPorts = chart.Inputs;
                outPorts = chart.Outputs;

                % 从小到大排序
                [~, inOrder] = sort(arrayfun(@(x) str2double(x.Port), inPorts));
                inPorts = inPorts(inOrder);
                [~, outOrder] = sort(arrayfun(@(x) str2double(x.Port), outPorts));
                outPorts = outPorts(outOrder);

                switch opts.portType
                    case 'Inport'
                        thePorts = inPorts;
                    case 'Outport'
                        thePorts = outPorts;
                    case 'All'
                        thePorts = [inPorts; outPorts];
                end
                ports = [ports; thePorts];
            end
            ports = arrayfun(@(x) x, ports, 'UniformOutput', false);
        end
    
        function names = getPortBlocksName(opts)
        % GETPORTBLOCKSNAMES  获取 MATLAB Function 模块的端口名称
            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, ["Inport"; "Outport"; "All"])} = 'All'
            end
            ports = myOp.slx.matlabFunction.getPortBlocks(...
                'block', opts.block, ...
                'portType', opts.portType ...
            );

            names = cellfun(@(x) string(x.Name), ports, 'UniformOutput', false);
            names = names(:);
        end
    
        function listPortBlocksName(opts)
        % LISTPORTBLOCKSNAMES  列出 MATLAB Function 模块的端口名称
            arguments
                opts.block = '';
                opts.portType {mustBeMember(opts.portType, ["Inport"; "Outport"; "All"])} = 'All'
            end
            names = myOp.slx.matlabFunction.getPortBlocksName(...
                'block', opts.block, ...
                'portType', opts.portType ...
            );

            for i = 1:length(names)
                thisBlockName = names{i};
                disp(thisBlockName);
            end
        end

        function chartBlocks = getChartBlocks(opts)
        % GETCHARTBLOCKS  获取 MATLAB Function 模块中的 Stateflow Chart 模块
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            mfBlocks = myOp.slx.matlabFunction.checkBlock(...
                'block', block ...
            );

            chartBlocks = cell(length(mfBlocks), 1);
            for i = 1:length(mfBlocks)
                thisBlock = mfBlocks{i};
                % MATLAB Function block 是一个 Stateflow.EMChart
                thisBlock = get_param(thisBlock.Handle, 'Object');
                chart = thisBlock.find('-isa', 'Stateflow.EMChart');
                chartBlocks{i} = chart;
            end
        end

        function mfBlocks = checkBlock(opts)
        % CHECKBLOCK  识别所选模块中的 MATLAB Function 模块
            arguments
                opts.block = '';
            end

            block = myOp.slx.general.checkBlock(opts.block);

            mfBlocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.matlabFunction.isMatlabFunction(thisBlock)
                    mfBlocks{end+1} = thisBlock;
                end
            end
        end

        function mfBlocks = getAll(opts)
        % GETALL  获取所有 MATLAB Function 模块
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = myOp.slx.general.checkBlock(opts.block);

            mfBlocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisMfBlocks = find_system(...
                    thisBlock.Handle, ...
                    'SearchDepth', opts.searchDepth, ...
                    'LookUnderMasks', 'all', ...
                    'BlockType', 'subSystem' ...
                );
                if isempty(thisMfBlocks)
                    continue;
                end
                thisMfBlocks = myOp.slx.matlabFunction.checkBlock(...
                    'block', thisMfBlocks ...
                );
                mfBlocks = [mfBlocks; thisMfBlocks];
            end
            mfBlocks = mfBlocks(:);
        end

        function ids = getId(opts)
        % GETID  获取 MATLAB Function 模块的唯一标识符
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);

            mfBlocks = myOp.slx.matlabFunction.checkBlock(...
                'block', block ...
            );

            ids = cell(length(mfBlocks), 1);
            for i = 1:length(mfBlocks)
                thisBlock = mfBlocks{i};
                % 绝对路径
                path = thisBlock.Path;
                name = thisBlock.Name;
                id = append(path, '/', name);
                id = string(id);
                ids{i} = id;
            end
        end

        function ids = getPortId(opts)

            arguments
                opts.ports = '';
            end
            if isequal(opts.ports, "")
                ports = myOp.slx.matlabFunction.getPortBlocks();
            else
                ports = opts.ports;
            end
            ids = cell(length(ports), 1);
            if ~iscell(ports)
                ports = arrayfun(@(x) x, ports, 'UniformOutput', false);
            end
            for i = 1:length(ports)
                thisPort = ports{i};
                path = thisPort.Path;
                name = thisPort.Name;
                id = append(path, '/', name);
                id = string(id);
                ids{i} = id;
            end

        end

        function flexibilize(opts)
            arguments
                opts.block = '';
            end
            block = myOp.slx.matlabFunction.getAll(...
                'block', opts.block ...
            );
            for i = 1:length(block)
                thisBlock = block{i};
                thisBlockId = myOp.slx.matlabFunction.getId(...
                    'block', thisBlock ...
                );
                % 获取 MATLAB Function 模块中的 Stateflow Chart 模块
                chart = myOp.slx.matlabFunction.getChartBlocks(...
                    'block', thisBlock ...
                );
                chart = chart{1};
                % 将 全部端口 的数据类型设置为 Inherit: Same as Simulink, Size设置为 -1
                ports = [chart.Inputs; chart.Outputs];
                portIds = myOp.slx.matlabFunction.getPortId(...
                    'ports', ports ...
                );
                for j = 1:length(ports)
                    thisPort = ports(j);

                    msgNotice = "";
                    if ~isequal(thisPort.DataType, 'Inherit: Same as Simulink')
                        thisPort.DataType = 'Inherit: Same as Simulink';
                        msgNotice = append(msgNotice, "数据类型已设置为 Inherit: Same as Simulink；");
                    end
                    if ~isequal(thisPort.Props.Array.Size, '-1')
                        thisPort.Props.Array.Size = "-1";
                        msgNotice = append(msgNotice, "大小已设置为 -1；");
                    end
                    thisPortId = portIds{j};
                    if ~isequal(msgNotice, "")
                        msg = append("✅️ 已设置端口: ", myhiliteCmd(thisBlockId, thisPortId), " 为灵活端口: ", msgNotice);
                        disp(msg);
                    end
                end
            end
        end

    end
end