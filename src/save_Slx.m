% save_Slx - 导出Slx文件为指定版本, 和指定类型
function save_Slx(opts)
% exportSlx - 导出Slx文件为指定版本, 和指定类型
%   opts: 选项结构体, 包含以下字段:
%       version: 指定的Slx版本
%       type: 指定的导出类型
%       modelName: 要导出的模型名称
%       modelPath: 要加载并导出的模型文件的路径
%       filePath: 导出文件的路径

    arguments
        opts.version (1,1) string ...
        {mustBeMember(opts.version, ["R2020b"; "R2021a"; "R2021b"; "R2022a"; "R2022b"; "R2023a"; "R2023b"; "R2024a"; "R2024b"])} = "R2023b"
        opts.type (1,1) string {mustBeMember(opts.type, ["slx"; "mdl"])} = "slx"
        opts.modelName (1,1) string = ''
        opts.modelPath (1,1) string = ''
        opts.filePath (1,1) string = ''
    end

    opts = exportSlx("version", opts.version, ...
        "type", opts.type, ...
        "modelName", opts.modelName, ...
        "modelPath", opts.modelPath, ...
        "filePath", opts.filePath);
    if ~opts.Ok
        return;
    end
    % 运行2023b版本的MATLAB, 读取模型, 运行 set_param(bdroot, "GenerateASAP2", true), 后保存
    matlabPath = findMatlab("version", "R2023b");
    if isempty(matlabPath)
        error("未找到指定版本的MATLAB安装路径，请检查MATLAB安装情况。");
    end
    % 使用系统命令行运行MATLAB
    runCode = append("load_system('", opts.filePath, "');");
    runCode = append(runCode, "set_param(bdroot, 'GenerateASAP2', true);");
    runCode = append(runCode, "save_system(bdroot);");
    runCode = append(runCode, "exit;");
    cmd = append('"', matlabPath, '" -nosplash -nodesktop -wait -r "', runCode, '"');
    [status, cmdout] = system(cmd);
    if status ~= 0
        error("在MATLAB中执行命令时出错：%s", cmdout);
    end
    disp("Slx文件导出成功: " + "'" + opts.filePath + "'");
end
