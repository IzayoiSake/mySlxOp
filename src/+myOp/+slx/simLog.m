classdef simLog

    methods(Static)
        function allOut = logAll(opts)
            
            arguments
                opts.onlyRead = false;
            end

            onlyRead = opts.onlyRead;

            persistent allThing;

            if isempty(allThing)
                onlyRead = false;
            end

            if onlyRead
                allOut = allThing;
                return;
            end

            % 获取当前顶层模型
            topModelPath = bdroot;
            topModelPath = getfullname(topModelPath);

            % 获取当前模型的所有线
            allLines = find_system(topModelPath, 'FindAll', 'on', 'type', 'line');
            allLines = myOp.slx.general.checkLine(allLines);
            fullId = myOp.slx.line.getLineFullId('line', allLines);

            % 获取当前模型中的所有matlab function模块的端口信息
            matlabFunction.blocks = myOp.slx.matlabFunction.getAll("block", topModelPath);
            matlabFunctionPort.ports = myOp.slx.matlabFunction.getPortBlocks(...
                'block', matlabFunction.blocks ...
            );
            matlabFunctionPort.fullId = myOp.slx.matlabFunction.getPortId(...
                'ports', matlabFunctionPort.ports ...
            );

            % 创建仿真器
            % simModel = simulation(topModelPath);
            % 查看顶层模型是否已经被其他程序(函数)运行处于仿真状态
            isOtherSiming = true;
            simStatus = get_param(topModelPath, 'SimulationStatus');
            if strcmp(simStatus, 'stopped')
                isOtherSiming = false;
                warning('off', 'all');
                set_param(topModelPath, 'SimulationCommand', 'start');
                set_param(topModelPath, 'SimulationCommand', 'pause');
                warning('on', 'all');
            end

            % 获取线的数据类型和维度
            [lineDataType, lineDimensions] = myOp.slx.simLog.geLineMsg(allLines);
            allLine.dataType = lineDataType;
            allLine.dimensions = lineDimensions;
            allLine.fullId = fullId;

            if ~isOtherSiming
                % 关闭仿真器
                set_param(topModelPath, 'SimulationCommand', 'stop');
            end

            % 清除基础工作区中的变量"out"
            evalin('base', 'clear out');

            allThing.line = allLine;
            allOut = allThing;
        end
        
    end


    methods(Static, Access = private)

        function [lineDataType, lineDimensions] = geLineMsg(allLines)

            lineDataType = cell(length(allLines), 1);
            lineDimensions = cell(length(allLines), 1);

            for i = 1:length(allLines)
                thisLine = allLines{i};
                % 获取线的数据类型
                try
                    srcPort = thisLine.getSourcePort();

                    dataType = srcPort.CompiledPortDataType;
                    % 检查 dataType 是否是一个 Simulink.Bus类型
                    if (myOp.slx.priTools.isSimulinkBusType(dataType))
                        dataType = append("Bus:", dataType);
                    end
                    % 检查 dataType 是否是一个 枚举类型
                    if (myOp.slx.priTools.isSimulinkEnumType(dataType))
                        dataType = append("Enum:", dataType);
                    end
                    lineDataType{i} = dataType;
                catch
                    lineDataType{i} = '';
                end
                % 获取线的维度
                try
                    srcPort = thisLine.getSourcePort();
                    dimensions = srcPort.CompiledPortDimensions;
                    dimensions = dimensions(2:end);
                    lineDimensions{i} = dimensions;
                catch
                    lineDimensions{i} = [];
                end
            end
        end

    end




end