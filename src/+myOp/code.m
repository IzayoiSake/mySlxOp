classdef code

    methods(Static)

        function funcBodies = extractFunctionBodies(thisCode)
            thisCode = string(thisCode);
            pattern = '(?:\n|\r|^)\s*function\s+';
            funcStarts = regexp(thisCode, pattern);
            numFuncs = length(funcStarts);
            funcBodies = cell(numFuncs, 1);
            for k = 1:numFuncs
                startIdx = funcStarts(k);
                if k < numFuncs
                    % 截取到下一个 function 关键字之前
                    endIdx = funcStarts(k+1) - 1;
                else
                    % 最后一个函数，截取到末尾
                    endIdx = strlength(thisCode);
                end
                funcBodies{k} = extractBetween(thisCode, startIdx, endIdx);
            end
        end
        
        function matches = extractFunctionSignatures(thisCode)
            funcs = myOp.code.extractFunctionBodies(thisCode);
            matches = struct('outputs', {}, 'name', {}, 'inputs', {});
            for k = 1:length(funcs)
                thisFunc = funcs{k};
                thisMatches = myOp.code.extractFunctionSignature(thisFunc);
                if ~isempty(thisMatches)
                    matches(end+1) = thisMatches; %#ok<AGROW>
                end
            end
            matches = matches(:);
        end
        


    end


    methods(Static, Access=private)

        % --- 辅助清洗工具 ---

        function list = cleanAndSplit(txt, delimiter)
            % 移除注释 % 及其后内容
            lines = strsplit(txt, {newline, char(13)});
            for i = 1:length(lines)
                if contains(lines{i}, '%')
                    tmp = strsplit(lines{i}, '%');
                    lines{i} = tmp{1};
                end
            end
            txt = strjoin(lines, ' ');
            % 移除 '...'
            txt = strrep(txt, '...', ' ');
            % 按逗号拆分并清理
            rawList = strsplit(txt, delimiter);
            list = strtrim(rawList(:));
            list(cellfun(@isempty, list)) = [];
        end

        function txt = simpleClean(txt)
            % 简单的预处理：去掉换行和 '...'
            txt = strrep(txt, '...', ' ');
            txt = strrep(txt, newline, ' ');
            txt = strrep(txt, char(13), ' ');
            txt = strtrim(txt);
        end

        function txt = preprocessText(txt)
            % 内部辅助工具：清洗函数头中的杂质
            % a. 去掉 '...' 及其后的内容（换行补丁）
            txt = regexprep(txt, '\.\.\..*?(\n|\r)', ' ');
            % b. 去掉注释（% 及其后的所有内容）
            txt = regexprep(txt, '%.*', '');
            % c. 将所有换行符替换为空格
            txt = regexprep(txt, '[\r\n]', ' ');
            % d. 去掉多余空格
            txt = strtrim(txt);
        end

        function matches = extractFunctionSignature(thisCode)
            % 1. 确保输入是字符数组
            thisCode = char(thisCode);
            
            % 2. 使用 strfind 查找所有 "function" 字符串
            allIdx = strfind(thisCode, 'function');
            
            matches = struct('outputs', {}, 'name', {}, 'inputs', {});
            
            for k = 1:length(allIdx)
                startPos = allIdx(k);
                
                % 🔍 校验：确保这是真正的函数定义（前面只能是空格或换行）
                if startPos > 1
                    prefix = thisCode(max(1, startPos-10) : startPos-1);
                    % 如果关键字前面有非空白字符（且不是换行符），说明是在注释或字符串里
                    if ~all(isspace(prefix))
                        continue; 
                    end
                end

                % 📦 截取从 'function' 开始的一段足够长的区域进行解析
                % 我们假设函数头（含输入输出）不会超过 5000 字符
                searchArea = thisCode(startPos : min(startPos+5000, end));
                
                % 🎯 定位关键符号
                openParenIdx = strfind(searchArea, '(');
                closeParenIdx = strfind(searchArea, ')');
                
                if isempty(openParenIdx) || isempty(closeParenIdx), continue; end
                
                % ⛔ 核心修复：只取第一个括号对
                % 这样 trigger 后面紧跟的 ) 就是终点，后面的注释会被完全无视
                firstOpen = openParenIdx(1);
                firstClose = closeParenIdx(1);
                
                % 1️⃣ 提取输入部分 (Inputs)
                rawIn = searchArea(firstOpen+1 : firstClose-1);
                matches(k,1).inputs = myOp.code.cleanAndSplit(rawIn, ',');

                % 2️⃣ 提取名称和输出部分 (Name & Outputs)
                % 'function' 长度是 8
                rawHead = searchArea(9 : firstOpen-1);
                cleanHead = myOp.code.simpleClean(rawHead);
                
                equalIdx = strfind(cleanHead, '=');
                if ~isempty(equalIdx)
                    % 情况：[out1, out2] = funcName
                    outStr = cleanHead(1 : equalIdx(1)-1);
                    nameStr = cleanHead(equalIdx(1)+1 : end);
                    
                    % 清理方括号并拆分
                    outStr = strrep(strrep(outStr, '[', ''), ']', '');
                    matches(k,1).outputs = myOp.code.cleanAndSplit(outStr, ',');
                    matches(k,1).name = strtrim(nameStr);
                else
                    % 情况：funcName
                    matches(k,1).name = strtrim(cleanHead);
                    matches(k,1).outputs = {};
                end
            end
            
            % 移除因为校验失败产生的空行
            matches = matches(~cellfun(@isempty, {matches.name}));
            matches = matches(:);
        end


    end


end