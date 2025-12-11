classdef general

    methods(Static)

        function data = readMyMdfData(filePath)

            persistent dataBuf;
            persistent lastFilePath;
        
            if isempty(dataBuf)
                dataBuf = [];
                lastFilePath = '';
            end
        
            % 检查文件名是否相同
            if strcmp(lastFilePath, filePath) && ~isempty(dataBuf)
                data = dataBuf;
                return;
            end
            data = mdfRead(filePath);
            lastFilePath = filePath;
            dataBuf = data;
        end

        function varDatas = readMdfData(opts)

            arguments
                opts.filePath string = "";
                opts.varName (:, 1) string = "";
                opts.XCP (:, 1) int32 = -1;
            end

            filePath = opts.filePath;
            varName = opts.varName;
            XCP = opts.XCP;

            if isequal(filePath, "")
                [filename, pathname] = uigetfile({'*.mdf;*.dat;*.mf4', 'MDF文件 (*.mdf, *.dat, *.mf4)'; '*.*', '所有文件 (*.*)'}, '选择MDF文件');
                if isequal(filename, 0)
                    disp('用户取消了选择');
                    varDatas = [];
                    return;
                end
                filePath = fullfile(pathname, filename);
            end

            mdfData = myOp.mdf.general.readMyMdfData(filePath);

            mdfDataInfo = mdfInfo(filePath);
            mdfStartTime = posixtime(mdfDataInfo.InitialTimestamp);

            if ~isequal(varName, "")
                if isscalar(XCP) && XCP ~= -1
                    for i = 1:length(varName)
                        thisVarName = varName(i);
                        thisVarName = append(thisVarName, "\XCP: ", num2str(XCP));
                        varName(i) = thisVarName;
                    end
                elseif isscalar(XCP) && XCP == -1
                    for i = 1:length(varName)
                        thisVarName = varName(i);
                        thisVarName = append(thisVarName, "\XCP: 1");
                        varName(i) = thisVarName;
                    end
                elseif isvector(XCP) && length(XCP) == length(varName)
                    for i = 1:length(varName)
                        thisVarName = varName(i);
                        thisXCP = XCP(i);
                        thisVarNameXCP = append(thisVarName, "\XCP: ", num2str(thisXCP));
                        varName(i) = thisVarNameXCP;
                    end
                else
                    error('XCP must be a scalar or a vector with the same length as varName.');
                end
            end

            varDatas = [];
            if isequal(varName, "")
                for i = 1:length(mdfData)
                    thisMdfData = mdfData{i};
                    thisTableVarName = thisMdfData.Properties.VariableNames;
                    thisTableVarName = thisTableVarName(:);
                    thisTableVarName = string(thisTableVarName);
                    for j = 1:length(thisTableVarName)
                        nameFull = split(thisTableVarName{j}, "\XCP: ");
                        if length(nameFull) == 1
                            varData.name = nameFull{1};
                            varData.XCP = 0;
                            varData.Data = mdfData{i}.(thisTableVarName{j});
                            timeAxisName = mdfData{i}.Properties.DimensionNames{1};
                            varData.Time = mdfData{i}.(timeAxisName);
                            varData.Time = seconds(varData.Time);
                            varData.startTime = mdfStartTime;
                            varData.Tss = timeseries(varData.Data, varData.Time);
                            varData.Tss.Name = varData.name;
                            varDatas = [varDatas; varData];
                        else
                            try
                                varData.name = nameFull{1};
                                varData.XCP = str2num(nameFull{2});
                                varData.Data = mdfData{i}.(thisTableVarName{j});
                                timeAxisName = mdfData{i}.Properties.DimensionNames{1};
                                varData.Time = mdfData{i}.(timeAxisName);
                                varData.Time = seconds(varData.Time);
                                varData.startTime = mdfStartTime;
                                varData.Tss = timeseries(varData.Data, varData.Time);
                                varData.Tss.Name = varData.name;
                                varDatas = [varDatas; varData];
                            catch
                                % 跳过无法解析的变量
                            end
                        end
                    end
                end
            else
                for i = 1:length(varName)
                    thisVarName = varName{i};
                    isGet = false;
                    % 遍历mdfData, 查找变量
                    for j = 1:length(mdfData)
                        thisMdfData = mdfData{j};
                        thisTableVarName = thisMdfData.Properties.VariableNames;
                        thisTableVarName = thisTableVarName(:);
                        thisTableVarName = string(thisTableVarName);
                        % 查看是否包含变量名
                        if any(contains(thisTableVarName, thisVarName))
                            % 如果包含，则返回该变量的数据
                            nameFull = split(thisVarName, "\XCP: ");
                            if length(nameFull) == 1
                                varData.name = nameFull{1};
                                varData.XCP = 0;
                                varData.Data = mdfData{j}.(thisVarName);
                                timeAxisName = mdfData{j}.Properties.DimensionNames{1};
                                varData.Time = mdfData{j}.(timeAxisName);
                                varData.Time = seconds(varData.Time);
                                varData.startTime = mdfStartTime;
                                varData.Tss = timeseries(varData.Data, varData.Time);
                                varData.Tss.Name = varData.name;
                                varDatas = [varDatas; varData];
                                isGet = true;
                            else
                                varData.name = nameFull{1};
                                varData.XCP = str2num(nameFull{2});
                                varData.Data = mdfData{j}.(thisVarName);
                                timeAxisName = mdfData{j}.Properties.DimensionNames{1};
                                varData.Time = mdfData{j}.(timeAxisName);
                                varData.Time = seconds(varData.Time);
                                varData.startTime = mdfStartTime;
                                varData.Tss = timeseries(varData.Data, varData.Time);
                                varData.Tss.Name = varData.name;
                                varDatas = [varDatas; varData];
                                isGet = true;
                            end
                        end
                        if isGet
                            break;
                        end
                    end
                end
            end
            varDatas = myOp.mdf.incaData(varDatas);
        end
    end
end