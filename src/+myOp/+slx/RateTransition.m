classdef RateTransition

    methods(Static)

        function isOkArray = check(opts)
        %==========================================================================
        % Function: check
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
            block = myOp.slx.general.checkBlock(block);

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
                    blockPath = fullfile(thisBlock.Path, thisBlock.Name);
                    link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', blockPath, blockPath);
                    error('%s: 不是 Rate Transition Block', link);
                end
            end
        end

        function listDisintgtyBlocks(opts)
        %==========================================================================
        % Function: listDisintgtyBlocks
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
            end
            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            
            allBlocks = [];
            for i = 1:length(block)
                thisBlock = block{i};
                thisRtBlocks = find_system(thisBlock.Handle, 'lookUnderMasks', 'all', ...
                    'FollowLinks', 'on', ...
                    'BlockType', 'RateTransition');
                allBlocks = [allBlocks; thisRtBlocks(:)];
            end
            allBlocks = unique(allBlocks);

            allBlocks = myOp.slx.general.parseBlock(allBlocks);

            for i = 1:length(allBlocks)
                thisBlock = allBlocks{i};
                isOk = myOp.slx.RateTransition.check('block', thisBlock);
                if ~isOk
                    thisBlockPath = fullfile(thisBlock.Path, thisBlock.Name);
                    thisBlockPath = strrep(thisBlockPath, '\', '/');
                    thisBlockName = thisBlock.Name;
                    link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', thisBlockPath, thisBlockName);
                    fprintf('Rate Transition Block 完整性 属性不符合要求: %s\n', link);
                end
            end
        end

    end
end