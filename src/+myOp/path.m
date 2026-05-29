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
    
        function paths = getCurrentPath()
            % getWorkPath 获取工作文件夹的路径
            currentPathStr = path;
            currentPathCell = regexp(currentPathStr, pathsep, 'split')';
            % 排除空的路径
            idx = cellfun(@(x) ~isequal(x, ""), currentPathCell);
            currentPathCell = currentPathCell(idx);
            paths = currentPathCell;
        end

        function paths = getDefaultPath()
            % getDefaultPath 获取默认文件夹的路径
            defaultPathStr = pathdef;
            defaultPathCell = regexp(defaultPathStr, pathsep, 'split')';
            % 排除空的路径
            idx = cellfun(@(x) ~isequal(x, ""), defaultPathCell);
            defaultPathCell = defaultPathCell(idx);
            paths = defaultPathCell;
        end        
        
        function paths = getChangedPath()
            % getChangedPath 获取已更改的文件夹的路径
            currentPathCell = myOp.path.getCurrentPath();
            defaultPathCell = myOp.path.getDefaultPath();
            % 获取已更改的路径
            changedPathCell = setdiff(currentPathCell, defaultPathCell, 'stable');
            
            % 排除特殊路径（可扩展的模式匹配）
            excludePatterns = { ...
                '\\.vscode\\extensions\\', ...
                '\\MathWorks\\MATLAB Add-Ons\\', ...
                '\\.matlab\\agentic-toolkits\\'
            };
            
            % 使用正则匹配进行过滤
            if ~isempty(changedPathCell)
                % 将模式组合成一个正则表达式 (pattern1|pattern2|...)
                combinedPattern = strjoin(excludePatterns, '|');
                % 找到匹配的索引并剔除
                isExcluded = ~cellfun(@isempty, regexp(changedPathCell, combinedPattern, 'once'));
                changedPathCell(isExcluded) = [];
            end
            
            paths = changedPathCell;
        end

        function clearChangedPath()
            % clearChangedPath 清除已更改的文件夹的路径
            changedPathCell = myOp.path.getChangedPath();
    
            if isempty(changedPathCell)
                return; 
            end

            % 2. 向量化过滤：排除包含 'mingw' 的路径
            isMinGW = endsWith(changedPathCell, 'mingw');
            toRemove = changedPathCell(~isMinGW);

            if isempty(toRemove)
                disp('✨ 没有需要移除的路径。');
                return;
            end

            % 3. 核心优化点：批量移除路径 (一次性刷新缓存)
            % 使用 {:} 将 cell 展开为参数列表，大幅提升性能
            rmpath(toRemove{:});

            % 4. 批量生成并显示信息
            messages = cell(size(toRemove));
            for i = 1:length(toRemove)
                p = toRemove{i};
                % 构造超链接，点击可直接打开文件夹
                messages{i} = sprintf('❗️已从路径中移除: <a href="matlab:winopen(''%s'')">%s</a> ;', p, p);
            end

            % 一次性显示所有信息
            disp(strjoin(messages, newline));
        end
    
    end
end