#!/usr/bin/env bash
# Print the current UTC version: R.YY.MM.DD.HHMM
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

RELEASE_NUMBER=

usage() {
  cat <<'EOF'
usage: scripts/version.sh [-r <release>]

Prints the current version, for example 0.26.11.19.2241.
R comes from the RELEASE file unless -r is given; the rest is the UTC time.
EOF
}

while (($#)); do
  case $1 in
    -r | --release) RELEASE_NUMBER=${2:?"-r needs a number"}; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

current_version
