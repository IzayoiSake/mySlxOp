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

    opts.isAutoLoad = false;
    if ~isequal(opts.modelName, '')
        % 检查是否已经加载了模型
        if ~bdIsLoaded(opts.modelName)
            error("模型 '%s' 未加载，请先加载模型。", opts.modelName);
        end
        model = opts.modelName;
    elseif ~isequal(opts.modelPath, '')
        model = load_system(opts.modelPath);
        model = get_param(model, 'Name');
        opts.isAutoLoad = true;
    else
        model = bdroot;
        if isempty(model)
            f = figure('Renderer' , 'painters' , 'Position' , [-100 -100 0 0]);
            [fileName, fileDir] = uigetfile({'*.slx'; '*.mdl'}, '选择要加载并导出的模型文件');
            close(f);
            if isequal(fileName, 0)
                disp("未选择文件，操作已取消。");
                return;
            end
            model = load_system(fullfile(fileDir, fileName));
            model = get_param(model, 'Name');
            opts.isAutoLoad = true;
        end
    end
    opts.modelName = model;

    if isequal(opts.filePath, '')
        f = figure('Renderer' , 'painters' , 'Position' , [-100 -100 0 0]);
        % 等用户选择导出文件路径, 扩展名必须为 "slx" 或 "mdl"
        [fileName, fileDir] = uiputfile({append("*.", opts.type); '*.slx'; '*.mdl'}, '保存导出文件', append(model, ".", opts.type));
        close(f);
        if isequal(fileName, 0)
            disp("未选择文件，操作已取消。");
            return;
        end
        opts.filePath = fullfile(fileDir, fileName);
    end

    % 创建一个随机临时文件夹
    aDir = tempname;
    if ~isfolder(aDir)
        mkdir(aDir);
    end

    aPath = fullfile(aDir, opts.modelName);
    aPath = append(aPath, ".", opts.type);

    % 导出Slx文件到临时文件夹
    optsExp = exportSlx("version", opts.version, ...
        "type", opts.type, ...
        "modelName", opts.modelName, ...
        "modelPath", opts.modelPath, ...
        "filePath", aPath);
    if ~optsExp.Ok
        return;
    end

    % changedPath = myOp.path.getChangedPath();

    % disp("正在使用MATLAB COM服务器执行Slx文件保存操作...");
    % h = myOp.comServer.getMatlabComServer();
    % h.Execute("clear;");
    % cmd = append("cd(""", pwd, """);");
    % for i = 1:length(changedPath)
    %     cmd = append(cmd, "addpath(""", changedPath{i}, """);");
    % end
    % cmd = append(cmd, "load_system(""", aPath, """);");
    % cmd = append(cmd, "set_param(bdroot, 'GenerateASAP2', true);");
    % cmd = append(cmd, "save_system(bdroot);");
    % cmd = append(cmd, "close_system(bdroot, 0);");
    % for i = 1:length(changedPath)
    %     cmd = append(cmd, "rmpath(""", changedPath{i}, """);");
    % end
    % h.Execute(cmd);

    % 将临时文件夹中的文件移动到指定路径
    movefile(aPath, opts.filePath, 'f');

    % 删除临时文件夹
    if isfolder(aDir)
        rmdir(aDir, 's');
    end

    if opts.isAutoLoad
        close_system(opts.modelName, 0);
    end

    myOp.slx.file.onGenerateASAP2("path", opts.filePath, "mute", true);

    disp("Slx文件导出成功: " + "'" + opts.filePath + "'");
end
