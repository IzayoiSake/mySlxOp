function uninstall_toolbox(toolboxName)

    arguments
        % 可选参数：工具箱名称，默认为 ""
        toolboxName (1, 1) string = "";
    end

    if isequal(toolboxName, "")
        % 如果未提供工具箱名称，提示用户输入
        toolboxName = input("请输入要卸载的工具箱名称（例如 'My Toolbox'）：", "s");
    end

    % 1. 查找所有已安装的附加功能
    allAddons = matlab.addons.installedAddons;

    % 2. 筛选出名为 "My Toolbox" 的行
    targetAddon = allAddons(strcmp(allAddons.Name, toolboxName), :);

    % 3. 如果找到了，执行卸载
    if ~isempty(targetAddon)
        fprintf('正在卸载: %s (版本: %s)...\n', targetAddon.Name, targetAddon.Version);
        matlab.addons.uninstall(targetAddon.Identifier);
        disp('✅ 卸载完成。');
    else
        msg = sprintf('❌ 未找到名为 "%s" 的工具箱，请检查拼写是否完全一致。', toolboxName);
        disp(msg);
    end
end