#!/usr/bin/env bash
# Point <image>-latest at the current month tag.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY_RUN=0
VERSION=
WANT=()

usage() {
  cat <<'EOF'
usage: scripts/latest.sh [options] [image...]

Copies the month tag R.YY.MM onto <repo>:<image>-latest. Nothing is rebuilt.
The month comes from the current UTC version unless -V is given, so run
latest.sh after publishing the build it should point at.

options:
      --repo REPO    registry repository (default: from the origin remote)
  -r, --release N    release number to use instead of RELEASE
  -V, --version V    version that names the month tag
      --dry-run      print the commands without running them
  -h, --help         show this help
EOF
}

while (($#)); do
  case $1 in
    --repo) IMAGE_REPO=${2:?"--repo needs a repository"}; shift 2 ;;
    -r | --release) RELEASE_NUMBER=${2:?"-r needs a number"}; shift 2 ;;
    -V | --version) VERSION=${2:?"-V needs a version"}; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; WANT=("$@"); break ;;
    -*) die "unknown option: $1" ;;
    *) WANT+=("$1"); shift ;;
  esac
done

need docker
VERSION=${VERSION:-$(current_version)}
month=$(month_of "$VERSION")
repo=$(image_repo)
collect_images images ${WANT[@]+"${WANT[@]}"}

for image in "${images[@]}"; do
  info "latest $repo:$image-latest -> $image-$month"
  run docker buildx imagetools create \
    --tag "$repo:$image-latest" \
    "$repo:$image-$month"
done
