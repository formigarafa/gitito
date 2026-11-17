#!/bin/sh

# Forced command of every key in the authorized keys file:
#
#   ssh-command-proxy.sh <user credential id>
#
# Asks the app what that credential should run for the command the client
# sent ($SSH_ORIGINAL_COMMAND), and runs the answer: a git server command on
# a repository, or nothing. The app is the one that understands the command
# (see SshAccess), so the script and the app are deployed together. The app
# writes where to ask, the token to ask with, and where it keeps the
# repositories, to the config file:
#
#   url=https://example.com/internal/ssh_access
#   token=<secret>
#   repositories=/path/to/repositories

CREDENTIAL_ID=$1
SCRIPT_PATH="$( cd "$( dirname "$0" )" && pwd )"
APP_PATH=$(dirname "$SCRIPT_PATH")
LOG_FILE=$APP_PATH/log/ssh-command-proxy.log
CONFIG_FILE=$APP_PATH/storage/ssh-command-proxy.production.conf

log() {
  echo "[credential ${CREDENTIAL_ID:-?}] $1" >> "$LOG_FILE"
}

deny() {
  log "DENIED ($1): $SSH_ORIGINAL_COMMAND"
  echo "$1. aborting..." >&2
  exit 1
}

[ -n "$SSH_ORIGINAL_COMMAND" ] || deny "No command received"
[ -n "$CREDENTIAL_ID" ] || deny "Key not recognised"

ACCESS_URL=$(sed -n 's/^url=//p' "$CONFIG_FILE" 2>/dev/null)
ACCESS_TOKEN=$(sed -n 's/^token=//p' "$CONFIG_FILE" 2>/dev/null)
REPOSITORIES_PATH=$(sed -n 's/^repositories=//p' "$CONFIG_FILE" 2>/dev/null)
[ -n "$ACCESS_URL" ] && [ -n "$ACCESS_TOKEN" ] && [ -n "$REPOSITORIES_PATH" ] || deny "Access check not configured"

# The token goes through stdin to stay out of the process list. The app
# answers in lines of name=value, and curl adds the status as the last one.
ANSWER=$(printf 'header = "Authorization: Bearer %s"\n' "$ACCESS_TOKEN" |
  curl --config - --silent --max-time 10 --write-out '\nstatus=%{http_code}\n' \
    --data-urlencode "credential_id=$CREDENTIAL_ID" --data-urlencode "command=$SSH_ORIGINAL_COMMAND" \
    "$ACCESS_URL" 2>/dev/null)

# The first value the app gave to a name.
answer() {
  printf '%s\n' "$ANSWER" | sed -n "s/^$1=//p" | sed -n 1p
}

STATUS=$(printf '%s\n' "$ANSWER" | sed -n 's/^status=//p' | sed -n '$p')

case "$STATUS" in
  200) ;;
  403)
    # Nothing but printable characters reaches the terminal of the client.
    MESSAGE=$(answer message | LC_ALL=C tr -cd ' -~')
    deny "${MESSAGE:-Access denied}"
    ;;
  *) deny "Access check failed (${STATUS:-no answer})" ;;
esac

VERB=$(answer verb)
REPOSITORY=$(answer repository)

# The app decides, and git-shell runs nothing but a git server command on one
# quoted path.
[ -n "$VERB" ] && [ -n "$REPOSITORY" ] || deny "Access check failed (unexpected answer)"

log "$VERB $REPOSITORY"
cd "$REPOSITORIES_PATH" || exit 1
exec git-shell -c "$VERB '$REPOSITORY'"
