# Gitito

Private git repository management with minimal server requirements.

Gitito works like GitHub or Gitorious: you register SSH public keys, create
repositories you can clone, push to and pull from, and add collaborators who
get access to them.

## Known issues

Other users can access everyone's repositories if they know the repository
addresses. This security check is not done yet.

## Requirements

- Ruby 4.0.9 (see `.ruby-version`)
- SQLite 3, used in every environment, including production
- `git` on the server, for `git-shell`

## Setup

```sh
bin/setup
```

This installs the gems, prepares the database and starts the server. Run
`bin/setup --skip-server` to skip starting it, and `bin/dev` to start the
server later.

## Configuration

Gitito's own settings live in `config/gitito.yml`. Each one can be set with an
environment variable:

| Variable | Purpose |
| --- | --- |
| `GITITO_SSH_AUTHORIZED_KEYS_FILE` | File the app writes users' public keys to |
| `GITITO_SSH_USER` | SSH user shown in clone URLs |
| `GITITO_SSH_HOST` | SSH host shown in clone URLs |
| `GITITO_WEB_HOST` | Host used for links in emails |
| `GITITO_MAILER_SENDER` | Sender address for emails |

Databases and the bare git repositories (`storage/repositories/<env>`) live in
`storage/`. In development and test, `authorized_keys` is written under `tmp/`.

## How SSH access works

Every key saved in the app becomes a line in the authorized keys file that
forces `script/ssh-command-proxy.sh`, which hands the git command to
`git-shell` inside `storage/repositories/production`. By default, production
writes `~/.ssh/authorized_keys` of the user running the app (and replaces its
contents), so run it as a dedicated SSH user such as `gitito`.

## Tests and CI

```sh
bin/rails test   # run the test suite
bin/ci           # setup, RuboCop, security audits, tests and seeds
```

`bin/ci` runs the steps in `config/ci.rb`. GitHub Actions runs the same checks.
Set `COVERAGE=1` to get a coverage report in `coverage/`.

## Deployment

The app ships with the default Rails setup: a production `Dockerfile` and
[Kamal](https://kamal-deploy.org) (`config/deploy.yml`, `bin/kamal`). Set the
`GITITO_*` variables in `config/deploy.yml`, then run `bin/kamal setup`. The
`storage/` directory is a persistent volume holding the databases, the
repositories and the authorized keys file.

The container serves the web app only. For git over SSH, the host's sshd must
read the authorized keys file and reach the repositories on the storage
volume.
