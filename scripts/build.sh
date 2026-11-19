#!/usr/bin/env bash
# Build images locally as <image>:<version>.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY_RUN=0
PLATFORM=linux/amd64
PULL=0
NO_CACHE=0
VERSION=
WANT=()

usage() {
  cat <<'EOF'
usage: scripts/build.sh [options] [image...]

Builds every directory with a Dockerfile, or only the named images.
The image is tagged <image>:<version> for local use.

options:
  -r, --release N    release number to use instead of RELEASE
  -V, --version V    version to use instead of the current UTC time
  -p, --platform P   target platform (default: linux/amd64)
      --pull         always pull the base image
      --no-cache     build without cache
      --dry-run      print the commands without running them
  -h, --help         show this help
EOF
}

while (($#)); do
  case $1 in
    -r | --release) RELEASE_NUMBER=${2:?"-r needs a number"}; shift 2 ;;
    -V | --version) VERSION=${2:?"-V needs a version"}; shift 2 ;;
    -p | --platform) PLATFORM=${2:?"-p needs a platform"}; shift 2 ;;
    --pull) PULL=1; shift ;;
    --no-cache) NO_CACHE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; WANT=("$@"); break ;;
    -*) die "unknown option: $1" ;;
    *) WANT+=("$1"); shift ;;
  esac
done

need docker
VERSION=${VERSION:-$(current_version)}
check_version "$VERSION"
collect_images images ${WANT[@]+"${WANT[@]}"}

for image in "${images[@]}"; do
  info "build $image:$VERSION ($PLATFORM)"
  cmd=(docker buildx build --load --platform "$PLATFORM" --file "$ROOT/$image/Dockerfile" --tag "$image:$VERSION")
  if ((PULL)); then cmd+=(--pull); fi
  if ((NO_CACHE)); then cmd+=(--no-cache); fi
  cmd+=("$ROOT/$image")
  run "${cmd[@]}"
done
