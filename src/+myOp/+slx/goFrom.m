classdef goFrom

    methods(Static)

        function goFromflushLineName(opts)
        % GOFROMFLUSHLINENAME  将 GoTo / From 模块的名字赋值给对应的信号线
        %
        %   goFromflushLineName(OPTIONS) 遍历指定的 Simulink 模块句柄，
        %   对于 GoTo 模块，将其 GotoTag 名称赋值给输入信号线；
        %   对于 From 模块，将其 GotoTag 名称赋值给输出信号线。
        %
        %   输入参数 (OPTIONS 结构体)：
        %       block : char | cell | string
        %           待处理的模块路径或句柄。如果为空，则使用当前选择的模块。
        %
        %   输出参数：
        %       无（函数直接修改模型中信号线的名称）。
        %
        %   示例：
        %       % 对当前选择的 GoTo / From 模块进行信号线重命名
        %       goFromflushLineName();
        %
        %       % 指定模块路径
        %       goFromflushLineName(struct('block', 'myModel/Goto1'));

            arguments
                opts.block = '';
            end

            block = opts.block;

            block = myOp.slx.general.checkBlock(block);

            if isempty(block)
                return;
            end

            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Goto')
                    % 获取Goto模块的名字
                    gotoName = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取Goto的输入端口
                    inports = get_param(thisBlock.Handle, 'PortHandles');
                    inports = inports.Inport;
                    inport = inports(1);
                    % 获取Goto的输入端口的连接线
                    line = get_param(inport, 'Line');
                    % 设置Line的名字为Goto模块的名字
                    set_param(line, 'Name', gotoName);
                end
                if strcmp(thisBlock.BlockType, 'From')
                    % 获取From模块的名字
                    fromName = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取From的输出端口
                    outports = get_param(thisBlock.Handle, 'PortHandles');
                    outports = outports.Outport;
                    outport = outports(1);
                    % 获取From的输出端口的连接线
                    line = get_param(outport, 'Line');
                    % 设置Line的名字为From模块的名字
                    set_param(line, 'Name', fromName);
                end
            end
        end

        function goFromLine2BlockTag(opts)
        % GOFROMLINE2BLOCKTAG  将信号线的名字赋值给对应的 GoTo / From 模块
        %
        %   goFromLine2BlockTag(OPTIONS) 遍历指定的 Simulink 模块句柄，
        %   对于 GoTo 模块，将其输入信号线的名称赋值给 GotoTag；
        %   对于 From 模块，将其输出信号线的名称赋值给 GotoTag。
        %
        %   输入参数 (OPTIONS 结构体)：
        %       block : char | cell | string
        %           待处理的模块路径或句柄。如果为空，则使用当前选择的模块。
        %
        %   输出参数：
        %       无（函数直接修改模型中模块的 GotoTag 属性）。
        %
        %   示例：
        %       % 对当前选择的 GoTo / From 模块进行信号线 → 模块名的重命名
        %       goFromLine2BlockTag();
        %
        %       % 指定模块路径
        %       goFromLine2BlockTag(struct('block', 'myModel/From1'));

            arguments
                opts.block = '';
                opts.changeMatched {mustBeNumericOrLogical(opts.changeMatched)} = true;
            end

            block = opts.block;
            block = myOp.slx.general.checkBlock(block);

            if isempty(block)
                return;
            end

            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Goto')
                    % 获取Goto模块的输入端口
                    inports = get_param(thisBlock.Handle, 'PortHandles');
                    inport = inports.Inport(1);
                    % 获取输入信号线的名字
                    line = get_param(inport, 'Line');
                    lineName = get_param(line, 'Name');
                    if isequal(lineName, "")
                        lineName = myOp.slx.line.getPrpgtSigName("line", line);
                    end
                    lineName = myOp.slx.line.normalizeName("name", lineName);
                    if ~isempty(lineName)
                        % 将线的名字赋值给GotoTag
                        if opts.changeMatched
                            matched = myOp.slx.goFrom.getMatched('block', thisBlock);
                            for j = 1:length(matched)
                                matchedBlock = matched{j};
                                % 同步更新对应的 From 模块的 GotoTag
                                set_param(matchedBlock.Handle, 'GotoTag', lineName);
                            end
                        end
                        set_param(thisBlock.Handle, 'GotoTag', lineName);
                    end
                end
                if strcmp(thisBlock.BlockType, 'From')
                    % 获取From模块的输出端口
                    outports = get_param(thisBlock.Handle, 'PortHandles');
                    outport = outports.Outport(1);
                    % 获取输出信号线的名字
                    line = get_param(outport, 'Line');
                    lineName = get_param(line, 'Name');
                    if isequal(lineName, "")
                        lineName = myOp.slx.line.getPrpgtSigName("line", line);
                    end
                    lineName = myOp.slx.line.normalizeName("name", lineName);
                    if ~isempty(lineName)
                        % 将线的名字赋值给GotoTag
                        if opts.changeMatched
                            matched = myOp.slx.goFrom.getMatched('block', thisBlock);
                            for j = 1:length(matched)
                                matchedBlock = matched{j};
                                % 同步更新对应的 Goto 模块的 GotoTag
                                set_param(matchedBlock.Handle, 'GotoTag', lineName);
                            end
                        end
                        set_param(thisBlock.Handle, 'GotoTag', lineName);
                    end
                end
            end
        end
    
        function createPair(opts)
        % CREATEPAIR  根据 GoTo / From 模块创建对应的配对模块
        %  createPair(OPTIONS) 遍历指定的 Simulink 模块句柄，
        %  对于 GoTo 模块，创建对应的 From 模块；
        %  对于 From 模块，创建对应的 GoTo 模块。
        %
        %  输入参数 (OPTIONS 结构体)：
        %      block : char | cell | string
        %          待处理的模块路径或句柄。如果为空，则使用当前选择的模块。
        %      direction : string
        %          指定创建的模块类型：
        %              "go2from" - 仅为 GoTo 模块创建 From 模块
        %              "from2go" - 仅为 From 模块创建 GoTo 模块
        %              "" (默认) - 为 GoTo 和 From 模块都创建对应的配对模块
        %
        %  输出参数：
        %      无（函数直接在模型中创建新的模块）。
        %  示例：
        %      % 对当前选择的 GoTo / From 模块创建配对模块
        %      myOp.slx.goFrom.createPair();
        %      % 指定模块路径，仅为 GoTo 模块创建 From 模块
        %      myOp.slx.goFrom.createPair(struct('block', 'myModel/Goto1', 'direction', 'go2from'));

            arguments
                opts.block = '';
                opts.direction {mustBeMember(opts.direction, {'go2from'; 'from2go'; ''})} = '';
            end

            block = myOp.slx.general.checkBlock(opts.block);

            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'Goto') && (isequal(opts.direction, 'go2from') || isequal(opts.direction, ''))
                    % 获取Goto模块的名字
                    gotoName = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取Goto模块所在系统
                    parentSys = get_param(thisBlock.Handle, 'Parent');
                    % 获取goto模块的位置
                    gotoPos = get_param(thisBlock.Handle, 'Position');
                    % 获取goto模块的大小 [长, 高]
                    gotoSize = [gotoPos(3) - gotoPos(1), gotoPos(4) - gotoPos(2)];
                    % 计算From模块的位置 (右移 一个身位+100)
                    fromPos = gotoPos + [gotoSize(1) + 100, 0, gotoSize(1) + 100, 0];
                    % 计算From模块的名字, 搜寻全部以 "From" 开头, 后跟纯数字的From模块
                    searchName = '^From\d*$';
                    allFrom = find_system(parentSys, 'searchdepth', 1, 'BlockType', 'From');
                    maxIndex = 0;
                    for j = 1:length(allFrom)
                        fromBlock = allFrom{j};
                        [~, fromBlockName, ~] = fileparts(fromBlock);
                        if ~isempty(regexp(fromBlockName, searchName, 'once'))
                            indexStr = extractAfter(fromBlockName, "From");
                            indexNum = str2double(indexStr);
                            if indexNum > maxIndex
                                maxIndex = indexNum;
                            end
                        end
                    end
                    newIndex = maxIndex + 1;
                    fromBlockName = strcat('From', num2str(newIndex));
                    % 创建From模块
                    fromBlockPath = strcat(parentSys, '/', fromBlockName);
                    add_block('simulink/Signal Routing/From', fromBlockPath, ...
                        'GotoTag', gotoName, ...
                        'Position', fromPos);
                end
                if strcmp(thisBlock.BlockType, 'From') && (isequal(opts.direction, 'from2go') || isequal(opts.direction, ''))
                    % 获取From模块的名字
                    fromName = get_param(thisBlock.Handle, 'GotoTag');
                    % 获取From模块所在系统
                    parentSys = get_param(thisBlock.Handle, 'Parent');
                    % 获取From模块的位置
                    fromPos = get_param(thisBlock.Handle, 'Position');
                    % 获取From模块的大小 [长, 高]
                    fromSize = [fromPos(3) - fromPos(1), fromPos(4) - fromPos(2)];
                    % 计算Goto模块的位置 (左移 一个身位+100)
                    gotoPos = fromPos - [fromSize(1) + 100, 0, fromSize(1) + 100, 0];
                    % 计算Goto模块的名字, 搜寻全部以 "Goto" 开头, 后跟纯数字的Goto模块
                    searchName = '^Goto\d*$';
                    allGoto = find_system(parentSys, 'searchdepth', 1, 'BlockType', 'Goto');
                    maxIndex = 0;
                    for j = 1:length(allGoto)
                        gotoBlock = allGoto{j};
                        [~, gotoBlockName, ~] = fileparts(gotoBlock);
                        if ~isempty(regexp(gotoBlockName, searchName, 'once'))
                            indexStr = extractAfter(gotoBlockName, "Goto");
                            indexNum = str2double(indexStr);
                            if indexNum > maxIndex
                                maxIndex = indexNum;
                            end
                        end
                    end
                    newIndex = maxIndex + 1;
                    gotoBlockName = strcat('Goto', num2str(newIndex));
                    % 创建Goto模块
                    gotoBlockPath = strcat(parentSys, '/', gotoBlockName);
                    add_block('simulink/Signal Routing/Goto', gotoBlockPath, ...
                        'GotoTag', fromName, ...
                        'Position', gotoPos);
                end
            end
        end

        function matched = getMatched(opts)
        % GETMATCHED  获取 GoTo / From 模块的配对模块
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);
            matched = {};
            if isempty(block)
                return;
            end
            if length(block) > 1
                msg = append("myOp.slx.goFrom.getMatched.MultipleBlocks", newline, ...
                    "⚠️当输入多个模块时，仅处理第一个模块。");
                warning(msg);
            end
            thisBlock = block{1};
            if strcmp(thisBlock.BlockType, 'Goto')
                % 获取Goto模块的名字
                gotoName = get_param(thisBlock.Handle, 'GotoTag');
                % 获取Goto模块所在系统
                parentSys = get_param(thisBlock.Handle, 'Parent');
                % 查找对应的From模块
                matchedFrom = find_system(parentSys, 'searchdepth', 1, 'BlockType', 'From', 'GotoTag', gotoName);
                if isempty(matchedFrom)
                    % disp("⚠️ 未找到对应的 From 模块。");
                    return;
                end
                % disp("✅ 找到对应的 From 模块：");
                matched = myOp.slx.general.parseBlock(matchedFrom);
            elseif strcmp(thisBlock.BlockType, 'From')
                % 获取From模块的名字
                fromName = get_param(thisBlock.Handle, 'GotoTag');
                % 获取From模块所在系统
                parentSys = get_param(thisBlock.Handle, 'Parent');
                % 查找对应的Goto模块
                matchedGoto = find_system(parentSys, 'searchdepth', 1, 'BlockType', 'Goto', 'GotoTag', fromName);
                if isempty(matchedGoto)
                    % disp("⚠️ 未找到对应的 Goto 模块。");
                    return;
                end
                % disp("✅ 找到对应的 Goto 模块：");
                matched = myOp.slx.general.parseBlock(matchedGoto);
            else
                
            end
        end

    end
end