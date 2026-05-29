classdef proxy
    methods (Static)
        function setJavaProxy(opts)
            % setJavaProxy 设置 Java 全局代理
            % 用法:
            %   proxy.setJavaProxy('localhost', 7890)
            arguments
                opts.host = 'localhost';
                opts.port = 7890;
            end
            host = opts.host;
            port = opts.port;
            java.lang.System.setProperty('http.proxyHost', char(host));
            java.lang.System.setProperty('http.proxyPort', char(num2str(port)));
            java.lang.System.setProperty('https.proxyHost', char(host));
            java.lang.System.setProperty('https.proxyPort', char(num2str(port)));
            % 如果需要通过 SOCKS 代理，请取消下一行注释并设置相应属性
            % java.lang.System.setProperty('socksProxyHost', char(host));
            % java.lang.System.setProperty('socksProxyPort', char(num2str(port)));
        end

        function clearJavaProxy()
            % clearJavaProxy 清除 Java 代理相关系统属性
            props = {'http.proxyHost','http.proxyPort','https.proxyHost','https.proxyPort', ...
                'socksProxyHost','socksProxyPort','http.proxyUser','http.proxyPassword'};
            for k = 1:numel(props)
                java.lang.System.clearProperty(props{k});
            end
        end
    end
end