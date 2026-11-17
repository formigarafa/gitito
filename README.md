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

## Requirements

- Ruby (version in `.ruby-version`)
- `git`, `curl` and an SSH server on the host
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
| `GITITO_SSH_ACCESS_URL` | Where the SSH host reaches the app to check access, `http://localhost:3000` by default |
| `GITITO_REPOSITORIES_ROOT` | Folder the git repositories are kept in, `storage/repositories/<environment>` by default |
| `GITITO_SSH_USER` | SSH user shown in clone URLs |
| `GITITO_SSH_HOST` | SSH host shown in clone URLs |
| `GITITO_WEB_HOST` | Host used for links in emails |
| `GITITO_MAILER_SENDER` | Sender address for emails |

## How SSH access works

Each registered key becomes a line in the authorized keys file with a forced
command, `script/ssh-command-proxy.sh`, which is told which key was used.
Users can run git commands but never get a shell.

For each connection the script sends the command it received to the running
app, at `GITITO_SSH_ACCESS_URL`, and the app answers what to run: a git
command on a repository the user of that key owns or collaborates on. The
script hands that answer to `git-shell`, which runs nothing but git commands,
inside the folder the repositories are kept in. Anything else is refused, the
same way whether the repository exists or not, and logged to
`log/ssh-command-proxy.log`. Git access needs the app to be running: when it
cannot be reached, every request is refused.

The script needs `curl`, and finds the address and a token for that question,
and the folder of the repositories, in
`storage/ssh-command-proxy.production.conf`. The app writes it along with
the authorized keys file. To rewrite both by hand, as after changing
`GITITO_SSH_ACCESS_URL`, `GITITO_REPOSITORIES_ROOT` or the secret key base, run
`bin/rails gitito:sync_ssh_access`. The Docker image does it on boot.

In production the file defaults to `~/.ssh/authorized_keys` of the user
running the app. Gitito keeps its keys in a block of that file, between a
`# BEGIN gitito keys` and a `# END gitito keys` line, and only rewrites that
block: keys you add outside of it are kept. Those keys get a normal shell as
that user, so it is still best to run the app as a dedicated user, such as
`gitito`. In development and test the file is written under `tmp/`.

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
file and reach the repositories on that volume, and the host must reach the
app at `GITITO_SSH_ACCESS_URL`.
