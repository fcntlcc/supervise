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
    echo "NOT SUPPORTED NOW"
    echo "init: end."

    return 1
}

do_update() 
{
    echo "update: begin."
    echo "NOT SUPPORTED NOW"
    echo "update: end."

    return 1
}

do_rollback() 
{
    echo "rollback: begin."
    echo "NOT SUPPORTED NOW"
    echo "rollback: end."

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
        echo "fail end. $PID_FILE not found"
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

