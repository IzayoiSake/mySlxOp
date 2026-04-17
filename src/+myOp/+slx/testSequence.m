classdef testSequence

    methods(Static)

        function testSequence_addSymbolByLineName(opts)
        % TESTSEQUENCE_ADDSYMBOLBYLINENAME  根据连接线名称向 Test Sequence 模块添加符号
        %
        %   testSequence_addSymbolByLineName(opts) 会检查指定的 Test Sequence 模块，
        %   根据输入的连接线对象名称自动在模块中添加相应的符号。如果符号已存在，
        %   则不会重复添加。
        %
        %   输入参数 (opts 结构体):
        %       opts.block   - Test Sequence 模块句柄或路径 (字符串或 cell 数组)
        %       opts.line    - Simulink 连接线对象 (字符串或 cell 数组)
        %       opts.scope   - 符号作用域 (可选)，必须是以下之一：
        %                         'Input' | 'Output' | 'Local' | ...
        %                         'Constant' | 'Parameter' | 'Data Store Memory'
        %                      默认值为 'Input'。
        %
        %   示例:
        %       testSequence_addSymbolByLineName( ...
        %           block = gcb, ...
        %           line = get_param(gcl,'LineHandles'), ...
        %           scope = 'Input');
        %
        %   说明:
        %       - 如果指定的 block 不是 Test Sequence 模块，则跳过。
        %       - 如果 line 没有名称，则不会生成符号。
        %       - 使用 sltest.testsequence.addSymbol 添加新符号。

            arguments
                opts.block = '';
                opts.line = '';
                opts.scope {mustBeMember(opts.scope, ["Input";"Output";"Local";"Constant";"Parameter";"Data Store Memory"])} = "Input";
            end

            opts.scope = string(opts.scope);
            

            block = opts.block;
            line = opts.line;
            scope = opts.scope;
            
            block = myOp.slx.general.checkBlock(block);
            line = myOp.slx.general.checkLine(line);

            if isempty(block) || isempty(line)
                return;
            end

            line = myOp.slx.line.line_sortByPosition('line', line);
            lineNames = [];
            for i = 1:length(line)
                thisLine = line{i};
                thisLineName = get_param(thisLine.Handle, 'Name');
                thisLineName = string(thisLineName);
                if ~isempty(thisLineName)
                    lineNames = [lineNames; thisLineName];
                end
            end

            % 检查 block 是否为 TestSequence 模块
            symbolNames = lineNames;
            symbolNames = myOp.slx.line.normalizeName("name", symbolNames);
            for i = 1:length(block)
                thisBlock = block{i};
                isTestSequence = myOp.slx.priTools.isTestSequence(thisBlock);
                if ~isTestSequence
                    continue;
                end

                % 获取当前全部的 symbol 名称
                existingSymbols = sltest.testsequence.findSymbol(thisBlock.getFullName());
                existingSymbols = existingSymbols(:);
                for j = 1:length(symbolNames)
                    thisSymbolName = symbolNames{j};
                    % 检查 symbol 是否已存在
                    if ~isempty(existingSymbols)
                        if any(strcmp(string(existingSymbols), thisSymbolName))
                            continue;
                        end
                    end
                    % 添加 symbol
                    sltest.testsequence.addSymbol(thisBlock.getFullName(), thisSymbolName, 'Data', scope);
                end
            end
        end


        function testSequence_flushSymbolByLineName(opts)
        % TESTSEQUENCE_FLUSHSYMBOLBYLINENAME  根据连接线名称向 Test Sequence 模块刷新符号
        %
        %   testSequence_flushSymbolByLineName(opts) 会检查指定的 Test Sequence 模块，
        %   根据输入的连接线对象名称自动在模块中对应的端口刷新相应的符号。
        %
        %   输入参数 (opts 结构体):
        %       opts.block   - Test Sequence 模块句柄或路径 (字符串或 cell 数组)
        %       opts.line    - Simulink 连接线对象 (字符串或 cell 数组)
        %       opts.scope   - 符号作用域 (可选)，必须是以下之一：
        %                         'Input' | 'Output' | 'Local' | ...
        %                         'Constant' | 'Parameter' | 'Data Store Memory'
        %                      默认值为 'Input'。
        %
        %   示例:
        %       testSequence_flushSymbolByLineName( ...
        %           block = gcb, ...
        %           line = get_param(gcl,'LineHandles'), ...
        %           scope = 'Input');
        %
        %   说明:
        %       - 如果指定的 block 不是 Test Sequence 模块，则跳过。
        %       - 如果 line 没有名称，则不会生成符号。

            arguments
                opts.block = '';
                opts.line = '';
                opts.scope {mustBeMember(opts.scope, ["Input";"Output";"Local";"Constant";"Parameter";"Data Store Memory"])} = "Input";
            end

            opts.scope = string(opts.scope);
            ;

            block = opts.block;
            line = opts.line;
            scope = opts.scope;
            
            block = myOp.slx.general.checkBlock(block);
            line = myOp.slx.general.checkLine(line);

            if isempty(block) || isempty(line)
                return;
            end

            line = myOp.slx.line.line_sortByPosition('line', line);
            lineNames = [];
            for i = 1:length(line)
                thisLine = line{i};
                thisLineName = get_param(thisLine.Handle, 'Name');
                thisLineName = string(thisLineName);
                if ~isempty(thisLineName)
                    lineNames = [lineNames; thisLineName];
                end
            end

            % 检查 block 是否为 TestSequence 模块
            symbolNames = lineNames;
            symbolNames = myOp.slx.line.normalizeName("name", symbolNames);
            for i = 1:length(block)
                thisBlock = block{i};
                isTestSequence = myOp.slx.priTools.isTestSequence(thisBlock);
                if ~isTestSequence
                    continue;
                end

                % 获取当前全部的 symbol 名称
                existingSymbols = sltest.testsequence.findSymbol(thisBlock.getFullName());
                existingSymbols = existingSymbols(:);
                existingSymbols = cellfun(...
                    @(x) sltest.testsequence.readSymbol(thisBlock.getFullName(), x), existingSymbols, 'UniformOutput', false...
                );
                for j = 1:length(symbolNames)
                    thisSymbolName = symbolNames{j};
                    if length(existingSymbols) < j
                        sltest.testsequence.addSymbol(thisBlock.getFullName(), thisSymbolName, 'Data', scope);
                    else
                        thisExistingSymbol = existingSymbols{j};
                        % 修改 symbol 的名字
                        sltest.testsequence.editSymbol(...
                            thisBlock.getFullName(), thisExistingSymbol.Name, ...
                            'Name', thisSymbolName ...
                        );
                    end
                end
            end
        end


        function testSequence_setSymbolDataType(opts)
        % TESTSEQUENCE_SETSYMBOLDATATYPE  将 Test Sequence 模块中符号的数据类型设置为 "Inherit: Same as Simulink"
        %
        %   testSequence_setSymbolDataType(opts) 会检查指定的 Test Sequence 模块，
        %   将其中所有符号（Scope 为 "Input" 或 "Output"）的数据类型批量设置为
        %   "Inherit: Same as Simulink"。
        %
        %   输入参数 (opts 结构体):
        %       opts.block   - Test Sequence 模块句柄或路径 (字符串或 cell 数组)
        %
        %   示例:
        %       testSequence_setSymbolDataType(block = gcb);
        %
        %   说明:
        %       - 如果指定的 block 不是 Test Sequence 模块，则跳过。
        %       - 仅修改 Scope 为 "Input" 或 "Output" 的符号，其它符号不受影响。
        %       - 使用 sltest.testsequence.editSymbol 进行符号属性更新。

            arguments
                opts.block = '';
            end

            block = opts.block;
            block = myOp.slx.general.checkBlock();
    
            allSymbols.Path = {};
            allSymbols.Symbols = {};
            for i = 1:length(block)
                thisBlock = block{i};
                isTestSequence = myOp.slx.priTools.isTestSequence(thisBlock);
                if ~isTestSequence
                    continue;
                end
                try
                    Symbols = sltest.testsequence.findSymbol(thisBlock.getFullName());
                    Symbols = Symbols(:);
                    Path = repmat({thisBlock.getFullName()}, length(Symbols), 1);
                    allSymbols.Path = [allSymbols.Path; Path];
                    allSymbols.Symbols = [allSymbols.Symbols; Symbols];
                catch
                    continue;
                end
            end
            
            for i = 1:length(allSymbols.Path)
                Path = allSymbols.Path{i};
                Symbol = allSymbols.Symbols{i};
                % 将数据类型设置为 "Inherit" (如果 Scope 是 "Input" 或 "Output")
                symbolObj = sltest.testsequence.readSymbol(Path, Symbol);
                if (symbolObj.Scope == "Input" || symbolObj.Scope == "Output")
                    try
                        sltest.testsequence.editSymbol(Path, Symbol, "DataType", "Inherit: Same as Simulink");
                    catch
                    end
                end
            end
        end
    end
end