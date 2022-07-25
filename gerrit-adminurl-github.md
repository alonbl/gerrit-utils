# Gerrit adminUrl for GitHub

The adminUrl is used to create and delete GitHub projects.

## Configuration

Create a user with active shell and distinct home directory.

### Script Configuration

```sh
GITHUB_CREATE_URL="https://api.github.com/orgs/@ORG@/repos"
GITHUB_CREATE_URL="https://api.github.com/@OWNER@/repos"
GITHUB_REPO_URL="https://api.github.com/repos/@OWNER@"
GITHUB_TOKEN="..."
GITHUB_PROJECT_CONVERT="s#/#_#g"
```

### OpenSSH Configuration

Use the following in `~/.ssh/authorized_keys`:

```
command="/path/gerrit-adminurl-github.sh --config=\"${HOME}\"/gerrit-adminurl-github.conf" ssh-rsa ...
```
