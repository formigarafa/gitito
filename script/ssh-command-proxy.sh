#!/bin/sh

# Forced command of every key in the authorized keys file:
#
#   ssh-command-proxy.sh <user credential id>
#
# Runs the git command the client asked for ($SSH_ORIGINAL_COMMAND), but only
# after the app confirms that credential can reach the repository. The app
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

# "git upload-pack 'owner/name.git'" is the same as "git-upload-pack 'owner/name.git'".
COMMAND=$SSH_ORIGINAL_COMMAND
case "$COMMAND" in
  "git "*) COMMAND="git-${COMMAND#git }" ;;
esac

VERB=${COMMAND%% *}
REPOSITORY=${COMMAND#* }

case "$VERB" in
  git-upload-pack|git-receive-pack|git-upload-archive) ;;
  *) deny "Command not allowed" ;;
esac

# Git quotes the path, and ssh:// URLs send it with a leading slash.
case "$REPOSITORY" in
  "'"*"'") REPOSITORY=${REPOSITORY#\'}; REPOSITORY=${REPOSITORY%\'} ;;
esac
REPOSITORY=${REPOSITORY#/}
case "$REPOSITORY" in
  *.git) ;;
  *) REPOSITORY=$REPOSITORY.git ;;
esac

# Nothing but an <owner>/<name>.git path, so it is safe to hand over to
# git-shell.
case "$REPOSITORY" in
  *[!A-Za-z0-9._/-]*|*/*/*|/*|*/.git) deny "Repository not found or access denied" ;;
  */*.git) ;;
  *) deny "Repository not found or access denied" ;;
esac

ACCESS_URL=$(sed -n 's/^url=//p' "$CONFIG_FILE" 2>/dev/null)
ACCESS_TOKEN=$(sed -n 's/^token=//p' "$CONFIG_FILE" 2>/dev/null)
REPOSITORIES_PATH=$(sed -n 's/^repositories=//p' "$CONFIG_FILE" 2>/dev/null)
[ -n "$ACCESS_URL" ] && [ -n "$ACCESS_TOKEN" ] && [ -n "$REPOSITORIES_PATH" ] || deny "Access check not configured"

# The token goes through stdin to stay out of the process list. The app
# answers 204 when the credential can reach the repository.
STATUS=$(printf 'header = "Authorization: Bearer %s"\n' "$ACCESS_TOKEN" |
  curl --config - --silent --get --max-time 10 --output /dev/null --write-out '%{http_code}' \
    --data-urlencode "credential_id=$CREDENTIAL_ID" --data-urlencode "repository=$REPOSITORY" \
    "$ACCESS_URL" 2>/dev/null)

case "$STATUS" in
  204) ;;
  403) deny "Repository not found or access denied" ;;
  *) deny "Access check failed (${STATUS:-no answer})" ;;
esac

log "$VERB $REPOSITORY"
cd "$REPOSITORIES_PATH" || exit 1
exec git-shell -c "$VERB '$REPOSITORY'"
