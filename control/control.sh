#!/bin/bash

SCRIPT_PATH_REL=`dirname "$0"`
SCRIPT_PATH_ABS=`readlink -f "$SCRIPT_PATH_REL"`
# Options
BASE_PATH=`readlink -f "$SCRIPT_PATH_ABS/../"`
SUPERVISE_PID_FILE="$SCRIPT_PATH_ABS/supervise.pid"
PID_FILE="$SCRIPT_PATH_ABS/application.pid"
# Yes | No
CHECK_STOP="Yes"

if [ -e "$SCRIPT_PATH_ABS/control.conf" ]; then
    source "$SCRIPT_PATH_ABS/control.conf"
elif [ -e "$SCRIPT_PATH_ABS/conf/control.conf" ]; then
    source "$SCRIPT_PATH_ABS/conf/control.conf"
fi

export LD_LIBRARY_PATH="$SERVICE_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"
CMD_INIT="$SERVICE_INIT_CMD"
CMD_START="./supervise $SERVICE_START_CMD"
CMD_STOP="$SERVICE_STOP_CMD"
CMD_RELOAD="$SERVICE_RELOAD_CMD"
CMD_TEST="$SERVICE_TEST_CMD"

do_stop_supervise()
{
    ret=0;
    
    if [ -e "$SUPERVISE_PID_FILE" ]; then
        kill -9 `cat "$SUPERVISE_PID_FILE"`
        ret=$?
    else 
        echo "SUPERVISE_PID_FILE ($SUPERVISE_PID_FILE) not found."
        ret=1
    fi
   
    return $ret

}

do_fetch_next() 
{
    echo "fetch: begin."
    echo "NOT SUPPORTED NOW"
    echo "fetch: end."

    return 1
}

do_init() 
{
    echo "init: begin."
    $CMD_INIT
    echo "init: end."

    return 1
}

do_update() 
{
	cd $SCRIPT_PATH_ABS
    TMP_BIN_GZ="./bin.update.gz"
    if [ "$1" == "debug" -a -n "$SERVICE_DEBUG_PACKAGE" ]; then
        echo "update: download $SERVICE_DEBUG_PACKAGE"
        curl -L -C - -o $TMP_BIN_GZ "$SERVICE_DEBUG_PACKAGE"
    elif [ -n "$SERVICE_PACKAGE" ]; then
        echo "update: download $SERVICE_PACKAGE"
        curl -L -C - -o $TMP_BIN_GZ "$SERVICE_PACKAGE"
    else
        echo "update: no package"
        echo "update: end."
        cd - > /dev/null
        return 0
    fi

    if [ "$?" == "0" ]; then 
        echo "update: replace"
        SAME=`md5sum "$SERVICE_BIN" "$SERVICE_BIN".prev | awk '{print $1}' | uniq | wc -l`
        if [ "$SAME" != "1" -o ! -f "$SERVICE_BIN".prev ]; then
            mv "$SERVICE_BIN" "$SERVICE_BIN".prev
        fi
        gunzip -c $TMP_BIN_GZ > "$SERVICE_BIN" && chmod +x "$SERVICE_BIN" && rm -f $TMP_BIN_GZ
        if [ "$?" != "0" ]; then
            echo "fail to unpack, rollback"
            cp "$SERVICE_BIN".prev "$SERVICE_BIN"
        fi
    else
        echo "update: fail to download"
    fi

    echo "update: end."
    cd - > /dev/null
    return 1
}

do_rollback() 
{
	cd $SCRIPT_PATH_ABS
    echo "rollback: begin."

    if [ -f "$SERVICE_BIN".prev ]; then 
        echo "rollback: replace"
        rm -f "$SERVICE_BIN" && cp "$SERVICE_BIN".prev "$SERVICE_BIN" && chmod +x "$SERVICE_BIN"
    else
        echo "rollback: no previous binary found"
    fi

    echo "rollback: end."

    cd - > /dev/null
    return 1
}

do_start() 
{
    echo "start: begin."
	cd $SCRIPT_PATH_ABS
	
    do_check
    ret=$?
    if [ $ret -eq 0 ]; then
        echo "start: already started."
        return 0
    fi    
        
    $CMD_START

	cd - >/dev/null

	sleep 1
	for ((i = 0; i<10; ++i)); do
		do_check
		ret=$?
		if [ $ret -eq 0 ]; then
			echo "start: succ end."
			return 0
		fi
		sleep 3
	done
    echo "start: fail end."

    return 1
}

do_fstart()
{
    echo "fstart: begin."
    rm -f "$SUPERVISE_PID_FILE"
    rm -f "$PID_FILE"

    do_start

    echo "fstart: end."
}

do_stop() 
{
    echo "stop: begin."
    ret=0;
    
    cd $SCRIPT_PATH_ABS	
    
    do_stop_supervise
    
    $CMD_STOP

    cd - >/dev/null
    
    if [ "$CHECK_STOP" == "Yes" ]; 
    then
        for ((i = 0; i<10; ++i)); do
            do_check
            ret=$?
            if [ $ret -eq 1 ] || [ $ret -eq 2 ]; then
                echo "stop: succ end."
                rm -f "$PID_FILE"
                return 0
            fi
            sleep 3
        done
        echo "stop: fail end."
        echo "TIPS: 'control.sh kill' can stop the service by 'kill -9'"
    fi  
    return 1
}

do_reload() 
{
    echo "reload: beign."

    cd $SCRIPT_PATH_ABS
    $CMD_RELOAD

    cd - >/dev/null

    echo "reload: end."
    return 1
}

do_restart() 
{
    do_stop
    sleep 0.2
    do_start
}


do_check() 
{
    echo -n "check: "
    pid=`cat $PID_FILE 2>/dev/null`
    if [ -z "$pid" ]; then
        echo "process not found. (No PID File)"
        return 2
    elif [ -d "/proc/$pid" ]; then
        echo process $pid is running.
        return 0
    else 
        echo process not found.
        return 1
    fi

    return $pid_check
}

do_kill() 
{
    echo "kill: begin."
    ret=0;
   
    do_stop_supervise
    
    if [ -e "$PID_FILE" ]; then
        kill -9 `cat "$PID_FILE"`
        ret=$?
    else 
        echo "kill: PID_FILE ($PID_FILE) not found."
        ret=1
    fi
   
    echo "kill: end."
    return $ret
}

do_test() 
{
    echo "test: begin."
    ret=0;
 
    $CMD_TEST
  
    echo "test: end."
    return $ret
}


###############################################################################

op=$1
shift 1

case $op in
(fetch) 
    do_fetch_next $*
    exit $?
    ;;
(init) 
    do_init $*
    exit $?
    ;;
(update)
    do_update $*
    exit $?
    ;;
(rollback)
    do_rollback $*
    exit $?
    ;;
(start) 
    do_start $*
    exit $?
    ;;
(fstart)
    do_fstart $*
    exit $?
    ;;
(stop)
    do_stop $*
    exit $?
    ;;
(reload)
    do_reload $*
    exit $?
    ;;
(restart)
    do_restart $*
    exit $?
    ;;
(check)
    do_check $*
    exit $?
    ;;
(kill)
    do_kill $*
    exit $?
    ;;
(test)
    do_test $*
    exit $?
    ;;
esac

echo "$op is not supported. (TIPS: Supported cmds: init fetch update rollback start stop reload restart kill check test)"

