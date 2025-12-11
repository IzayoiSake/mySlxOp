classdef incaData

    properties(Access = public)
        data;
        names;
    end

    methods(Access = public)

        function obj = incaData(data)
            % INCADATA 构造此类的实例

            if nargin > 0
                obj = obj.set(data);
            end
            
        end

        function data = get(obj, varName)
            % GET 获取指定变量的数据结构体
            %
            %   GET(VARNAME) 获取指定变量名的数据结构体
            %
            %   VARNAME 可以是字符串数组或字符串向量，表示变量名
            %
            %   如果 VARNAME 为空字符串，则获取所有变量的数据结构体

            varname = string(varName);
            for i = 1:length(varname)
                idx = find(strcmp(varname(i), obj.names), 1);
                if isempty(idx)
                    error('Variable name %s not found.', varname(i));
                end
                data(i) = obj.data(idx);
            end
        end
        
        function obj = set(obj, data)
            % SET 设置数据结构体
            %
            %   SET(DATA) 设置数据结构体
            %
            %   DATA 必须是个结构体数组, 且包含字段 'Time' 和 'Data' 和 'name'

            for i = 1:length(data)
                assert(isstruct(data(i)), 'each element of data must be a struct');
                assert(isfield(data(i), 'Time'), 'data must contain field Time');
                assert(isfield(data(i), 'Data'), 'data must contain field Data');
                assert(isfield(data(i), 'name'), 'data must contain field name');
            end
            obj.data = data;
            obj.names = arrayfun(@(x) x.name, data, 'UniformOutput', false);
            obj.names = string(obj.names);
        end

        function data = getAb(obj, varName)
            % GETAB 获取指定变量的时间序列数据
            %
            %   GETAB(VARNAME) 获取指定变量名的时间序列数据
            %
            %   VARNAME 可以是字符串数组或字符串向量，表示变量名
            %
            %   如果 VARNAME 为空字符串，则获取所有变量的时间序列数据

            varname = string(varName);
            for i = 1:length(varname)
                idx = find(strcmp(varname(i), obj.names), 1);
                if isempty(idx)
                    error('Variable name %s not found.', varname(i));
                end
                data(i) = obj.data(idx);
                startTime = data(i).startTime;
                data(i).Time = data(i).Time + startTime;
                data(i).Tss.Time = data(i).Time;
            end
        end

    end
end