# 单机服务运维工具

## supervise

托管前台服务应用, 使其以守护进程模式运行. 同时监控其运行状态, 在被监控进程异常退出时, 自动重新拉起.

- 使用方法:
    - `supervise <path to app> [arguments of app]`

- 通过环境变量, 可以控制的内容:
    - `SUPCONF_SUPERVISE_PID_FILE`: supervise进程pid记录文件 (默认值: `./supervise.pid`)
    - `SUPCONF_APPLICATION_PID_FILE`: 应用进程pid记录文件 (默认值: `./application.pid`)
    - `SUPCONF_SUPERVISE_LOG_FILE`: supervise日志文件 (默认值: `./supervise.log`)
    - `SUPCONF_APPLICATION_STDOUT_FILE`: 应用标准输出重定向到指定文件 (默认值: `/dev/null`)
    - `SUPCONF_APPLICATION_STDERR_FILE`: 应用标准错误输出重定向到指定文件 (默认值: `/dev/null`)
    - `SUPCONF_FOREGROUND_SUPERVISE`: supervise自身是否在前台执行, 0表示非前台, 非0表示前台 (默认值: `0`)
    - `SUPCONF_RESTART_LIMIT`: 应用重启次数限制. 例如配置为2, 则应用最多执行3次. (默认值: `-1` 表示不限制)
    - `SUPCONF_HOOK_BEFORE_RESTART`: 应用被重启前回调执行的命令 (默认值: `无`)
    - `SUPCONF_HOOK_REACH_RESTART_LIMIT`: 应用重启次数达到限制后,最后一次退出后回调执行的命令 (默认值: `无`)

