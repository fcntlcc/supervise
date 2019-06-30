/**
 * supervise 
 *
 * 将前台执行的应用程序封装为服务(守护进程).
 *
 * supervise自身以守护进程启动, 应用以supervise的子进程启动. 
 * supervise监控应用进程, 在应用退出时, 再次启动应用进程.
 *
 */

#include <unistd.h>
#include <stdint.h>
#include <stdio.h>

/****************************************************************************/

/**
 * supervise控制信息
 */
struct supervise_control_info_t {
    pid_t supervise_pid;
    pid_t application_pid;

    /** 应用重启计数, 初次启动不计 */
    int restart_count; 

    /** 应用重启限制, 例如restart_limit = 2, 
     *   则重启2次后不再继续重启 (加上初次启动, 一共启动3次)
     */
    int restart_limit; 

    /** supervise进程pid记录文件
     * 默认值: ./supervise.pid, 可通过环境变量 SUPCONF_SUPERVISE_PID_FILE 设置
     */
    const char *supervise_pid_file;

    /** 应用进程pid记录文件
     * 默认值: ./application.pid, 可通过环境变量 SUPCONF_APPLICATION_PID_FILE 设置
     */
    const char *application_pid_file;
   
    /** supervise日志文件
     * 默认值: ./supervise.log, 可通过环境变量 SUPCONF_SUPERVISE_LOG_FILE 设置
     */
    const char *supervise_log_file;
    
    /** 应用标准输出重定向到指定文件
     * 默认值: /dev/null, 可通过环境变量 SUPCONF_APPLICATION_STDOUT_FILE 设置
     */
    const char *application_stdout_file;
    
    /** 应用标准错误输出重定向到指定文件
     * 默认值: /dev/null, 可通过环境变量 SUPCONF_APPLICATION_STDERR_FILE 设置
     */
    const char *application_stderr_file;

    int supervise_log_fd;
    int application_stdout_fd;
    int application_stderr_fd;

    /**
     * supervise自身是否在前台执行
     *
     * 非0表示在前台执行, 0表示以守护进程执行
     *
     * 默认值: 0, 可通过环境变量 SUPCONF_FOREGROUND_SUPERVISE 设置
     */
    int option_foreground_supervise;

    /**
     * 应用被重启前回调
     *
     * 默认值: 空指针 (不回调), 可通过环境变量 SUPCONF_HOOK_BEFORE_RESTART 设置
     */
    const char *hook_before_restart;

    /**
     * 应用重启达到限制后, 再次退出(不会再被重启)时回调
     *
     * 默认值: 空指针 (不回调), 可通过环境变量 SUPCONF_HOOK_REACH_RESTART_LIMIT 设置
     */
    const char *hook_reach_restart_limit;
};

/* 全局控制信息 */
static struct supervise_control_info_t g_control;
/****************************************************************************/

/** 初始化控制信息: 设置默认值, 从环境变量获取设置值 */
static int init_supervise_control_info(struct supervise_control_info_t *ctl_info);

/** 初始化日志 */
static int init_supervise_logs(const struct supervise_control_info_t *ctl_info);

/****************************************************************************/

static int init_supervise_control_info(struct supervise_control_info_t *ctl_info) {
    //TODO
    return -1;
}

static int init_supervise_logs(const struct supervise_control_info_t *ctl_info) {
    //TODO
    return -1;
}

/****************************************************************************/
int main(int argc, char *argv[]) {
    
    if (0 != init_supervise_control_info(&g_control) ) {
        //TODO
    }

    //TODO

    return -1;
}

