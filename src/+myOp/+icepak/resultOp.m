classdef resultOp < handle
    properties(Access = private)
        fileHeaders
        path
    end
    properties(Access = public)
        nodes (:, 1) myOp.icepak.node
        type
    end

    methods(Access = public)

        function getResult(self, path)
            arguments
                self (1, 1)
                path (1, :) {mustBeText} = "";
            end
            if isequal(path, "")
                % 创建一个不可见的figure对象
                f = figure('Visible', 'off');
                % 打开文件选择对话框
                [file, folder] = uigetfile({'*.txt;*.csv;', 'All Files (*.*)'}, 'Select a file');
                % 检查用户是否选择了文件
                if isequal(file, 0)
                    return;
                else
                    path = fullfile(folder, file);
                end
            end
            if isfile(path)
                self.path = path;
            else
                msg = "❌️ 文件: " + newline + path + newline + "不存在，请重新选择！";
                error(msg);
            end
            content = readcell(self.path, 'Delimiter', ',');
            self.fileHeaders = string(content(1:3, 1:2));
            % 找到 "Object" 的位置
            isOk = false;
            for i = 1:size(content, 1)
                thisRow = content(i, :);
                thisRow = string(thisRow);
                index = find(thisRow == "Object");
                if ~isempty(index)
                    timeIndex = find(thisRow == "Time Value");
                    if ~isempty(timeIndex)
                        self.type = "Transient";
                    else
                        self.type = "Steady";
                    end
                    meanIndex = find(thisRow == "Mean");
                    headerRow = i;
                    isOk = true;
                    break;
                end
            end
            if ~isOk
                msg = "❌️ 文件: " + newline + path + newline + "内容格式不正确，请重新选择！";
                error(msg);
            end
            if length(index) ~= length(meanIndex)
                msg = "❌️ 文件: " + newline + path + newline + "内容格式不正确，请重新选择！";
                error(msg);
            end
            if isequal(self.type, "Transient") && length(timeIndex) ~= length(meanIndex)
                msg = "❌️ 文件: " + newline + path + newline + "内容格式不正确，请重新选择！";
                error(msg);
            end

            for i = 1:length(index)
                thisIndex = index(i);
                thisMeanIndex = meanIndex(i);
                for j = (headerRow + 1) : size(content, 1)
                    if isequal(self.type, "Transient")
                        thisTimeIndex = timeIndex(i);
                        nodeName = string(content{j, thisIndex});
                        nodeTime = content{j, thisTimeIndex};
                        nodeTemperature = content{j, thisMeanIndex};
                    else
                        nodeName = string(content{j, thisIndex});
                        nodeTemperature = content{j, thisMeanIndex};
                    end
                    theNode = myOp.icepak.node.findNodes(self.nodes, "name", nodeName);
                    if isempty(theNode)
                        % 如果节点不存在，则创建新节点
                        if isequal(self.type, "Transient")
                            node = myOp.icepak.node(nodeName, "time", nodeTime, "temperature", nodeTemperature);
                        else
                            node = myOp.icepak.node(nodeName, "temperature", nodeTemperature);
                        end
                        self.nodes(end + 1) = node;
                    else
                        % 如果节点已存在，则更新其数据
                        if isequal(self.type, "Transient")
                            theNode.append("time", nodeTime, "temperature", nodeTemperature);
                        else
                            theNode.set("temperature", nodeTemperature);
                        end
                    end
                end
            end
            self.nodes = self.nodes(:);
            arrayfun(@(node) node.tidy(), self.nodes);
            self.sortNodes();
        end

        function sortNodes(self)
            self.nodes = myOp.icepak.node.sort(self.nodes);
            self.nodes = self.nodes(:);
        end

        function tableData = dispResult(self)
            tableData = table("VariableNames", ["Name", "Time", "Temperature"]);
            for i = 1:length(self.nodes)
                node = self.nodes(i);
                nodeName = node.name;
                nodeTime = node.time;
                nodeTemperature = node.temperature;
                tableData = [tableData; {nodeName, nodeTime, nodeTemperature}];
            end
        end
        
        function saveResult(self, opts)
             arguments
                self (1, 1)
                opts.path (1, :) {mustBeText} = "";
                opts.overwrite (1, 1) = false;
            end
            if ~isequal(opts.path, "")
                savePath = opts.path;
            elseif opts.overwrite
                savePath = self.path;
            else
                [fileDir, fileName, fileExt] = fileparts(self.path);
                fileDir = fullfile(fileDir, "modified");
                if ~exist(fileDir, 'dir')
                    mkdir(fileDir);
                end
                savePath = fullfile(fileDir, fileName + fileExt);
            end
            if isequal(self.type, "Steady")
                nodeHeader = ["Object", "Section", "Sides", "Value", "Min", "Max", "Mean", "Stdev", "Area/volume", "Mesh"];
                writeData = cell(length(self.nodes) + 4, length(nodeHeader));
                writeData(4, 1:end) = cellstr(nodeHeader);
            else
                nodeHeader = ["Time Value", "Object", "Section", "Sides", "Value", "Min", "Max", "Mean", "Stdev", "Total", "Area/volume"];
                writeData = cell(self.nodes(1).dataLength() + 4, length(nodeHeader) * length(self.nodes) + 1);
                writeData{4, 1} = "Solution ID";
                writeData(4, 2:end) = repmat(cellstr(nodeHeader), 1, length(self.nodes));
                [~, fileName, ~] = fileparts(self.path);
                writeData(5:end, 1) = cellstr(fileName);
            end
            writeData(1:3, 1:2) = cellstr(self.fileHeaders);

            if isequal(self.type, "Steady")
                for i = 1:length(self.nodes)
                    node = self.nodes(i);
                    nodeName = node.name;
                    nodeTemperature = node.temperature;
                    writeData{i + 4, 1} = nodeName;
                    writeData{i + 4, 2} = "All";
                    writeData{i + 4, 3} = "All";
                    writeData{i + 4, 4} = "Temperature (C)";
                    writeData{i + 4, 5} = "";
                    writeData{i + 4, 6} = "";
                    writeData{i + 4, 7} = nodeTemperature;
                    writeData{i + 4, 8} = "";
                    writeData{i + 4, 9} = "";
                    writeData{i + 4, 10} = "Full";
                end
            else
                for i = 1:length(self.nodes)
                    node = self.nodes(i);
                    nodeName = node.name;
                    nodeTime = node.time;
                    nodeTemperature = node.temperature;
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 2) = cellstr(string(nodeName));
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 1) = cellstr(string(nodeTime));
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 3) = cellstr("All");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 4) = cellstr("All");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 5) = cellstr("Temperature (C)");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 6) = cellstr("");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 7) = cellstr("");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 8) = cellstr(string(nodeTemperature));
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 9) = cellstr("");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 10) = cellstr("");
                    writeData(5:end, 1 + (i - 1) * length(nodeHeader) + 11) = cellstr("");
                end
            end
            writecell(writeData, savePath);
        end
    
        function nodes = getNodes(self, opts)
            arguments
                self (1, 1)
                opts.byName (:, 1) = "";
                opts.byRawName (:, 1) = "";
                opts.byLayer (:, 1) = [];
                opts.byPosition (:, 1) = [];
            end
            nodes = self.nodes;
            if ~isequal(opts.byName, "")
                names = arrayfun(@(node) node.getName(), nodes);
                names = string(names);
                names = names(:);
                idx = ismember(names, opts.byName);
                nodes = nodes(idx);
            end
            if ~isequal(opts.byRawName, "")
                rawNames = arrayfun(@(node) node.getRawName(), nodes);
                rawNames = string(rawNames);
                rawNames = rawNames(:);
                idx = ismember(rawNames, opts.byRawName);
                nodes = nodes(idx);
            end
            if ~isempty(opts.byLayer)
                layers = arrayfun(@(node) node.layer(), nodes);
                idx = ismember(layers, opts.byLayer);
                nodes = nodes(idx);
            end
            if ~isempty(opts.byPosition)
                positions = arrayfun(@(node) node.position(), nodes);
                idx = ismember(positions, opts.byPosition);
                nodes = nodes(idx);
            end
        end
    
        function setNodes(self, nodes)
            self.nodes = nodes;
        end

        function expandTempt(self, opts)
            arguments
                self (1, 1)
                opts.positions (:, 1) = [];
                opts.cofficient (1, 1) {mustBeNumeric} = 1;
            end
            positions = opts.positions;
            if isempty(positions)
                return;
            end
            cofficient = opts.cofficient;
            for i = 1:length(positions)
                pos = positions(i);
                theNodes = self.getNodes("byPosition", pos);
                theNodes = myOp.icepak.node.sort(theNodes);
                for j = 1:(length(theNodes) - 1)
                    theNode = theNodes(j);
                    endNode = theNodes(end);
                    theTempt = theNode.temperature;
                    endTempt = endNode.temperature;
                    temptDiff = theTempt - endTempt;
                    theNewTempt = endTempt + temptDiff * cofficient;
                    theNode.set("temperature", theNewTempt);
                end
            end
        end

    end


end