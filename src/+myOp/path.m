classdef path

    methods(Static)
        function path = getZinSightPath()
            % getZinSightPath 获取ZinSight文件夹的路径
            % 获取当前文件的路径
            currentPath = mfilename('fullpath');
            % 当前文件是ZinSight文件夹下的子文件(多层文件夹下)
            index = strfind(currentPath, '502_Matlab');
            if isempty(index)
                error('当前文件不在ZinSight文件夹下');
            end
            % 获取ZinSight文件夹的路径
            path = currentPath(1:index-2);
        end
    end
end