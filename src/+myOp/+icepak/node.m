classdef node < handle
    properties(GetAccess = public, SetAccess = private)
        name
        time (:, 1)
        temperature (:, 1)
        rawName
    end

    methods(Access = public)

        function self = node(name, opts)
            arguments
                name (1, 1) {mustBeText} = "";
                opts.time (:, 1) {mustBeNumeric} = NaN;
                opts.temperature (:, 1) {mustBeNumeric} = NaN;
            end
            self.rawName = name;
            self.name = name;
            self.time = opts.time;
            self.temperature = opts.temperature;
        end
    
        function setPosLay(self, opts)
            arguments
                self (1, 1)
                opts.layer (1, 1) {mustBeNumeric} = self.layer();
                opts.position (1, 1) {mustBeNumeric} = self.position();
            end
            namingRule = self.namingRule();
            if isequal(namingRule, "point")
                tempStr = repelem(".1", opts.layer - 1);
                if isempty(tempStr)
                    tempStr = "";
                end
                tempStr = strjoin(tempStr, "");
                self.name = append("P.", string(opts.position), tempStr);
            elseif isequal(namingRule, "underline")
                self.name = append("P_", string(opts.position), "_", string(opts.layer));
            end
        end

        function namingRule = namingRule(self, opts)
            arguments
                self (1, 1)
                opts.name (1, 1) string = self.name;
            end
            % 如果name以 "P." 开头，则认为 "点" 命名
            if startsWith(opts.name, "P.")
                namingRule = "point";
            % 如果name以 "P_" 开头，则认为 "下划线" 命名
            elseif startsWith(opts.name, "P_")
                namingRule = "underline";
            end
        end

        function set(self, opts)
            arguments
                self (1, 1)
                opts.name (1, 1) {mustBeText} = self.name;
                opts.time (:, 1) {mustBeNumeric} = self.time;
                opts.temperature (:, 1) {mustBeNumeric} = self.temperature;
            end
            self.name = opts.name;
            self.time = opts.time;
            self.temperature = opts.temperature;
        end

        function layer = layer(self)
            namingRule = self.namingRule();
            if isequal(namingRule, "point")
                layer = count(self.name, ".");
            elseif isequal(namingRule, "underline")
                splitName = split(self.name, "_");
                layer = str2double(splitName{3});
            end
        end

        function position = position(self)
            namingRule = self.namingRule();
            if isequal(namingRule, "point")
                splitName = split(self.name, ".");
                position = str2double(splitName{2});
            elseif isequal(namingRule, "underline")
                splitName = split(self.name, "_");
                position = str2double(splitName{2});
            end
        end

        function nodeType = getType(self)
            if any(isnan(self.time))
                nodeType = "Steady";
            else
                nodeType = "Transient";
            end
        end

        function setName(self, opts)
            arguments
                self (1, 1)
                opts.name (1, 1) {mustBeText} = "";
            end
            if ~isequal(opts.name, "")
                self.name = opts.name;
            end
        end

        function name = getName(self)
            arguments
                self (1, 1)
            end
            name = self.name;
        end

        function name = getRawName(self)
            arguments
                self (1, 1)
            end
            name = self.rawName;
        end

        function append(self, opts)
            arguments
                self (1, 1)
                opts.time (1, 1) {mustBeNumeric} = NaN;
                opts.temperature (1, 1) {mustBeNumeric} = NaN;
            end
            theTime = opts.time;
            theTemperature = opts.temperature;

            if any(isnan(self.time)) && ~isnan(theTime)
                msg = append("⚠️: 节点 ", self.name, " 的时间值为 NaN, 类型为 steady 类型节点, 无法添加时间值！忽略本次修改");
                warning(msg);
            elseif ~any(isnan(self.time)) && isnan(theTime)
                msg = append("⚠️: 节点 ", self.name, " 已有时间值, 类型为 transient 类型节点, 无法添加 steady 类型的时间值 NaN！忽略本次修改");
                warning(msg);
            elseif any(isnan(self.time)) && isnan(theTime)
                self.time = theTime;
                self.temperature = theTemperature;
            else
                % 查找是否已有时间值，如果有则覆盖，没有则添加
                timeIndex = find(self.time == theTime);
                if isempty(timeIndex)
                    self.time(end + 1) = theTime;
                    self.temperature(end + 1) = theTemperature;
                else
                    self.temperature(timeIndex) = theTemperature;
                end
            end
        end
        
        function tidy(self)
            % 将时间和温度按照时间排序
            [self.time, sortIndex] = sort(self.time);
            self.temperature = self.temperature(sortIndex);
        end

        function length = dataLength(self)
            length = numel(self.time);
        end

        function newNode = copy(self)
            newNode = myOp.icepak.node(self.rawName, "time", self.time, "temperature", self.temperature);
            newNode.setName("name", self.name);
        end

    end

    methods(Static)

        function nodes = sort(nodes)
            arguments
                nodes (:, 1) myOp.icepak.node
            end
            % 按照position排序
            allPositions = arrayfun(@(node) node.position(), nodes);
            [~, positionOrder] = sort(allPositions);
            nodes = nodes(positionOrder);
            % 按照layer排序
            allLayers = arrayfun(@(node) node.layer(), nodes);
            [~, layerOrder] = sort(allLayers);
            nodes = nodes(layerOrder);
        end

        function nodesOut = findNodes(nodes, opts)
            arguments
                nodes (:, 1) myOp.icepak.node
                opts.name (1, 1) {mustBeText} = "";
                opts.layer (1, 1) {mustBeNumeric} = NaN;
                opts.position (1, 1) {mustBeNumeric} = NaN;
            end
            if isequal(opts.name, "") && isnan(opts.layer) && isnan(opts.position)
                nodes = [];
            end
            if ~isequal(opts.name, "") && ~isempty(nodes)
                nodes = nodes(arrayfun(@(node) isequal(node.name, opts.name), nodes));
            end
            if ~isnan(opts.layer) && ~isempty(nodes)
                nodes = nodes(arrayfun(@(node) isequal(node.layer(), opts.layer), nodes));
            end
            if ~isnan(opts.position) && ~isempty(nodes)
                nodes = nodes(arrayfun(@(node) isequal(node.position(), opts.position), nodes));
            end
            nodesOut = nodes;
        end

    end


    methods(Access = private)
        
    end

end