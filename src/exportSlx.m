function opts = exportSlx(opts)
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

    opts.Ok = false;
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

    try
        save_system(model, opts.filePath, ...
            'ExportToVersion', opts.version, ...
            'OverwriteIfChangedOnDisk', true);
        opts.Ok = true;
    catch ME
        disp("导出Slx文件失败: " + ME.message);
        opts.Ok = false;
    end
    
    if opts.isAutoLoad
        close_system(model, 0);
    end
end
