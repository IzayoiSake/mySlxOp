classdef ctrlPar

    methods(Static)

        %% 控制参数的相关功能
        function [parNames, parValues] = getBlockPars(opts)

            arguments
                opts.block = '';
                opts.mode {mustBeMember(opts.mode, ["all"; "CtPar"])} = "CtPar";
            end

            block = opts.block;
            mode = opts.mode;

            block = myOp.slx.general.checkBlock(block);

            % 控制参数的数据类型
            ctrlParDataTypes = {...
                'Simulink.Parameter', ...
                'Simulink.LookupTable', ...
            };
            ctrlParDataTypes = ctrlParDataTypes(:);
            
            % 从基础工作空间中获取所有的变量
            allVars = evalin('base', 'whos');

            % 筛选出所有的控制参数
            ctrlParNames = {};
            for i = 1:length(allVars)
                varName = allVars(i).name;
                varType = allVars(i).class;
                if isequal(mode, "CtPar")
                    if ismember(varType, ctrlParDataTypes)
                        ctrlParNames = [ctrlParNames; varName];
                    end
                elseif isequal(mode, "all")
                    ctrlParNames = [ctrlParNames; varName];
                end
                
            end

            % 在sysPath下查找所有 任意属性是ctrlParNames的block
            sysCtrlParNames = {};
            for i = 1:length(block)
                for j = 1:length(ctrlParNames)
                    searchBlocks = find_system(...
                        block{i}.Handle, ...
                        'FindAll', 'on', ...
                        'LookUnderMasks', 'all', ...
                        'RegExp', 'on', ...
                        'BlockDialogParams', append('.*', ctrlParNames{j}, '.*') ...
                    );
                    if ~isempty(searchBlocks)
                        sysCtrlParNames = [sysCtrlParNames; ctrlParNames{j}];
                    end
                end
            end
            sysCtrlParNames = unique(sysCtrlParNames);
            parNames = sysCtrlParNames;
            parNames = myOp.slx.ctrlPar.ctrlParSort(parNames);
            parValues = cell(length(parNames), 1);
            for i = 1:length(parNames)
                tempVar = evalin('base', parNames{i});
                try
                    parValues{i} = tempVar.Value;
                catch
                    try
                        parValues{i} = tempVar;
                    catch
                        parValues{i} = 'Error';
                    end
                end
            end
        end


        function varargout = extractBlockPars(opts)

            arguments
                opts.block = '';
            end

            block = opts.block;

            parNames = myOp.slx.ctrlPar.getBlockPars('block', block);
            for i = 1:length(parNames)
                varName = parNames{i};
                varValue = evalin('base', varName);
                pars.(varName) = varValue;
            end
            if nargout == 1
                varargout{1} = pars;
            else
                % 让用户选择要保存的mat文件路径
                [filename, pathname] = uiputfile('*.mat', '保存控制参数', 'ctrlPar.mat');
                if isequal(filename, 0) || isequal(pathname, 0)
                    disp('用户取消了保存');
                    return;
                end
                if exist(fullfile(pathname, filename), 'file') == 2
                    save(fullfile(pathname, filename), '-struct', 'pars', '-append');
                else
                    save(fullfile(pathname, filename), '-struct', 'pars');
                end
                
                disp(pars);
                disp(append("已将控制参数保存到 ", fullfile(pathname, filename)));
            end
        end


        function bws2mws(opts)
            % 将基础工作区中的控制参数复制到模型工作区中

            arguments
                opts.block = '';
            end

            block = opts.block;
            block = myOp.slx.general.checkBlock(block);
            if isempty(block)
                block = bdroot;
            end
            block = myOp.slx.general.checkBlock(block);
            [parNames, ~] = myOp.slx.ctrlPar.getBlockPars('block', block);

            mws = get_param(bdroot(block{1}.Handle), 'ModelWorkspace');

            for i = 1:length(parNames)
                parName = parNames{i};
                % 将基础工作区中的变量复制到模型工作区中
                val = evalin('base', parName);
                assignin(mws, parName, val);
                disp(append("已将变量 ", parName, " 从 基础工作区 复制到 模型工作区 "));
            end
        end


        function pars = ctrlParSort(pars)

            if ~iscell(pars)
                pars = {pars};
            end

            parsFirst = cell(length(pars), 1);
            parsSecond = cell(length(pars), 1);
            parsThird = cell(length(pars), 1);

            for i = 1:length(pars)
                par = pars{i};
                parSplit = split(par, '_');
                if length(parSplit) >= 3
                    parFirst = parSplit{1};
                    parSecond = parSplit{2};
                    parThird = parSplit{3};
                elseif length(parSplit) >= 2
                    parFirst = parSplit{1};
                    parSecond = parSplit{2};
                    parThird = '';
                elseif length(parSplit) >= 1
                    parFirst = parSplit{1};
                    parSecond = '';
                    parThird = '';
                end
                parsFirst{i} = parFirst;
                parsSecond{i} = parSecond;
                parsThird{i} = parThird;
            end

            % 先预处理 parsThird 中的数据
            for i = 1:length(parsThird)
                parThird = parsThird{i};
                
                % 如果 parThird 以字符 'c' 开头
                if ~startsWith(parThird, 'c')
                    continue;
                end
                % 如果 parThird 以以下字符串开头, 则去掉对应开头, 区分大小写
                head = {...
                    'cbo'; ...
                    'cf'; ...
                    'cu'; ...
                    'ci'; ...
                    'ca'; ...
                    'c'; ...
                };
                for j = 1:length(head)
                    if startsWith(parThird, head{j})
                        parThird = strrep(parThird, head{j}, '');
                        break;
                    end
                end
                parsThird{i} = parThird;
            end


            % 按照1,2,3的优先级排序, 1相同的情况下放在一起, 在1相同的情况下按照2排序, 2相同的情况下按照3排序
            [~, idx] = sortrows([parsFirst, parsSecond, parsThird]);

            pars = pars(idx);
        end


        function loadExcelPar(opts)
            
            arguments
                opts.filePaths = '';
                opts.headerNames = '';
            end

            filePaths = opts.filePaths;
            headerNames = opts.headerNames;

            if isempty(filePaths)
                % 等待用户选择文件, 可多选
                [filenames, pathnames] = uigetfile('*.xlsx', '选择Excel文件', 'MultiSelect', 'on');
                if isequal(filenames, 0)
                    disp('用户取消了选择');
                    return;
                end
                filenames = cellstr(filenames);
                filePaths = cell(length(filenames), 1);
                for i = 1:length(filenames)
                    filePaths{i} = fullfile(pathnames, filenames{i});
                end
            else
                if ischar(filePaths) || isstring(filePaths)
                    filePaths = {filePaths};
                end
                filenames = cell(length(filePaths), 1);
                for i = 1:length(filePaths)
                    [~, filenames{i}, ~] = fileparts(filePaths{i});
                end
            end
            if ~isempty(headerNames)
                if (ischar(headerNames) || isstring(headerNames))
                    headerNames = {headerNames};
                end
            end

            for i = 1:length(filePaths)
                % 读取Excel文件
                data = readcell(fullfile(filePaths{i}));
                % 去除前2列
                newdata = data(:, 3:end);
                % 获取newdata的Header
                disp("------------------------------------");
                header = newdata(1, :);
                for j = 1:length(header)
                    disp(header{j});
                end
                disp("------------------------------------");
                disp(append("本文件: ", filenames{i}, " ", "参数名如上."));
                if isempty(headerNames)
                    disp("请选择要导入的参数名");
                    % 等待用户输入参数名
                    selectedHeader = input('请输入参数名: ', 's');
                else
                    selectedHeader = headerNames{i};
                end
                if ~contains(header, selectedHeader)
                    disp(append("Error: ", filenames{i}, " 文件 ", selectedHeader, " 不存在."));
                    continue;
                else
                    disp(append("已选择参数: ", selectedHeader));
                end
                % 获取选择的参数列
                selectedData = newdata(2:end, find(contains(header, selectedHeader)));
                dataName = data(2:end, 2);

                for j = 1:length(dataName)
                    try
                        thisDataName = dataName{j};
                        % 如果thisDataName包含"BreakPoints"字符串
                        isBreakPoints = contains(thisDataName, "Breakpoints");
                        if (isBreakPoints)
                            thisDataName = strrep(thisDataName, "Breakpoints", "");
                        end

                        workSpaceVar = evalin('base', thisDataName);

                        evalFunc = append("[", string(selectedData{j}), "]");

                        % 同步数据维度
                        if (isprop(workSpaceVar, 'Breakpoints') && isBreakPoints)
                            dim = size(workSpaceVar.Breakpoints.Value);
                        elseif isprop(workSpaceVar, 'Table')
                            dim = size(workSpaceVar.Table.Value);
                        elseif isprop(workSpaceVar, 'Value') || isfield(workSpaceVar, 'Value')
                            dim = size(workSpaceVar.Value);
                        elseif isnumeric(workSpaceVar)
                            dim = size(workSpaceVar);
                        end
                        if (length(dim) >= 2)
                            % 如果维度大于2, 则将evalFunc转换为多维数组
                            evalFunc = append("reshape(", evalFunc, ", ", "[", num2str(dim), "]", ")");
                        end

                        % 同步数据类型
                        if (isprop(workSpaceVar, 'Breakpoints') && isBreakPoints)
                            dataType = workSpaceVar.Breakpoints.DataType;
                        elseif isprop(workSpaceVar, 'Table')
                            dataType = workSpaceVar.Table.DataType;
                        elseif isprop(workSpaceVar, 'Value') || isfield(workSpaceVar, 'Value')
                            dataType = workSpaceVar.DataType;
                        elseif isnumeric(workSpaceVar)
                            dataType = class(workSpaceVar);
                        end
                        evalFunc = append(dataType, "(", evalFunc, ")");

                        % 赋值
                        if (isprop(workSpaceVar, 'Breakpoints') && isBreakPoints)
                            workSpaceVar.Breakpoints.Value = eval(evalFunc);
                        elseif isprop(workSpaceVar, 'Table')
                            workSpaceVar.Table.Value = eval(evalFunc);
                        elseif isprop(workSpaceVar, 'Value') || isfield(workSpaceVar, 'Value')
                            workSpaceVar.Value = eval(evalFunc);
                        elseif isnumeric(workSpaceVar)
                            workSpaceVar = eval(evalFunc);
                        end
                        assignin('base', thisDataName, workSpaceVar);
                    catch
                        disp(append("Error: ", dataName{j}));
                        continue;
                    end
                end
            end
        end

        
    end
end