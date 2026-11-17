# Gitito

Self-hosted private git repositories, for when GitLab or Gitea is more than
you need.

Gitito is a small Rails app that sits next to your server's own `sshd` and
`git`. Through the web UI, users register their SSH public keys, create
repositories and choose collaborators. Cloning, pushing and pulling happen
over plain SSH:

```sh
git clone gitito@example.com:alice/project.git
```

It only manages keys, repositories and access. There is no code browser,
issues or pull requests.

## Known issues

SSH access is not yet checked per repository: any user with a registered key
can reach any repository whose address they know. Only run it for people you
trust.

## Requirements

- Ruby (version in `.ruby-version`)
- `git` and an SSH server on the host
- A database. It comes configured for SQLite in every environment, production
  included, so there is nothing else to install. Any database Rails supports
  works if you prefer another.

## Setup

```sh
bin/setup   # installs gems, prepares the database and starts the server
```

Pass `--skip-server` to only set up, and use `bin/dev` to start the server
later.

## Configuration

Settings live in `config/gitito.yml` and can be overridden with environment
variables:

| Variable | Purpose |
| --- | --- |
| `GITITO_SSH_AUTHORIZED_KEYS_FILE` | File the app writes users' public keys to |
| `GITITO_SSH_USER` | SSH user shown in clone URLs |
| `GITITO_SSH_HOST` | SSH host shown in clone URLs |
| `GITITO_WEB_HOST` | Host used for links in emails |
| `GITITO_MAILER_SENDER` | Sender address for emails |

## How SSH access works

Each registered key becomes a line in the authorized keys file with a forced
command, `script/ssh-command-proxy.sh`, which hands the git command to
`git-shell` inside `storage/repositories/production`. Users can run git
commands but never get a shell.

In production the file defaults to `~/.ssh/authorized_keys` of the user
running the app, and **its contents are replaced**. Run the app as a dedicated
user, such as `gitito`. In development and test the file is written under
`tmp/`.

## Tests

```sh
bin/rails test   # test suite; COVERAGE=1 writes a report to coverage/
bin/ci           # what GitHub Actions runs: RuboCop, security audits, tests
```

## Deployment

The stock Rails `Dockerfile` and [Kamal](https://kamal-deploy.org) setup are
included: set the `GITITO_*` variables in `config/deploy.yml` and run
`bin/kamal setup`.

Everything stateful lives in `storage/` (databases, repositories and the
authorized keys file), so keep it on a persistent volume. The container only
serves the web app; the host's `sshd` must be able to read the authorized keys
file and reach the repositories on that volume.
