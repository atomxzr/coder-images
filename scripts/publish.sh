#!/usr/bin/env bash
# Build and push images to a registry.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY_RUN=0
PLATFORM=linux/amd64
KIND=
VERSION=
WANT=()

usage() {
  cat <<'EOF'
usage: scripts/publish.sh [options] [image...]

Pushes each image as <repo>:<image>-<version> and moves the month tag
<repo>:<image>-R.YY.MM. The repository defaults to ghcr.io/<owner>/<repo>
from the origin remote; set IMAGE_REPO or pass --repo to change it.

options:
  -t, --tag KIND     also move <repo>:<image>-<kind> (stable, nightly, ...)
      --repo REPO    registry repository, for example ghcr.io/me/images
  -r, --release N    release number to use instead of RELEASE
  -V, --version V    version to use instead of the current UTC time
  -p, --platform P   target platform (default: linux/amd64)
      --dry-run      print the commands without running them
  -h, --help         show this help

Login uses GHCR_TOKEN or GITHUB_TOKEN when set; otherwise the existing
docker login is reused. GHCR_USER (or GITHUB_ACTOR) names the registry user.
EOF
}

while (($#)); do
  case $1 in
    -t | --tag) KIND=${2:?"-t needs a kind"}; shift 2 ;;
    --repo) IMAGE_REPO=${2:?"--repo needs a repository"}; shift 2 ;;
    -r | --release) RELEASE_NUMBER=${2:?"-r needs a number"}; shift 2 ;;
    -V | --version) VERSION=${2:?"-V needs a version"}; shift 2 ;;
    -p | --platform) PLATFORM=${2:?"-p needs a platform"}; shift 2 ;;
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
month=$(month_of "$VERSION")
repo=$(image_repo)
collect_images images ${WANT[@]+"${WANT[@]}"}

login() {
  local token=${GHCR_TOKEN:-${GITHUB_TOKEN:-}}
  if [[ -z $token ]]; then
    info 'no GHCR_TOKEN or GITHUB_TOKEN set; using the existing docker login'
    return
  fi
  local host=${repo%%/*}
  local user=${GHCR_USER:-${GITHUB_ACTOR:-token}}
  info "login $host as $user"
  if ((DRY_RUN)); then
    run docker login "$host" -u "$user" --password-stdin
  else
    printf '%s' "$token" | docker login "$host" -u "$user" --password-stdin
  fi
}

login

revision=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)
created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source_url=$(origin_url || true)

for image in "${images[@]}"; do
  tags=("$repo:$image-$VERSION" "$repo:$image-$month")
  if [[ -n $KIND ]]; then tags+=("$repo:$image-$KIND"); fi

  info "publish $image:$VERSION -> $repo ($PLATFORM)"
  for tag in "${tags[@]}"; do info "  $tag"; done

  cmd=(docker buildx build --push --platform "$PLATFORM"
    --file "$ROOT/$image/Dockerfile"
    --label "org.opencontainers.image.version=$VERSION"
    --label "org.opencontainers.image.revision=$revision"
    --label "org.opencontainers.image.created=$created")
  if [[ -n $source_url ]]; then
    cmd+=(--label "org.opencontainers.image.source=$source_url")
  fi
  for tag in "${tags[@]}"; do cmd+=(--tag "$tag"); done
  cmd+=("$ROOT/$image")

  run "${cmd[@]}"
done
