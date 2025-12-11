classdef general

    methods(Static)

        %% Simulink系统本身的基本操作
        function slRestart()
            % SLRESTART 重启 Simulink
            %
            %   SLRESTART() 关闭所有打开的 Simulink 模型并重新启动 Simulink。
            %
            %   示例：
            %       slRestart();
            %
            sl_refresh_customizations();
        end

        %% 当前系统的Object的基础功能
        function block = checkBlock(block)
            if ~exist('block', 'var')
                block = find_system(gcs, 'lookUnderMasks', 'all', 'SearchDepth', 1, 'Type', 'block', 'Selected', 'on');
                % 排除gcs自己
                block = block(~strcmp(block, gcs));
            end
            if isempty(block)
                block = find_system(gcs, 'lookUnderMasks', 'all', 'SearchDepth', 1, 'Type', 'block', 'Selected', 'on');
                % 排除gcs自己
                block = block(~strcmp(block, gcs));
            end
            if isempty(block)
                block = {};
                return;
            end
            block = myOp.slx.general.parseBlock(block);
        end

        function block = parseBlock(block)
            if isempty(block)
                error('parseBlock: Block is empty.');
            end
            if ~iscell(block)
                if ischar(block) && ~isstring(block)
                    block = {block};
                    block = block(:);
                else
                    block = block(:);
                    block = mat2cell(block, ones(1, numel(block)));
                end
            end
            for i = 1:length(block)
                try
                    block{i} = get_param(block{i}, 'Object');
                catch
                    block{i} = get_param(block{i}.Handle, 'Object');
                end
            end
        end

        function line = checkLine(line)
            if ~exist('line', 'var')
                line = find_system(gcs, 'lookUnderMasks', 'all', 'SearchDepth', 1, 'findAll', 'on', 'Type', 'line', 'Selected', 'on');
            end
            if isempty(line)
                line = find_system(gcs, 'lookUnderMasks', 'all', 'SearchDepth', 1, 'findAll', 'on', 'Type', 'line', 'Selected', 'on');
            end
            if isempty(line)
                line = {};
                return;
            end
            line = myOp.slx.general.parseLine(line);
        end

        function line = parseLine(line)
            if isempty(line)
                error('parseLine: Line is empty.');
            end
            if ~iscell(line)
                if ischar(line) && ~isstring(line)
                    line = {line};
                    line = line(:);
                else
                    line = line(:);
                    line = mat2cell(line, ones(1, numel(line)));
                end
            end
            for i = 1:length(line)
                try
                    line{i} = get_param(line{i}, 'Object');
                catch
                    line{i} = get_param(line{i}.Handle, 'Object');
                end
            end
        end

        function ports = getBlockPort(opts)

            arguments
                opts.block = '';
                opts.portType string {mustBeMember(opts.portType, ["inport", "outport", ""])} = "";
                opts.portNum double {mustBeInteger} = 0;
            end

            % 将opts.portType全转成小写
            opts.portType = lower(opts.portType);
            for i = 1:length(opts.portType)
                if strcmp(opts.portType(i), "input")
                    opts.portType(i) = "inport";
                elseif strcmp(opts.portType(i), "output")
                    opts.portType(i) = "outport";
                end
            end

            opts.block = myOp.slx.general.checkBlock(opts.block);
            if length(opts.block) ~= 1
                error('getBlockPort: Please specify exactly one block.');
            end
            if (length(opts.block) ~= length(opts.portType)) && (length(opts.portType) ~= 1)
                error('getBlockPort: The length of block and portType must be the same or portType must be a single value.');
            elseif (length(opts.block) ~= length(opts.portType)) && (length(opts.portType) == 1)
                opts.portType = repmat(opts.portType, length(opts.block), 1);
            end

            for i = 1:length(opts.block)
                thisBlock = opts.block{i};
                ph = get_param(thisBlock.Handle, 'PortHandles');

                if opts.portType(i) == ""   % 没指定 portType → 返回所有
                    ports{i} = [ph.Inport(:); ph.Outport(:)];

                elseif opts.portNum == 0   % 指定 portType 但没指定 portNum → 返回该类全部
                    switch opts.portType(i)
                        case "inport"
                            ports{i} = ph.Inport(:);
                        case "outport"
                            ports{i} = ph.Outport(:);
                    end

                else   % 指定 portType + portNum → 返回单个
                    switch opts.portType(i)
                        case "inport"
                            phs = ph.Inport;
                        case "outport"
                            phs = ph.Outport;
                    end

                    if opts.portNum > length(phs)
                        error('getBlockPort: %s only has %d ports, requested %d.', ...
                            opts.portType(i), length(phs), opts.portNum);
                    end
                    ports{i} = phs(opts.portNum);
                end
            end

            thePorts = [];
            for i = 1:length(ports)
                thisPorts = ports{i};
                for j = 1:length(thisPorts)
                    thePorts = [thePorts; myOp.slx.general.parseBlock(thisPorts(j))];
                end
            end
            thePorts = thePorts(:);
            ports = thePorts;
        end

        function ports = getLinePort(opts)

            arguments
                opts.line = '';
                opts.portType string {mustBeMember(opts.portType, ["srcPort", "dstPort", ""])} = "";
            end

            line = myOp.slx.general.checkLine(opts.line);
            if length(line) ~= 1
                error('getLinePort: Please specify exactly one line.');
            end

            if opts.portType == ""   % 没指定 portType → 返回所有
                ports = [line{1}.SrcPortHandle; line{1}.DstPortHandle];
            else   % 指定 portType
                switch opts.portType
                    case "srcPort"
                        ports = line{1}.SrcPortHandle;
                    case "dstPort"
                        ports = line{1}.DstPortHandle;
                end
            end
            ports = myOp.slx.general.parseBlock(ports);
        end
    
        function resolvedLines = getAllSig(opts)

            arguments
                opts.block = '';
                opts.line = '';
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            line = opts.line;
            line = myOp.slx.general.checkLine(line);

            % 获取 block 中的所有的 line
            allLines = [];
            for i = 1:length(block)
                thisBlock = block{i};
                thisLines = find_system(...
                    thisBlock.Handle, ...
                    'FindAll', 'on', ...
                    'LookUnderMasks', 'all', ...
                    'Type', 'line' ...
                );
                if isempty(thisLines)
                    continue;
                end
                thisLines = myOp.slx.general.parseLine(thisLines);
                allLines = [allLines; thisLines(:)];
            end
            % 从 allLines 中移除重复的 line
            allLines = unique(cell2mat(allLines));
            allLines = arrayfun(@(x) x, allLines, 'UniformOutput', false);

            allLines = [allLines; line];

            % 从 allLines 中移除不是 MustResolveToSignalObject 的 line
            resolvedLines = [];
            for i = 1:length(allLines)
                thisLine = allLines{i};
                if thisLine.MustResolveToSignalObject
                    resolvedLines = [resolvedLines; {thisLine}];
                end
            end

        end

        function lineNames = listAllSigName(opts)
            arguments
                opts.block = '';
                opts.line = '';
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            line = opts.line;
            line = myOp.slx.general.checkLine(line);

            resolvedLines = myOp.slx.general.getAllSig("block", block, "line", line);
            lineNames = [];
            for i = 1:length(resolvedLines)
                lineNames = [lineNames; string(resolvedLines{i}.Name)];
            end
        end
    
    
    end
end