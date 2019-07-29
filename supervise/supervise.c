/**
 * supervise 
 *
 * 将前台执行的应用程序封装为服务(守护进程).
 *
 * supervise自身以守护进程启动, 应用以supervise的子进程启动. 
 * supervise监控应用进程, 在应用退出时, 再次启动应用进程.
 *
 */
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>

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
     * 默认值: -1 (无限制), 可通过环境变量 SUPCONF_RESTART_LIMIT 设置
     */
    int restart_limit; 

    /** supervise进程锁文件
     * 默认值: ./supervise.lock, 可通过环境变量 SUPCONF_SUPERVISE_LOCK_FILE 设置
     */
    const char *supervise_lock_file;

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

/** 设置默认值 */

/** 初始化日志 */
static int init_supervise_logs(struct supervise_control_info_t *ctl_info);

/** 读取配置: 字符串类型 */
static int init_read_str_conf_from_environment(const char **conf, 
        const char *conf_name, const char *default_value);

/** 读取配置: 整数 */
static int init_read_int_conf_from_environment(int *conf,
        const char *conf_name, int default_value);

/** 日志打印 */
static int print_log(struct supervise_control_info_t *ctl_info, const char *format, ...);

/****************************************************************************/

static int init_supervise_control_info(struct supervise_control_info_t *ctl_info) {
    // 重置pid和计数
    ctl_info->supervise_pid = getpid();
    ctl_info->application_pid = 0;
    ctl_info->restart_count = 0;
    ctl_info->restart_limit = -1;
    
    // 重置fd
    ctl_info->supervise_log_fd = -1;
    ctl_info->application_stdout_fd = -1;
    ctl_info->application_stderr_fd = -1;

    // 初始化日志
    init_read_str_conf_from_environment(&ctl_info->supervise_log_file, "SUPCONF_SUPERVISE_LOG_FILE", "./supervise.log");
    init_supervise_logs(ctl_info);

    // 初始化配置
    

    // 初始化其它

    //TODO
    return -1;
}

static int init_supervise_logs(struct supervise_control_info_t *ctl_info) {
    if (ctl_info->supervise_log_file == NULL) {
        ctl_info->supervise_log_fd = -1;
        return 0;
    }

    ctl_info->supervise_log_fd = open(ctl_info->supervise_log_file,
            O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);

    if (ctl_info->supervise_log_fd == -1) {
        fprintf(stderr, "Fail to open log file [%s]. [errno: %d, %s]\n",
            ctl_info->supervise_log_file, errno, strerror(errno) );
        return 0;
    }

    print_log(ctl_info, "Supervise Started.");
    
    return 1;
}

static int init_read_str_conf_from_environment(const char **conf, 
        const char *conf_name, const char *default_value) {
    if (conf_name != NULL) {
        *conf = getenv(conf_name);
        if (*conf != NULL) {
            return 1;
        }
    }

    *conf = default_value;
    return 0;
}

static int init_read_int_conf_from_environment(int *conf,
        const char *conf_name, int default_value) {
    const char *str_value = NULL;
    init_read_str_conf_from_environment(&str_value, conf_name, NULL);

    if (str_value != NULL) {
        *conf = strtol(str_value, NULL, 10);
        return 1;
    }

    *conf = default_value;
    return 0;
}


static int print_log(struct supervise_control_info_t *ctl_info, const char *format, ...) {
    struct timespec ts;
    struct tm       now;
    clock_gettime(CLOCK_REALTIME, &ts);
    localtime_r(&ts.tv_sec, &now);

    char log_cont_buffer[1024 * 1];
    char log_line_buffer[1024 * 2];
    va_list ap;
    va_start(ap, format);
    int log_cont_len = vsnprintf(log_cont_buffer, sizeof(log_cont_buffer), format, ap);
    if (log_cont_len < 0 || log_cont_len >= sizeof(log_cont_buffer) ) {
        log_cont_buffer[sizeof(log_cont_buffer) - 1] = 0;
    }

    int log_line_len = snprintf(log_line_buffer, sizeof(log_line_buffer), 
            "%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%.6ld %d->%d %d:%d %s\n",
            now.tm_year + 1900, now.tm_mon + 1, now.tm_mday,
            now.tm_hour, now.tm_min, now.tm_sec, ts.tv_nsec/1000,
            ctl_info->supervise_pid, ctl_info->application_pid,
            ctl_info->restart_count, ctl_info->restart_limit,
            log_cont_buffer
            );
    if (log_line_len < 0 || log_line_len >= sizeof(log_line_buffer) ) {
        log_line_buffer[sizeof(log_line_buffer) - 1] = 0;
        log_line_len = sizeof(log_line_buffer) - 1;
    }

    write(ctl_info->supervise_log_fd, log_line_buffer, log_line_len);

    return 0;
}


/****************************************************************************/
int main(int argc, char *argv[]) {
    
    if (0 != init_supervise_control_info(&g_control) ) {
        //TODO
    }

    //TODO

    return -1;
}

