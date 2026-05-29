classdef RateTransition

    methods(Static)

        function isOkArray = checkCompliance(opts)
        %==========================================================================
        % Function: checkCompliance
        %
        % 描述 (Description)
        % -------------------------------------------------------------------------
        % 该函数用于检查指定的 Simulink Block 是否为 Rate Transition Block，
        % 并验证其关键属性 "Integrity" 与 "Deterministic" 是否均为 'on'。
        % 若 block 不属于 Simulink.RateTransition 类型，则在命令行中输出可
        % 点击跳转的 Block 路径并报错；若为 RateTransition，但属性设置不
        % 正确，则返回对应的检查结果。
        %
        % 本函数常用于模型规范审查、建模风格检查或自动化模型验证场景。
        %
        %
        % 输入参数 (Inputs)
        % -------------------------------------------------------------------------
        %   opts.block
        %       指定需要检查的 Simulink Block，可以是：
        %           • Block 路径 (string / char)
        %           • Block 句柄
        %           • Block 对象
        %           • 以上类型的 cell 数组
        %
        %       本参数将通过 myOp.slx.general.checkBlock() 归一化为
        %       Block 对象列表（Simulink 对象），供内部逐一检查。
        %
        %
        % 输出参数 (Outputs)
        % -------------------------------------------------------------------------
        %   isOkArray
        %       logical 列向量，长度与输入 block 数量一致。
        %       对每个 block：
        %           • true  —— Integrity='on' 且 Deterministic='on'
        %           • false —— 属性设置不符合要求
        %
        %       若输入 block 中有非 RateTransition Block，则函数会直接报错，
        %       并不会产生对应元素。
        %
        %==========================================================================

            arguments
                opts.block = '';
            end

            block = opts.block;
            block = myOp.slx.RateTransition.checkBlock("block", block);

            isOkArray = true(length(block), 1);
            for i = 1:length(block)
                thisBlock = block{i};
                if isa(thisBlock, "Simulink.RateTransition")
                    integrity = thisBlock.Integrity;
                    deterministic = thisBlock.Deterministic;
                    isOk = true;
                    if ~isequal(integrity, 'on')
                        isOk = false;
                    end
                    if ~isequal(deterministic, 'on')
                        isOk = false;
                    end
                    isOkArray(i) = isOk;
                else
                    blockPath = thisBlock.getFullName();
                    link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, blockPath);
                    error('%s: 不是 Rate Transition Block', link);
                end
            end
        end

        function varargout = listNonCompliantBlocks(opts)
        %==========================================================================
        % Function: listNonCompliantBlocks
        %
        % 描述 (Description):
        %   本函数用于在指定模型/子系统范围内自动扫描所有 Rate Transition
        %   Block，并检查其“完整性(Integrity)”与“确定性(Deterministic)”
        %   等关键属性是否符合项目规范。  
        %   若发现不符合要求的 Rate Transition Block，会在命令行输出可点击
        %   跳转的链接，便于模型调试与整改。
        %
        %   扫描范围由 opts.block 指定，可输入：  
        %       • 模型名（如 'myModel'）  
        %       • 子系统路径（如 'myModel/Controller'）  
        %       • 或者句柄（会自动通过 myOp.slx.general.checkBlock 解析）
        %
        % 输入参数 (Input Arguments):
        %   opts.block  
        %       - 要扫描的模型或子系统，可为字符串或句柄。  
        %       - 默认值为 ''，表示使用当前模型。  
        %       - 最终会通过 myOp.slx.general.checkBlock 转换为标准块路径列表。
        %
        %
        % 输出参数 (Output Arguments):
        %   本函数无返回值。  
        %   扫描过程中若发现 Rate Transition Block 属性不符合规范，会在控制台
        %   输出如下信息（含可点击的高亮链接）：  
        %       "Rate Transition Block 完整性 属性不符合要求: <a ...>blockPath</a>"
        %
        %   若所有 Block 均符合要求，则不会输出任何提示。
        %
        %==========================================================================

            arguments
                opts.block = '';
                opts.return = false;
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            
            blocks = myOp.slx.RateTransition.getAll(...
                'block', block ...
            );
            isCompliant = myOp.slx.RateTransition.checkCompliance('block', blocks);
            nonCompliantIdx = find(~isCompliant);
            nonCompliantBlocks = blocks(nonCompliantIdx);
            if opts.return
                varargout{1} = nonCompliantBlocks;
            end
            for i = 1:length(nonCompliantBlocks)
                thisBlock = nonCompliantBlocks{i};
                blockPath = thisBlock.getFullName();
                link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, blockPath);
                head = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, string(i));
                fprintf('%s : 🛑 完整性 属性不符合要求: %s\n', head, link);
            end
        end

        function is = isRateTransition(block)
        % ISRATETRANSITION  检查指定 Block 是否均为 Rate Transition Block

            arguments
                block
            end
            block = myOp.slx.general.parseBlock(block);

            is = all(arrayfun(@(x) isa(x{1}, 'Simulink.RateTransition'), block));
        end

        function blocks = checkBlock(opts)
        % CHECKBLOCK  识别所选模块中的 Rate Transition 模块
            arguments
                opts.block = '';
            end

            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                if myOp.slx.RateTransition.isRateTransition(thisBlock)
                    blocks{end+1} = thisBlock; %#ok<AGROW>
                end
            end
            blocks = blocks(:);
        end

        function blocks = getAll(opts)
        % GETALL  获取所有 Rate Transition 模块
            arguments
                opts.block = '';
                opts.searchDepth = Inf;
            end
            block = myOp.slx.general.checkBlock(opts.block);

            blocks = {};
            for i = 1:length(block)
                thisBlock = block{i};
                thisRtBlocks = myOp.slx.general.find_system(...
                    thisBlock.Handle, ...
                    'SearchDepth', opts.searchDepth, ...
                    'Type', 'Block' ...
                );
                if isempty(thisRtBlocks)
                    continue;
                end
                thisRtBlocks = myOp.slx.RateTransition.checkBlock(...
                    'block', thisRtBlocks ...
                );
                blocks = [blocks; thisRtBlocks];
            end
            blocks = blocks(:);
        end

        function comply(opts)
        %==========================================================================
        % Function: comply
        %
        % 描述 (Description):
        %   该函数用于将指定的 Rate Transition Block
        %   强制设置为合规状态。具体操作为设置：
        %   "Integrity" = 'on'
        %   "Deterministic" = 'on'
        %
        % 输入参数 (Inputs):
        %   opts.block
        %       需要进行合规化处理的范围（模型、具体 Block）。
        %==========================================================================
            arguments
                opts.block = '';
            end

            % 获取范围内所有的 Rate Transition 模块
            rtBlocks = myOp.slx.RateTransition.getAll(...
                'block', opts.block ...
            );

            for i = 1:length(rtBlocks)
                thisRt = rtBlocks{i};
                isComplaint = myOp.slx.RateTransition.checkCompliance(...
                    'block', thisRt ...
                );
                if ~isComplaint
                    set_param(thisRt.Handle, 'Integrity', 'on');
                    set_param(thisRt.Handle, 'Deterministic', 'on');
                    % 显示提示
                    blockPath = fullfile(thisRt.Path, thisRt.Name);
                    link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, blockPath);
                    header = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, string(i));
                    fprintf('%s : 已设置 %s 为合规状态。\n', header, link);
                else
                    % 已合规，无需处理
                    % 显示提示
                    blockPath = fullfile(thisRt.Path, thisRt.Name);
                    link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, blockPath);
                    header = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, string(i));
                    fprintf('%s : %s 已为合规状态，无需处理。\n', header, link);
                end
            end
        end

        function clearInitCond(opts)
        % CLEARINITCOND  清除 Rate Transition Block 的初始条件
            arguments
                opts.block = '';
            end

            % 获取范围内所有的 Rate Transition 模块
            rtBlocks = myOp.slx.RateTransition.checkBlock(...
                'block', opts.block ...
            );

            count = 1;
            for i = 1:length(rtBlocks)
                thisRt = rtBlocks{i};
                
                if ~isequal(thisRt.InitialCondition, '0')
                    set_param(thisRt.Handle, 'InitialCondition', '0');
                    % 显示提示
                    blockPath = fullfile(thisRt.Path, thisRt.Name);
                    link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, blockPath);
                    header = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, string(count));
                    fprintf('%s : 已清除 %s 的初始条件。\n', header, link);
                    count = count + 1;
                end
            end
        end

    end
end