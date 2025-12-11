function path = findMatlab(opts)
% findMatlab - Find the specified MATLAB installation
    arguments
        opts.version (1,1) string = "";
    end

    if isempty(opts.version) || strcmp(opts.version, "")
        % 如果没有指定版本，则使用默认的MATLAB安装路径
        path = fullfile(matlabroot, 'bin', 'matlab');
    else
    % 查找指定版本的MATLAB安装路径
        % 检查输入version参数是否是以"R"开头, 以"a"或"b"结尾, 且中间是数字
        if ~(startsWith(opts.version, "R") || startsWith(opts.version, "r")) || ~(endsWith(opts.version, "a") || endsWith(opts.version, "b"))
            error('无效的MATLAB版本格式: %s', opts.version);
        else
            opts.version = strrep(opts.version, "r", "R");
            % 从环境变量中获取MATLAB安装路径
            envPath = getenv('path');
            envPath = strsplit(envPath, pathsep);
            envPath = envPath(:);
            % 查找符合版本号的MATLAB安装路径
            for i = 1:length(envPath)
                if contains(envPath{i}, sprintf("MATLAB\\%s\\bin", opts.version))
                    path = fullfile(envPath{i}, 'matlab');
                    return;
                end
            end
            error('未找到指定版本的MATLAB安装路径: %s', opts.version);
        end
    end
end