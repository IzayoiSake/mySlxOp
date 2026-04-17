classdef dataProcess

    methods(Static, Access=public)

        function timeDiff = calculateTimeDelay(data1, data2, opts)
            % calculateTimeDelay - 自动计算 data1 和 data2 数据的时间差 (基于互相关分析)
            % 
            % 输入:
            %   data1 : 第一个数据集的 timetable 数据 (作为对齐基准)
            %   data2 : 第二个数据集的 timetable 数据
            %   opts.Ts       : 重采样步长(秒)。默认为 0 (自动计算)。
            %   opts.ZeroTime : 是否强制将时间轴归零(逻辑值)。
            %                   - 如果两份数据是相对时间(各自按启动键计时)，设为 true。
            %                   - 如果是绝对时间(如北京时间)，设为 false。
            % 输出:
            %   timeDiff : 修正补偿值(秒)。直接执行 data2.Time = data2.Time + seconds(timeDiff) 即可对齐。

            arguments
                data1 timetable
                data2 timetable
                opts.Ts (1,1) {mustBeNonnegative} = 0;
                opts.ZeroTime (1,1) logical = true;
            end

            % 1. 设定重采样步长
            if isequal(opts.Ts, 0)
                dt1 = median(diff(data1.Time));
                dt2 = median(diff(data2.Time));
                opts.Ts = min(seconds(dt1), seconds(dt2));
            end
            dt_sec = opts.Ts;
            dt = seconds(dt_sec);
            
            data1Var = data1.Properties.VariableNames{1};
            data2Var = data2.Properties.VariableNames{1};

            % 2. 统一采样率
            data1_sync = retime(data1, 'regular', 'linear', 'TimeStep', dt);
            data2_sync = retime(data2, 'regular', 'linear', 'TimeStep', dt);

            % 3. 🌟 可选操作：时间轴归零
            deltaTimeStart = seconds(0); % 默认偏差为0
            if opts.ZeroTime
                deltaTimeStart = data2_sync.Time(1) - data1_sync.Time(1);
                data1_sync.Time = data1_sync.Time - data1_sync.Time(1);
                data2_sync.Time = data2_sync.Time - data2_sync.Time(1);
            end

            % 4. 寻找时间轴的绝对交集
            startTime = max(data1_sync.Time(1), data2_sync.Time(1));
            endTime = min(data1_sync.Time(end), data2_sync.Time(end));
            
            if startTime >= endTime
                error("计算失败：重采样后时间轴完全没有重叠部分！");
            end
            
            timerange_overlap = timerange(startTime, endTime);

            % 5. 提取交集内的数据
            sig_data1 = data1_sync(timerange_overlap, :).(data1Var);
            sig_data2 = data2_sync(timerange_overlap, :).(data2Var);

            % 6. 数据预处理（去直流偏置，🔥完美兼容多维矩阵）
            % 使用 fillmissing 安全填充，mean(..., 1) 确保总是按列求均值
            mean_data1 = mean(sig_data1, 1, 'omitnan');
            mean_data2 = mean(sig_data2, 1, 'omitnan');
            
            sig_data1 = fillmissing(sig_data1, 'constant', mean_data1);
            sig_data2 = fillmissing(sig_data2, 'constant', mean_data2);
            
            % 减去均值去直流偏置 (MATLAB 支持矩阵减去行向量的隐式扩展)
            sig_data1_ac = sig_data1 - mean_data1;
            sig_data2_ac = sig_data2 - mean_data2;

            % 7. 自动寻找延迟
            % 保持你的原始顺序：计算 data1 相对于 data2 的延迟
            % 如果是多维数据，finddelay 会返回一个数组。我们取所有通道的中位数作为全局延迟。
            delays = finddelay(sig_data2_ac, sig_data1_ac);
            delay_samples = round(median(delays));

            % 8. 换算为秒，并进行初始偏差补偿
            timeDiff = delay_samples * dt_sec;
            
            if opts.ZeroTime
                % 如果做了归零，必须扣除最初的起始偏差
                timeDiff = timeDiff - seconds(deltaTimeStart);
            end
        end

        function data2Synced = syncTbTime(data1, data2, opts)
            % syncTbTime - 将 data2 的时间轴调整，使其与 data1 完美对齐

            arguments
                data1 timetable
                data2 timetable
                opts.ZeroTime (1,1) logical = true;
                opts.timeDiff (1,1) double = NaN; % 如果已经预先计算好了时间差，可以直接传入，避免重复计算
            end
            timeDiff = opts.timeDiff;
            
            if isnan(timeDiff)
                % 提取第一个变量的第一列作为对齐计算的特征代表
                data1_1_Name = data1.Properties.VariableNames{1};
                data1_1_Data = data1.(data1_1_Name);
                data1_1_Data = data1_1_Data(:, 1); 
                data1_1 = timetable(data1.Time, data1_1_Data);
                data1_1.Properties.DimensionNames{1} = 'Time';
                
                data2_1_Name = data2.Properties.VariableNames{1};
                data2_1_Data = data2.(data2_1_Name);
                data2_1_Data = data2_1_Data(:, 1);
                data2_1 = timetable(data2.Time, data2_1_Data);
                data2_1.Properties.DimensionNames{1} = 'Time';
                
                timeDiff = myOp.dataProcess.calculateTimeDelay(data1_1, data2_1, "ZeroTime", opts.ZeroTime);
            end
            
            data2Synced = data2;
            
            % 1. 施加时间平移
            data2Synced.Time = data2Synced.Time + seconds(timeDiff);
            
            % ==================== 补全的重采样与边界钳位逻辑 ====================
            
            % 2. 记录平移后、重采样前，真实数据的起止时间
            origStartTime = data2Synced.Time(1);
            origEndTime   = data2Synced.Time(end);
            
            % 提取所有的变量名 (支持表内有多个不同测点的数据)
            varNames = data2Synced.Properties.VariableNames;
            
            % 预先保存每个变量的 第一个 和 最后一个 有效值
            % 🌟 使用动态结构体保存，支持多维。例如 100x3 的矩阵，取出来就是 1x3 的行向量
            firstValid = struct();
            lastValid = struct();
            for i = 1:length(varNames)
                vName = varNames{i};
                firstValid.(vName) = data2Synced.(vName)(1, :);
                lastValid.(vName)  = data2Synced.(vName)(end, :);
            end
            
            % 3. 核心：重映射到 data1 的绝对时间轴
            % 此时边界处会发生乱飞的外推
            data2Synced = retime(data2Synced, data1.Time, 'linear');
            
            % 提前计算逻辑掩码 (找准哪些时间点属于“外推垃圾区”)
            maskBefore = data2Synced.Time < origStartTime;
            maskAfter  = data2Synced.Time > origEndTime;
            
            % 4. 边界强制钳位：遍历所有变量进行覆盖
            for i = 1:length(varNames)
                vName = varNames{i};
                
                % 将早于真实起始时间的外推垃圾数据，强行覆盖为第一个有效值
                % 🌟 (maskBefore, :) 确保同时覆盖该变量的所有维度列
                if any(maskBefore)
                    data2Synced.(vName)(maskBefore, :) = firstValid.(vName);
                end
                
                % 将晚于真实结束时间的外推垃圾数据，强行覆盖为最后一个有效温度
                if any(maskAfter)
                    data2Synced.(vName)(maskAfter, :) = lastValid.(vName);
                end
            end
            
            % 5. 兜底处理 (极其安全的工程习惯)
            % 防止原始数据中间本身就有 NaN 断层，用最近邻补齐
            data2Synced = fillmissing(data2Synced, 'nearest');
        end
    
    end
end