#!/bin/sh

# $SSH_ORIGINAL_COMMAND
# $* 

SCRIPT_PATH="$( cd "$( dirname "$0" )" && pwd )"
LOG_PATH=$(dirname $SCRIPT_PATH)/log
LOG_FILE=$LOG_PATH/ssh-command-proxy.log
REPOSITORIES_PATH=$(dirname $SCRIPT_PATH)/db/users_repositories/production

cd "$REPOSITORIES_PATH"
if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
  echo $SSH_ORIGINAL_COMMAND >> $LOG_FILE
  exec git-shell -c "$SSH_ORIGINAL_COMMAND"
else
  echo "No command received." >> $LOG_FILE 
  echo "No command received. aborting..."
  exit 1;
fi


