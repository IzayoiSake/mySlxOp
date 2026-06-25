function showSlx()
    % 获取当前 MATLAB 会话中已加载的全部 block diagram
    bds = find_system('SearchDepth', 0, ...
                      'Type', 'block_diagram');

    if isempty(bds)
        fprintf('No Simulink models are loaded.\n');
        return;
    end

    % 获取 block diagram 类型
    bdTypes = get_param(bds, 'BlockDiagramType');

    % 普通模型 + 引用子系统
    idx = ismember(bdTypes, {'model', 'subsystem'});

    bds = bds(idx);
    bdTypes = bdTypes(idx);

    if isempty(bds)
        fprintf('No model or referenced subsystem is loaded.\n');
        return;
    end

    for i = 1:numel(bds)
        bd = bds{i};
        bdType = bdTypes{i};

        file = get_param(bd, 'FileName');

        if isempty(file)
            file = '<unsaved>';
        end

        fprintf('%s [%s] -> %s\n', bd, bdType, file);
    end
end