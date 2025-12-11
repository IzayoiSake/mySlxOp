classdef ctrlPar

    methods(Static)

        %% 控制参数的相关功能
        function [parNames, parValues] = getBlockPars(opts)

            arguments
                opts.block = '';
            end

            block = opts.block;

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
                if ismember(varType, ctrlParDataTypes)
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


    end
end