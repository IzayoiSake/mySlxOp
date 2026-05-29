classdef dataLogging

    methods(Static)


        function mi = getDataLoggingSet(opts)
        % 获取 系统 的 DataLoggingOverride 属性值
            arguments
                opts.block = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);
            % 如果为空, 获取当前系统顶层模型
            if isempty(block)
                sys = bdroot;
                block = myOp.slx.general.checkBlock(sys);
            end
            topModel = bdroot(block{1}.Handle);
            topModel = get_param(topModel, 'object');
            % 1. 获取顶层模型的日志覆盖总对象
            mi = get_param(topModel.Handle, 'DataLoggingOverride');
        end


        function logMode = getDataLoggingMode(opts)
        % 获取 系统 的 DataLoggingMode 属性值

            arguments
                opts.block = '';
            end
            mi = myOp.slx.sim.dataLogging.getDataLoggingSet(...
                'block', opts.block ...
            );

            logMode = mi.LoggingMode;

            % if isequal(logMode, 'LogAllAsSpecifiedInModel')
            % elseif isequal(logMode, 'OverrideSignals')
            % end
        end


        function signalLoggingInfo = getSignalLoggingInfo(opts)
        % 获取 系统 中所有信号的日志设置信息
            arguments
                opts.block = '';
                opts.line = '';
            end
            block = myOp.slx.general.checkBlock(opts.block);
            line = myOp.slx.general.checkLine(opts.line);

            loggedLines = myOp.slx.line.getAllLoggedLines(...
                'block', block, ...
                'line', line ...
            );

            signalLoggingInfo = cell(length(loggedLines), 1);
            for i = 1:length(loggedLines)
                thisLine = loggedLines{i};
                thisSrcBlock = myOp.slx.line.getLinkedBlock(...
                    'line', thisLine, ...
                    'type', 'src' ...
                );
                thisSrcBlock = thisSrcBlock{1};
                thisSrcPort = myOp.slx.line.getLinkedPort(...
                    'line', thisLine, ...
                    'type', 'src' ...
                );
                thisSrcPort = thisSrcPort{1};

                logInfo = Simulink.SimulationData.SignalLoggingInfo;
                logInfo.BlockPath = thisSrcBlock.getFullName();
                logInfo.PutputPortIndex = thisSrcPort.PortNumber;
                logInfo.LoggingInfo = Simulink.SimulationData.LoggingInfo;
                logInfo.PropagatedName = '';

                signalLoggingInfo = [signalLoggingInfo; logInfo];
            end

        end

    end
end