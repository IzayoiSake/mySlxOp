classdef priTools

    methods(Static)

        function [direction, portNum] = autoDetectDP(block)
            block = myOp.slx.general.parseBlock(block);
            if isempty(block)
                error('block must contain one element.');
            end
            if ~isscalar(block)
                error('block must contain exactly one element.');
            end

            direction = [];
            portNum = [];

            thisBlock = block{1};
            inports = get_param(thisBlock.Handle, 'PortHandles');
            inports = inports.Inport;
            inports = inports(:);
            outports = get_param(thisBlock.Handle, 'PortHandles');
            outports = outports.Outport;
            outports = outports(:);
            if ~iscell(inports)
                inports = mat2cell(inports, ones(1, numel(inports)));
            end
            if ~iscell(outports)
                outports = mat2cell(outports, ones(1, numel(outports)));
            end
            inports = inports(:);
            outports = outports(:);
            thisDirection = 'in';
            thisPortNum = 1;
            if isempty(inports) && isempty(outports)
                return;
            elseif isscalar(inports) && isscalar(outports)
                thisDirection = 'in';
                thisPortNum = 1;
            elseif isscalar(inports)
                thisDirection = 'in';
                thisPortNum = 1;
            elseif isscalar(outports)
                thisDirection = 'out';
                thisPortNum = 1;
            elseif isempty(inports)
                thisDirection = 'out';
                thisPortNum = 1:length(outports);
                thisPortNum = thisPortNum(:);
            elseif isempty(outports)
                thisDirection = 'in';
                thisPortNum = 1:length(inports);
                thisPortNum = thisPortNum(:);
            end
            direction = thisDirection;
            portNum = thisPortNum;
        end

        function isDirect = isDirectThroughBlock(block)
            block = myOp.slx.general.parseBlock(block);
            if ~isscalar(block)
                error('block must contain exactly one element.');
            end
            isDirect = cell(length(block), 1);
            for i = 1:length(isDirect)
                isDirect{i} = false;
            end
            if isempty(block)
                return;
            end
            for i = 1:length(block)
                thisBlock = block{i};
                inports = get_param(thisBlock.Handle, 'PortHandles');
                inports = inports.Inport;
                inports = inports(:);
                outports = get_param(thisBlock.Handle, 'PortHandles');
                outports = outports.Outport;
                outports = outports(:);
                if ~iscell(inports)
                    inports = mat2cell(inports, ones(1, numel(inports)));
                end
                if ~iscell(outports)
                    outports = mat2cell(outports, ones(1, numel(outports)));
                end
                inports = inports(:);
                outports = outports(:);
                if isempty(inports) && isscalar(outports)
                    isDirect{i} = true;
                elseif isempty(outports) && isscalar(inports)
                    isDirect{i} = true;
                elseif isscalar(inports) && isscalar(outports)
                    isDirect{i} = true;
                else
                    isDirect{i} = false;
                end
            end
            isDirect = cell2mat(isDirect);
        end
        
        function endBlock = traceBlock(varargin)
            p = inputParser;

            % 可选参数
            addParameter(p, 'block', '', @(x) ischar(x) || isstring(x) || iscell(x) || ishandle(x) || isobject(x));
            addParameter(p, 'direction', '', @(x) ischar(x) || isstring(x));
            addParameter(p, 'portNum', '', @(x) isnumeric(x));
            addParameter(p, 'endBlockType', '', @(x) ischar(x) || isstring(x));

            % 解析输入参数
            parse(p, varargin{:});

            % 获取参数值
            block = p.Results.block;
            direction = p.Results.direction;
            portNum = p.Results.portNum;
            endBlockType = p.Results.endBlockType;

            block = myOp.slx.general.checkBlock(block, true);
            if ~isscalar(block)
                error('block must contain exactly one element.');
            end
            if isempty(direction) || isempty(portNum)
                [direction, portNum] = myOp.slx.priTools.autoDetectDP(block);
            elseif isscalar(direction) && isscalar(portNum)
                direction = repmat(direction, length(block), 1);
                portNum = repmat(portNum, length(block), 1);
            end
            if isempty(endBlockType)
                endBlockType = "No";
            end

            block = block{1};


            endBlock = cell(0);
            endBlockTemp = block;
            endPortNumTemp = portNum;
            if ~iscell(endBlockTemp)
                endBlockTemp = {endBlockTemp};
            end
            if ~iscell(endPortNumTemp)
                endPortNumTemp = {endPortNumTemp};
            end
            while true
                tempBlock = endBlockTemp;
                tempPortNum = endPortNumTemp;
                endBlockTemp = cell(0);
                endPortNumTemp = cell(0);
                isEnd = false(length(tempBlock), 1);
                isEnd = mat2cell(isEnd, ones(1, numel(isEnd)));
                for i = 1:length(tempBlock)
                    thisBlock = tempBlock{i};
                    thisPortNum = tempPortNum{i};
                    if strcmp(thisBlock.BlockType, endBlockType) || ~myOp.slx.priTools.autoDetectDP(thisBlock)
                        isEnd{i} = true;
                        endBlockTemp = [endBlockTemp; {thisBlock}];
                        endPortNumTemp = [endPortNumTemp; {thisPortNum}];
                        continue;
                    end
                    if strcmp(direction, 'in')
                        [thisBlockTemp, thisPortNumTemp] = mySlxOp.getLastBlock('block', thisBlock, 'portNum', thisPortNum, 'lookUnderMask', true);
                    elseif strcmp(direction, 'out')
                        [thisBlockTemp, thisPortNumTemp] = mySlxOp.getNextBlock('block', thisBlock, 'portNum', thisPortNum, 'lookUnderMask', true);
                    else
                        error('Invalid direction.');
                    end
                    if isempty(thisBlockTemp)
                        isEnd{i} = true;
                        endBlockTemp = [endBlockTemp; {thisBlock}];
                        endPortNumTemp = [endPortNumTemp; {thisPortNum}];
                        continue;
                    else
                        endBlockTemp = [endBlockTemp; thisBlockTemp];
                        endPortNumTemp = [endPortNumTemp; thisPortNumTemp];
                    end
                end
                if all(cell2mat(isEnd))
                    break;
                end
            end
            endBlock = endBlockTemp;
        end

        function isMatlabFunction = isMatlabFunction(block)
            block = myOp.slx.general.parseBlock(block);
            isMatlabFunction = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'SubSystem')
                    if (strcmp(thisBlock.ErrorFcn, 'Stateflow.Translate.translate'))
                        temp{i} = true;
                    end
                end
            end
            if all(cell2mat(temp))
                isMatlabFunction = true;
            end
        end

        function isSubsystem = isSubsystem(block)
            block = myOp.slx.general.parseBlock(block);
            isSubsystem = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                if strcmp(thisBlock.BlockType, 'SubSystem') && ~myOp.slx.priTools.isMatlabFunction(thisBlock)
                    temp{i} = true;
                end
            end
            if all(cell2mat(temp))
                isSubsystem = true;
            end
        end

        function isTestSequence = isTestSequence(block)
            block = myOp.slx.general.parseBlock(block);
            isTestSequence = false;
            temp = mat2cell(false(length(block), 1), ones(1, numel(block)));
            for i = 1:length(block)
                thisBlock = block{i};
                try
                    sltest.testsequence.findSymbol(thisBlock.getFullName());
                    temp{i} = true;
                catch
                end
            end
            if all(cell2mat(temp))
                isTestSequence = true;
            end
        end

        function dataType = genDataTypeByVarName(varName)
            % 数据类型索引名
            dataTypeIndexName = {...
                "bo", ...
                "i", ...
                "u", ...
                "f", ...
                "st", ...
            };
            dataTypeIndexNameC = dataTypeIndexName;
            for i = 1:length(dataTypeIndexName)
                dataTypeIndexNameC{i} = append("c", dataTypeIndexName{i});
            end
            dataTypeIndexName = dataTypeIndexName(:);
            % 数据类型列表
            dataTypeList = {...
                'boolean', ...
                'int16', ...
                'uint16', ...
                'single', ...
                'uint16', ...
            };
            dataTypeList = dataTypeList(:);

            name = varName;
            dataType = '';

            if isempty(dataType)
                try
                    var = evalin('base', name);
                    dataType = var.DataType;
                catch
                end
            end

            if isempty(dataType)
                try
                    % 将 name 以 '_' 分割
                    nameSplit = split(name, '_');
                    % 取第三份
                    if length(nameSplit) < 3
                        parLastName = nameSplit{end};
                    else
                        parLastName = nameSplit{3};
                    end
                    % 如果 parLastName 以 dataTypeIndexName 中的任意一个开头(区分大小写), 则取出对应的数据类型
                    for i = 1:length(dataTypeIndexName)
                        if startsWith(parLastName, dataTypeIndexName{i})
                            dataType = dataTypeList{i};
                            break;
                        end
                        if startsWith(parLastName, dataTypeIndexNameC{i})
                            dataType = dataTypeList{i};
                            break;
                        end
                    end
                catch
                    % 如果 name 不符合规范, 则报错
                    errorMsg = append("变量名 <", name, "> 不规范, 请手动指定数据类型.");
                    error(errorMsg);
                end
            end
        end

        function isEnum = isSimulinkEnumType(dataTypeName)
            % 判断一个字符串是否为Simulink.IntEnumType的枚举类型
        
            try
                mc = meta.class.fromName(dataTypeName);
                if isempty(mc)
                    isEnum = false;
                    return;
                end
        
                % 检查是否继承自Simulink.IntEnumType
                isEnum = any(strcmp({mc.SuperclassList.Name}, 'Simulink.IntEnumType'));
            catch
                isEnum = false;
            end
        end
        
        function isBus = isSimulinkBusType(dataTypeName)
            % 判断一个字符串是否为Simulink.Bus类型
        
            try
                % 读取基础工作区的变量
                busObj = evalin('base', dataTypeName);
                % 检查是否是Simulink.Bus对象
                isBus = isa(busObj, 'Simulink.Bus');
            catch
                isBus = false;
            end
        end

        function data = readMyMdfData(filePath)

            persistent dataBuf;
            persistent lastFilePath;
        
            if isempty(dataBuf)
                dataBuf = [];
                lastFilePath = '';
            end
        
            % 检查文件名是否相同
            if strcmp(lastFilePath, filePath) && ~isempty(dataBuf)
                data = dataBuf;
                return;
            end
            data = mdfRead(filePath);
            lastFilePath = filePath;
            dataBuf = data;
        end

    end
end