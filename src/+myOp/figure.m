classdef figure

    methods(Static)

        function betterFig(ax)
            if ~exist('ax', 'var') || isempty(ax)
                ax = gca;
            end
            % 设置图形属性
            % 设置坐标轴字体大小
            set(ax, 'FontSize', 18);
            % 设置坐标轴线宽
            set(ax, 'LineWidth', 1.5);
        
            % 全部曲线线宽设置为2
            h = findobj(ax, 'Type', 'line');
            set(h, 'LineWidth', 2);
        
            % 设置坐标轴标签字体大小
            set(get(ax, 'XLabel'), 'FontSize', 18);
            set(get(ax, 'YLabel'), 'FontSize', 18);
            % 设置标题字体大小
            set(get(ax, 'Title'), 'FontSize', 24);
            % 设置图例字体大小
            set(get(ax, 'Legend'), 'FontSize', 16);
            
            set(ax, 'Box', 'on'); % 显示边框
            grid(ax, 'on'); % 显示网格
            
            % 获取ax的所属tlo
            tlo = ancestor(ax, 'tiledchartlayout');
            if ~isempty(tlo)
                tlo.TileSpacing = 'compact';
                tlo.Padding = 'compact';
                % 设置标题字体大小
                set(get(tlo, 'Title'), 'FontSize', 24);
                % set(tlo, 'Grid', 'on'); % 显示网格
            end
            
            % 窗口最大化
            % set(gcf, 'WindowState', 'maximized');
        end


        function hilightPeakPoint(X, Y, color, exceptValue)
            % hilightPeakPoint 高亮显示峰值点
            % hilightPeakPoint(X, Y)
            % X: 时间序列
            % Y: 信号序列

            [~, locs] = findpeaks(Y);
            meanY = mean(abs(Y));
            if ~exist('color', 'var')
                color = 'r';
            end
            if ~exist('exceptValue', 'var')
                exceptValue = 0;
            end
            % 去除小于均值的点
            locs = locs(abs(Y(locs)) > max(meanY, exceptValue));
            hold on;
            % 高亮显示峰值点
            plot(X(locs), Y(locs), 'ro', 'MarkerSize', 10, 'LineWidth', 2, 'Color', color, 'HandleVisibility', 'off');
            % 显示峰值点的值(X和Y)
            for i = 1:length(locs)
                text(X(locs(i)), Y(locs(i)), num2str(Y(locs(i))), 'Color', color, 'FontSize', 12, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
            end
            hold off;
        end


        function tlo = tlo(f, gridRow, gridCol)
        % TLO - Auto-create or expand a tiledlayout while keeping old plots at same positions.
        %
        % Usage:
        %   tlo(f)                % create or return existing tiledlayout
        %   tlo(f, [r, c])        % set or expand layout to r×c
        %   tlo(f, r, c)          % same as above
        %
        % When expanding, preserves existing plots at their original row/col indices.
            if ~exist('gridRow', 'var')
                gridRow = [];
            end
            if ~exist('gridCol', 'var')
                gridCol = [];
            end

            if ~isempty(gridRow) && ~isempty(gridCol)
                if numel(gridRow) ~= 1 || numel(gridCol) ~= 1
                    error('gridSize输入方式错误');
                end
            elseif ~isempty(gridRow) && isempty(gridCol)
                if ~(numel(gridRow) == 1 || numel(gridRow) == 2)
                    error('gridSize输入方式错误');
                end
                if numel(gridRow) == 2
                    gridCol = gridRow(2);
                    gridRow = gridRow(1);
                else
                    gridCol = 1;
                end
            end
            
            tlo = get(f, 'Children');
            extendMethod = 'free'; % 'none', 'free'
            if isempty(tlo) || ~isa(tlo, 'matlab.graphics.layout.TiledChartLayout')
                if isempty(gridRow) && isempty(gridCol)
                    tlo = tiledlayout(f, 'flow');
                else
                    tlo = tiledlayout(f, gridRow, gridCol);
                end
            else
                cGridSize = tlo.GridSize;
                cGridRow = cGridSize(1);
                cGridCol = cGridSize(2);

                if isempty(gridRow) && isempty(gridCol)
                    tlo.TileSpacing = 'compact';
                    tlo.Padding = 'compact';
                    return;
                end

                if gridRow == cGridRow && gridCol == cGridCol
                    extendMethod = 'none';
                else
                    extendMethod = 'free';
                end
            end

            if strcmp(extendMethod, 'free')
                cAx = tlo.Children();
                cPositions = zeros(length(cAx), 2);
                % 获取每个子图在布局中的位置
                for i = 1:size(cAx, 1)
                    numb = cAx(i).Layout.Tile;
                    row = ceil(numb / cGridCol);
                    col = mod(numb - 1, cGridCol) + 1;
                    cPositions(i, :) = [row, col];
                end
                ax = copy(cAx);
                % 创建新的tiledlayout
                delete(tlo);
                tlo = tiledlayout(f, gridRow, gridCol);
                % 按位置还原子图
                for i = 1:length(ax)
                    try
                        % 如果新布局中位置超出范围, 则忽略该子图
                        if (cPositions(i,1) > gridRow || cPositions(i,2) > gridCol)
                            continue;
                        end
                        newPos = (cPositions(i, 1) - 1) * gridCol + cPositions(i, 2);
                        newAx = nexttile(tlo, newPos);
                        copyobj(allchild(ax(i)), newAx);
                        myOp.figure.copyAxesProperties(ax(i), newAx);
                    catch
                        % warning('子图位置超出新布局范围, 已删除该子图');
                    end
                end
                delete(ax);
            end
            tlo.TileSpacing = 'compact';
            tlo.Padding = 'compact';
        end


        function tlo = tiledlayout(f, gridRow, gridCol)
        % tiledlayout - Auto-create or expand a tiledlayout while keeping old plots at same positions.
        %
        % Usage:
        %   tiledlayout(f)                % create or return existing tiledlayout
        %   tiledlayout(f, [r, c])        % set or expand layout to r×c
        %   tiledlayout(f, r, c)          % same as above
        %
        % When expanding, preserves existing plots at their original row/col indices.
            
            if ~exist('gridRow', 'var')
                gridRow = [];
            end
            if ~exist('gridCol', 'var')
                gridCol = [];
            end
            tlo = myOp.figure.tlo(f, gridRow, gridCol);
        end


        function ax = nexttile(tlo, tilePos, span)
        % NEXTTILE - Get axes at specified tile position in a tiledlayout.
        %
        % Syntax:
        %   ax = nexttile(tlo)
        %   ax = nexttile(tlo, tilePos)
        %   ax = nexttile(tlo, tileRow, tileCol)
        %
        % Description:
        %   - nexttile(tlo)                : 返回下一个可用的 tile 对应的 axes
        %   - nexttile(tlo, tilePos)       : tilePos 为标量索引或 [row, col]
        %   - nexttile(tlo, tileRow, tileCol) : 按行列指定位置
        %
        %   该函数会内部调用 MATLAB 内置的 nexttile 来实际创建/获取 axes。

            % 获取 / 创建 tiledlayout

            if ~exist('tilePos', 'var')
                tilePos = [];
            end
            if ~exist('span', 'var')
                span = [];
            end

            if isempty(tilePos) && isempty(span)
                % 只有 tlo, 直接要“下一个 tile”
                ax = nexttile(tlo);
            elseif ~isempty(tilePos) && isempty(span)
                % 一个位置参数：既可以是标量索引，也可以是 [row col]
                if isscalar(tilePos)
                    idx = tilePos;
                elseif isnumeric(tilePos) && numel(tilePos) == 2
                    row = tilePos(1);
                    col = tilePos(2);
                    idx = (row - 1) * tlo.GridSize(2) + col;
                else
                    error('tilePos must be a scalar index or a [row col] vector.');
                end
                ax = nexttile(tlo, idx);
            else
                % 两个位置参数： tilePos 和 span
                if isscalar(tilePos)
                    idx = tilePos;
                elseif isnumeric(tilePos) && numel(tilePos) == 2
                    row = tilePos(1);
                    col = tilePos(2);
                    idx = (row - 1) * tlo.GridSize(2) + col;
                else
                    error('tilePos must be a scalar index or a [row col] vector.');
                end
                ax = nexttile(tlo, idx, span);
            end
        end


        function copyAxesProperties(src, dst)
        % COPYAXESPROPERTIES  Copy all visible and style properties from one axes to another.
        %
        %   copyAxesProperties(src, dst)
        %   Copies titles, labels, limits, grid, aspect ratios, color, fonts, view,
        %   and legend from source axes SRC to destination axes DST.
        %
        %   It preserves almost all user-visible settings so the new axes looks
        %   identical to the old one, except for container layout differences.
        %
        %   This helper is designed to be used when recreating tiled layouts
        %   (e.g., expanding figure grids).

            %----------------------------
            % 1️⃣ 复制标题和坐标轴标签
            %----------------------------
            labels = {'Title','XLabel','YLabel','ZLabel'};
            for i = 1:numel(labels)
                srcLabel = src.(labels{i});
                dstLabel = dst.(labels{i});
                dstLabel.String     = srcLabel.String;
                dstLabel.FontName   = srcLabel.FontName;
                dstLabel.FontSize   = srcLabel.FontSize;
                dstLabel.FontWeight = srcLabel.FontWeight;
                dstLabel.FontAngle  = srcLabel.FontAngle;
                dstLabel.Color      = srcLabel.Color;
            end

            %----------------------------
            % 2️⃣ 复制轴范围、比例、网格
            %----------------------------
            props = {
                'XLim','YLim','ZLim',...
                'XScale','YScale','ZScale',...
                'XDir','YDir','ZDir',...
                'Box','Color','LineWidth',...
                'XGrid','YGrid','ZGrid',...
                'XMinorGrid','YMinorGrid','ZMinorGrid',...
                'GridLineStyle','MinorGridLineStyle',...
                'Layer','TickDir','TickLength','Clipping',...
                'XAxisLocation','YAxisLocation',...
                'FontName','FontSize','FontWeight','FontAngle','FontSmoothing'
                };
            for k = 1:numel(props)
                if isprop(src, props{k})
                    try
                        dst.(props{k}) = src.(props{k});
                    catch
                        % 忽略只读或无效属性
                    end
                end
            end

            %----------------------------
            % 3️⃣ 复制刻度与刻度标签
            %----------------------------
            tickProps = {'XTick','YTick','ZTick','XTickLabel','YTickLabel','ZTickLabel'};
            for k = 1:numel(tickProps)
                if isprop(src, tickProps{k})
                    try
                        dst.(tickProps{k}) = src.(tickProps{k});
                    catch
                    end
                end
            end

            % %----------------------------
            % % 4️⃣ 复制比例、视角
            % %----------------------------
            % try
            %     if strcmp(src.DataAspectRatioMode,'manual')
            %         dst.DataAspectRatio = src.DataAspectRatio;
            %     end
            %     if strcmp(src.PlotBoxAspectRatioMode,'manual')
            %         dst.PlotBoxAspectRatio = src.PlotBoxAspectRatio;
            %     end
            % catch
            % end
            % if isprop(src, 'View')
            %     dst.View = src.View;
            % end
            % if isprop(src, 'CameraPosition')
            %     dst.CameraPosition = src.CameraPosition;
            %     dst.CameraTarget   = src.CameraTarget;
            %     dst.CameraUpVector = src.CameraUpVector;
            %     dst.CameraViewAngle = src.CameraViewAngle;
            % end

            %----------------------------
            % 5️⃣ 复制网格状态
            %----------------------------
            if strcmp(get(src,'XGrid'),'on'), grid(dst,'on'); else, grid(dst,'off'); end
            if strcmp(get(src,'YGrid'),'on'), grid(dst,'on'); else, grid(dst,'off'); end
            if strcmp(get(src,'ZGrid'),'on'), grid(dst,'on'); else, grid(dst,'off'); end
            if strcmp(get(src,'XMinorGrid'),'on'), grid(dst,'minor'); end
            if strcmp(get(src,'YMinorGrid'),'on'), grid(dst,'minor'); end

            %----------------------------
            % 6️⃣ 复制 legend
            %----------------------------
            lgd = legend(src);
            if ~isempty(lgd) && isvalid(lgd)
                % 获取 legend 所关联的绘图对象
                try
                    legend(dst, lgd.String, ...
                        'Location', lgd.Location, ...
                        'Orientation', lgd.Orientation, ...
                        'Box', lgd.Box);
                catch
                    % 某些 legend 设置可能无效时跳过
                    legend(dst, lgd.String, 'Location', lgd.Location);
                end
                newLgd = legend(dst);
                newLgd.FontSize   = lgd.FontSize;
                newLgd.FontName   = lgd.FontName;
                newLgd.FontWeight = lgd.FontWeight;
                newLgd.TextColor  = lgd.TextColor;
            end

            %----------------------------
            % 7️⃣ 复制 colormap / clim / colorbar
            %----------------------------
            try
                colormap(dst, colormap(src));
            catch
            end
            if isprop(src, 'CLim')
                try dst.CLim = src.CLim; end
            end
            cbar = findobj(src, 'Type', 'ColorBar');
            if ~isempty(cbar)
                for cb = reshape(cbar,1,[])
                    newCb = colorbar(dst, 'Location', cb.Location);
                    newCb.Limits = cb.Limits;
                    newCb.Ticks  = cb.Ticks;
                    newCb.Label.String = cb.Label.String;
                    newCb.Label.FontSize = cb.Label.FontSize;
                end
            end

            %----------------------------
            % 8️⃣ 保留 Hold 状态
            %----------------------------
            if ishold(src)
                hold(dst, 'on');
            else
                hold(dst, 'off');
            end
        end


        function dstTs = tsDataResample(refTs, dstTs, opts)
        % TSDataResample - Resample source timeseries with separate
        % interpolation & extrapolation methods.
        %
        % opts.interpMethod  - 内插方法（默认 pchip）
        % opts.extrapMethod  - 外插方法（默认 previous）

            arguments
                refTs timeseries
                dstTs timeseries
                opts.interpMethod  {mustBeMember(opts.interpMethod, ...
                    ["linear","nearest","previous","next","pchip","spline"])} = "pchip";

                opts.extrapMethod  {mustBeMember(opts.extrapMethod, ...
                    ["linear","nearest","previous","next","pchip","spline"])} = "nearest";
            end

            % 目标时间向量
            dstTime = dstTs.Time;
            refTime = refTs.Time;

            % 参考时间范围
            tMin = refTs.Time(1);
            tMax = refTs.Time(end);

            % mask
            isIn  = (dstTime >= tMin) & (dstTime <= tMax);
            inTsTime = dstTs.Time(isIn);
            inTsData = dstTs.Data(isIn);
            inTs = timeseries(inTsData, inTsTime);
            isRefIn = (refTime >= inTsTime(1)) & (refTime <= inTsTime(end));
            isRefOut = ~isRefIn;
            inTsNewTime = refTime(isRefIn);
            outTsNewTime = refTime(isRefOut);
            inTsNewData = interp1( ...
                inTs.Time, inTs.Data, inTsNewTime, ...
                opts.interpMethod, 'extrap');  % extrap无效，只在内部使用
            outTsNewData = find(isRefOut) * NaN;

            % 合并新数据
            dstNewData = zeros(size(refTime));
            dstNewData(isRefIn) = inTsNewData;
            dstNewData(isRefOut) = outTsNewData;
            dstNewTIme = refTime;

            % 将NaN部分外插
            isNaN = isnan(dstNewData);
            if any(isNaN)
                % —— 使用单独的方法外插（线性/nearest/pchip等）——
                dstNewData(isNaN) = interp1( ...
                    refTime(~isNaN), dstNewData(~isNaN), ...
                    refTime(isNaN), ...
                    opts.extrapMethod, 'extrap');
            end
            dstTs = timeseries(dstNewData, dstNewTIme);
        end


        function [out1, out2] = tsDataTimeAlign(refTs, dstTs, opts)
        % TSDataTimeAlign - Align two timeseries based on time range.

            arguments
                refTs timeseries
                dstTs timeseries
                opts.method {mustBeMember(opts.method, ["dst", "ref", "both"])} = "dst";
                opts.maxTimeGap double = 3;
            end     

            % 获取目标时间向量
            dstTime = dstTs.Time;
            refTime = refTs.Time;
            % 获取开始和结束时间
            if opts.method == "dst"
                startTime = refTime(1);
                endTime = refTime(end);
            elseif opts.method == "ref"
                startTime = dstTime(1);
                endTime = dstTime(end);
            elseif opts.method == "both"
                startTime = max(dstTime(1), refTime(1));
                endTime = min(dstTime(end), refTime(end));
            end

            % 截取时间范围内的数据
            refIdx = (refTime >= startTime) & (refTime <= endTime);
            dstIdx = (dstTime >= startTime) & (dstTime <= endTime);
            refTs = getsamples(refTs, find(refIdx));
            dstTs = getsamples(dstTs, find(dstIdx));

            % 检查时间间隔是否过大
            refTimeDiff = diff(refTs.Time);
            dstTimeDiff = diff(dstTs.Time);
            if any(refTimeDiff > opts.maxTimeGap)
                error('源时间序列存在过大时间间隔，可能影响对齐结果。');
            end
            if any(dstTimeDiff > opts.maxTimeGap)
                error('目标时间序列存在过大时间间隔，可能影响对齐结果。');
            end
            if (abs(refTs.Time(1) - dstTs.Time(1)) > opts.maxTimeGap) || ...
               (abs(refTs.Time(end) - dstTs.Time(end)) > opts.maxTimeGap)
                error('源和目标时间序列起止时间差异较大，可能影响对齐结果。');
            end

            if opts.method == "dst"
                out1 = dstTs;
                out2 = refTs;
            elseif opts.method == "ref"
                out1 = refTs;
                out2 = dstTs;
            elseif opts.method == "both"
                out1 = refTs;
                out2 = dstTs;
            end
        end
    

        function [data] = drawCheck(varargin)

            if nargin == 1
                data = varargin{1};
            elseif nargin == 2
                data = timeseries(varargin{2}, varargin{1});
            else
                error("参数错误");
            end
            if ~isa(data, 'timeseries')
                error("单参数必须是 timeseries 类型");
            end
            % 绘制数据检查

            maxLength = 10000;
            if length(data.Time) > maxLength
                newTime = linspace(data.Time(1), data.Time(end), maxLength);
                newTime = newTime(:);
                % [uniqueTime, ia] = unique(data.Time);
                % uniqueData = data.Data(ia);
                % newData = interp1(uniqueTime, uniqueData, newTime);
                newData = interp1(data.Time, data.Data, newTime);
                newData = newData(:);

                time = newTime;
                time = seconds(time);
                data = timetable(time, newData);
                data.Properties.VariableNames = {'data'};
            end
        end


        function [data] = drawCheckDt(varargin)

            if nargin == 1
                data = varargin{1};
            elseif nargin == 2
                data = timeseries(varargin{2}, varargin{1});
            else
                error("参数错误");
            end
            if ~isa(data, 'timeseries')
                error("单参数必须是 timeseries 类型");
            end
            % 绘制数据检查

            maxLength = 10000;
            if length(data.Time) > maxLength
                newTime = linspace(data.Time(1), data.Time(end), maxLength);
                newTime = newTime(:);
                % [uniqueTime, ia] = unique(data.Time);
                % uniqueData = data.Data(ia);
                % newData = interp1(uniqueTime, uniqueData, newTime);
                newData = interp1(data.Time, data.Data, newTime);
                newData = newData(:);

                % 时间转为 datetime 格式
                newTime = datetime(newTime, 'ConvertFrom', 'posixtime');
                time = newTime;
                data = timetable(time, newData);
                data.Properties.VariableNames = {'data'};
            end
        end
    

        function out = tsOutliersFix(ts, method)
        % TSOUTLIERSFIX - Fix outliers in a timeseries using specified method.
            arguments
                ts timeseries
                method {mustBeMember(method, ["linear";"spline";"pchip";"nearest";"movmedian"])} = "movmedian"
            end

            data = ts.Data;
            time = ts.Time;

            % 检测异常值
            outlierIdx = isoutlier(data, "movmedian", length(data)/10);

            % 修正异常值
            if any(outlierIdx)
                if method == "movmedian"
                    fixedData = data;
                    thisMovmedian = movmedian(data, 5, 'omitnan');
                    fixedData(outlierIdx) = thisMovmedian(outlierIdx);
                else
                    fixedData = data;
                    fixedData(outlierIdx) = interp1( ...
                        time(~outlierIdx), data(~outlierIdx), ...
                        time(outlierIdx), method, 'extrap');
                end
            else
                fixedData = data;
            end

            out = timeseries(fixedData, time);
        end

        
    end
end