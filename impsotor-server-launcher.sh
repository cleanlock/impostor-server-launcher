#!/usr/bin/env bash

### BEGIN INIT INFO
# Provides: impostor-server-launcher
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Impostor Server Launcher
### END INIT INFO

################################################################
#                                                              #
#                   Impostor Server Launcher                   #
#                                                              #
#                   A simple script to launch                  #
#                 your Among Us Impostor Server                #
#                                                              #
################################################################

############
#  CONFIG  #
############

################################################################

SCREEN_NAME="impostor" # Set your screen name
USER="impostor" # Set user account
DIR_ROOT="/home/user/impostor" # Path to the Impostor Server directory
DAEMON_GAME="Impostor.Server" # Filename of the Impostor Server

################################################################

#####################
#  NO EDITS BEYOND  #
#     THIS LINE     #
#####################

################################################################
function start {
  if [ ! -d "$DIR_ROOT" ]; then echo "ERROR: \"${DIR_ROOT}\" is not a directory"; exit 1; fi
  if [ ! -x "$DIR_ROOT/$DAEMON_GAME" ]
  then
    echo "NOTICE: $DIR_ROOT/$DAEMON_GAME does not exist or is not executable."
    create
  fi
  
  if status; then echo "$SCREEN_NAME is already running"; exit 1; fi

  # Start game
  echo "Starting Among Us Server..."
  cd "$DIR_ROOT"
  rm -f screenlog.*
  screen -L -AmdS ${SCREEN_NAME} ./${DAEMON_GAME} ${PARAM_START}
}

function stop {
  if ! status; then echo "$SCREEN_NAME could not be found. Probably not running."; exit 1; fi
  if [ $(id -u) -eq 0 ]
  then
    tmp=$(su - ${USER} -c "screen -ls" | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}')
    su - ${USER} -c "screen -r $tmp -X quit ; rm -f '$DIR_ROOT/screenlog.*'"
  else
    screen -r $(screen -ls | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}') -X quit
    rm -f "$DIR_ROOT/screenlog.*"
  fi
}

function status {
  if [ $(id -u) -eq 0 ]
  then
    su - ${USER} -c "screen -ls" | grep [.]${SCREEN_NAME}[[:space:]] > /dev/null
  else
    screen -ls | grep [.]${SCREEN_NAME}[[:space:]] > /dev/null
  fi
}

function console {
  if ! status; then echo "$SCREEN_NAME could not be found. Probably not running."; exit 1; fi

  if [ $(id -u) -eq 0 ]
  then
    tmp=$(su - ${USER} -c "screen -ls" | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}')
    su - ${USER} -c "script -q -c 'screen -r $tmp' /dev/null"
  else
    screen -r $(screen -ls | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}')
  fi
}

function usage {
  echo "Usage: service amongus {start|stop|status|restart|console}"
  echo "On console, press CTRL+A then D to stop the screen without stopping the server."
}

### BEGIN ###

# Check required packages
PATH=/bin:/usr/bin:/sbin:/usr/sbin
if ! type awk > /dev/null 2>&1; then echo "ERROR: You need awk for this script (try apt-get install awk)"; exit 1; fi
if ! type wget > /dev/null 2>&1; then echo "ERROR: You need wget for this script (try apt-get install wget)"; exit 1; fi
if ! type tar > /dev/null 2>&1; then echo "ERROR: You need tar for this script (try apt-get install tar)"; exit 1; fi

# Detects if unbuffer command is available for 32 bit distributions only.
ARCH=$(uname -m)
if [ $(command -v stdbuf) ] && [ "${ARCH}" != "x86_64" ]; then
  UNBUFFER="stdbuf -i0 -o0 -e0"
fi

case "$1" in

  start)
    echo "Starting $SCREEN_NAME..."
    start
    sleep 5
    echo "$SCREEN_NAME started successfully"
  ;;

  stop)
    echo "Stopping $SCREEN_NAME..."
    stop
    sleep 5
    echo "$SCREEN_NAME stopped successfully"
  ;;

  restart)
    echo "Restarting $SCREEN_NAME..."
    status && stop
    sleep 5
    start
    sleep 5
    echo "$SCREEN_NAME restarted successfully"
  ;;

  status)
    if status
    then echo "$SCREEN_NAME is UP"
    else echo "$SCREEN_NAME is DOWN"
    fi
  ;;

  console)
    echo "Open console on $SCREEN_NAME..."
    console
  ;;

  update)
    echo "Updating $SCREEN_NAME..."
    update
  ;;

  create)
    echo "Creating $SCREEN_NAME..."
    create
  ;;

  *)
    usage
    exit 1
  ;;

esac

exit 0
