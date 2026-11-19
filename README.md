# coder-images

Workspace images for Coder, built from this repository and published to GitHub
Container Registry.

## Images

| Image  | Base                               | Adds                                                        |
| ------ | ---------------------------------- | ----------------------------------------------------------- |
| `base` | `codercom/enterprise-base:ubuntu`  | curl, wget, ripgrep, jq, fzf, nano, vim, tmux               |

Each image is a top-level directory with a `Dockerfile`. The scripts find images
by that file, so a new directory needs no extra configuration.

## Versions

Versions use `R.YY.MM.DD.HHMM` in UTC, for example `0.26.11.19.2241`. `R` is the
release number in `RELEASE`. The rest is the build time, so every published
version is unique.

Shorter names are moving tags, also in UTC:

| Tag                  | Example               | Meaning                          |
| -------------------- | --------------------- | -------------------------------- |
| `<image>-<version>`  | `base-0.26.11.19.2241`| one build, never moved           |
| `<image>-R.YY.MM`    | `base-0.26.11`        | newest build of that month       |
| `<image>-latest`     | `base-latest`         | follows the month tag            |
| `<image>-<kind>`     | `base-stable`         | optional channel tag             |

All tags live in one repository: `ghcr.io/atomxzr/coder-images`.

## Requirements

- Docker with buildx
- Git
- Bash 4 or newer (Git Bash on Windows)

## Quick start

```bash
bash scripts/build.sh base
bash scripts/publish.sh base -t stable
bash scripts/latest.sh
```

Pull the result:

```bash
docker pull ghcr.io/atomxzr/coder-images:base-latest
```

> [!NOTE]
> `latest` follows a month tag, not a raw build. Run `scripts/latest.sh` after
> publishing the build it should point at.

## Scripts

| Script               | Purpose                                         |
| -------------------- | ----------------------------------------------- |
| `scripts/version.sh` | Print the current version.                      |
| `scripts/build.sh`   | Build images locally.                           |
| `scripts/publish.sh` | Build and push images, move the month tag.      |
| `scripts/latest.sh`  | Point `latest` at the month tag.                |
| `scripts/release.sh` | Bump `RELEASE` and tag the commit.              |

Every script takes `-h`. Common flags:

| Flag                 | Scripts                             | Meaning                                  |
| -------------------- | ----------------------------------- | ---------------------------------------- |
| `-V, --version V`    | build, publish, latest, release     | Use `V` instead of the clock.            |
| `-r, --release N`    | all                                 | Use release `N` instead of `RELEASE`.    |
| `--dry-run`          | all                                 | Print the commands, change nothing.      |
| `-t, --tag KIND`     | publish, release                    | Channel tag, or kind in the tag subject. |
| `--repo REPO`        | publish, latest                     | Registry repository.                     |
| `-p, --platform P`   | build, publish                      | Target platform, default `linux/amd64`.  |

## Configuration

The repository defaults to `ghcr.io/<owner>/<repo>` from the origin remote. Set
`IMAGE_REPO` or pass `--repo` to use another registry.

Publishing logs in only when a token is present:

| Variable                        | Purpose                                  |
| ------------------------------- | ---------------------------------------- |
| `GHCR_TOKEN` or `GITHUB_TOKEN`  | Registry password.                       |
| `GHCR_USER`                     | Registry user, defaults to `GITHUB_ACTOR`.|

Without a token the scripts reuse the existing `docker login`.

## Adding an image

1. Create `rust/Dockerfile`.
2. Run `bash scripts/build.sh rust`.
3. Run `bash scripts/publish.sh rust`.

The scripts pick the directory up automatically. Pass
`-p linux/amd64,linux/arm64` when an image supports more platforms.

## Releases

`scripts/release.sh -r N` writes `N` to `RELEASE`, commits it, and tags the
commit `release/N`. The tag is annotated:

```
release-tag(release, all, 0.26.11.19.2241)

CHANGELOG:

- add tmux
```

The subject names the kind (`-t`), the image (`--image`), and the version. Add
the changelog with `-m` or `--changelog FILE`:

```bash
bash scripts/release.sh -r 1 -m $'CHANGELOG:\n\n- add tmux'
```

The release tag publishes nothing by itself. CI publishes on `release/*` tags,
and a manual run publishes on demand.

> [!IMPORTANT]
> Publish before you release, or publish again after the bump. Builds made with
> the old `RELEASE` keep the old `R`.

## Continuous integration

`.github/workflows/publish.yml` publishes on `release/*` tags and on manual
runs. A manual run takes a kind, a release number, and a list of images.

The workflow logs in with `GITHUB_TOKEN` and needs `packages: write`.
