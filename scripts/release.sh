#!/usr/bin/env bash
# Start a release: bump RELEASE and tag the commit.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY_RUN=0
COMMIT=1
KIND=release
IMAGE=all
BODY=
RELEASE=
VERSION=

usage() {
  cat <<'EOF'
usage: scripts/release.sh -r N [options]

Writes N to RELEASE, commits it, and tags the commit release/N with the
subject release-tag(<kind>, <image>, <release>) and an optional changelog.

options:
  -r, --release N      release number (required)
  -t, --tag KIND       kind in the tag subject (default: release)
      --image NAME     image in the tag subject (default: all)
  -m, --message TEXT   changelog text for the tag body
      --changelog FILE read the changelog from a file
      --no-commit      leave RELEASE uncommitted
  -V, --version V      version in the tag subject (default: current UTC time)
      --dry-run        print the commands without running them
  -h, --help           show this help

Example:
  scripts/release.sh -r 1 -m $'CHANGELOG:\n\n- add tmux'
EOF
}

while (($#)); do
  case $1 in
    -r | --release) RELEASE=${2:?"-r needs a number"}; shift 2 ;;
    -t | --tag) KIND=${2:?"-t needs a kind"}; shift 2 ;;
    --image) IMAGE=${2:?"--image needs a name"}; shift 2 ;;
    -m | --message) BODY=${2:?"-m needs a text"}; shift 2 ;;
    --changelog) BODY=$(cat "${2:?"--changelog needs a file"}"); shift 2 ;;
    --no-commit) COMMIT=0; shift ;;
    -V | --version) VERSION=${2:?"-V needs a version"}; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -n $RELEASE ]] || die '-r <release> is required'
[[ $RELEASE =~ ^[0-9]+$ ]] || die "release must be a number, got '$RELEASE'"
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || die 'not a git repository'

RELEASE_NUMBER=$RELEASE
VERSION=${VERSION:-$(current_version)}
tag="release/$RELEASE"

git -C "$ROOT" rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"

info "release $RELEASE -> $VERSION"

if ((DRY_RUN)); then
  info "would write $RELEASE to RELEASE"
else
  printf '%s\n' "$RELEASE" >"$ROOT/RELEASE"
fi

if ((COMMIT)) && ((!DRY_RUN)); then
  git -C "$ROOT" add RELEASE
  if ! git -C "$ROOT" diff --cached --quiet -- RELEASE; then
    git -C "$ROOT" commit -m "release $RELEASE" -- RELEASE
  fi
fi

subject="release-tag($KIND, $IMAGE, $VERSION)"
if [[ -n $BODY ]]; then
  run git -C "$ROOT" tag -a "$tag" -m "$subject" -m "$BODY"
else
  run git -C "$ROOT" tag -a "$tag" -m "$subject"
fi

info "tagged $tag"
