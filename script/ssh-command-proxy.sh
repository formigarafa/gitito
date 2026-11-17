#!/bin/sh

# Forced command of every key in the authorized keys file:
#
#   ssh-command-proxy.sh <user credential id>
#
# Runs the git command the client asked for ($SSH_ORIGINAL_COMMAND), but only
# on a repository the access file lists for that credential. The app keeps the
# access file up to date, with one "<user credential id> <owner>/<name>.git"
# line for each repository each key can reach.

CREDENTIAL_ID=$1
SCRIPT_PATH="$( cd "$( dirname "$0" )" && pwd )"
APP_PATH=$(dirname "$SCRIPT_PATH")
LOG_FILE=$APP_PATH/log/ssh-command-proxy.log
REPOSITORIES_PATH=$APP_PATH/storage/repositories/production
ACCESS_FILE=$REPOSITORIES_PATH.access

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

# Nothing but what an <owner>/<name>.git path is made of, so it is safe to
# look up in the access file and to hand over to git-shell.
case "$REPOSITORY" in
  ""|*[!A-Za-z0-9._/-]*) deny "Repository not found or access denied" ;;
esac

grep -qxF -- "$CREDENTIAL_ID $REPOSITORY" "$ACCESS_FILE" 2>/dev/null ||
  deny "Repository not found or access denied"

log "$VERB $REPOSITORY"
cd "$REPOSITORIES_PATH" || exit 1
exec git-shell -c "$VERB '$REPOSITORY'"
