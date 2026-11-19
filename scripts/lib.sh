#!/usr/bin/env bash
# Shared helpers for the image scripts. Source it, do not run it.

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DRY_RUN=${DRY_RUN:-0}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*" >&2
}

run() {
  if ((DRY_RUN)); then
    printf '+' >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
  else
    "$@"
  fi
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

# R from --release, the environment, or the RELEASE file.
release_number() {
  local release=${RELEASE_NUMBER:-}
  if [[ -z $release && -f $ROOT/RELEASE ]]; then
    release=$(tr -d '[:space:]' <"$ROOT/RELEASE")
  fi
  release=${release:-0}
  [[ $release =~ ^[0-9]+$ ]] || die "release must be a number, got '$release'"
  printf '%s\n' "$release"
}

# R.YY.MM.DD.HHMM in UTC, for example 0.26.11.19.2241.
current_version() {
  printf '%s.%s\n' "$(release_number)" "$(date -u +%y.%m.%d.%H%M)"
}

check_version() {
  [[ $1 =~ ^[0-9]+\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{4}$ ]] ||
    die "invalid version '$1' (expected R.YY.MM.DD.HHMM)"
}

# R.YY.MM from a version.
month_of() {
  local release yy mm
  IFS=. read -r release yy mm _ <<<"$1"
  [[ -n $mm ]] || die "invalid version '$1'"
  printf '%s.%s.%s\n' "$release" "$yy" "$mm"
}

origin_url() {
  local url
  url=$(git -C "$ROOT" remote get-url origin 2>/dev/null) || return 1
  url=${url%.git}
  url=${url#git@github.com:}
  url=${url#https://github.com/}
  url=${url#ssh://git@github.com/}
  printf 'https://github.com/%s\n' "$url"
}

# Registry repository, for example ghcr.io/atomxzr/coder-images.
image_repo() {
  if [[ -n ${IMAGE_REPO:-} ]]; then
    printf '%s\n' "$IMAGE_REPO"
    return
  fi
  local url
  url=$(origin_url) || die 'no origin remote; set IMAGE_REPO=ghcr.io/<owner>/<repo>'
  printf 'ghcr.io/%s\n' "${url#https://github.com/}" | tr '[:upper:]' '[:lower:]'
}

# Directories with a Dockerfile: the named ones, or every top-level directory.
list_images() {
  local name dir
  if (($#)); then
    for name in "$@"; do
      name=${name%/}
      [[ -f $ROOT/$name/Dockerfile ]] || die "no Dockerfile in $name/"
      printf '%s\n' "$name"
    done
    return
  fi
  for dir in "$ROOT"/*/; do
    name=$(basename "$dir")
    [[ -f $dir/Dockerfile ]] && printf '%s\n' "$name"
  done
  return 0
}

# Fill the given array with the selected image directories.
collect_images() {
  local -n out=$1
  shift
  if (($#)); then
    mapfile -t out < <(list_images "$@")
  else
    mapfile -t out < <(list_images)
  fi
  ((${#out[@]})) || die 'no images found'
}
