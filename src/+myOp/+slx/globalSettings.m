classdef globalSettings

    methods(Static)

        function expandSampleTimeColors()
            % 创建一个调色板对象
            plt = simulink.sampletimecolors.Palette("R2023aStyle");

            % 设置旧版的离散采样时间颜色（红、绿、蓝、浅蓝、深绿）
            plt.DiscreteSampleTimeColors = [
                1.0000  0.2706  0.2275;  % 红色
                0.2275  0.7843  0.1922;  % 绿色
                0.0549  0.0000  1.0000;  % 蓝色
                0.3098  0.7373  1.0000;  % 浅蓝色
                0.0000  0.5020  0.0000   % 深绿色
            ];

            % 保存为可复用调色板
            simulink.sampletimecolors.storePalette(plt);

            % 应用并设为用户默认
            simulink.sampletimecolors.applyPalette(plt, "UserDefault", true);
        end
    end
end