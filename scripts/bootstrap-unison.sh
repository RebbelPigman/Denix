#!/usr/bin/env bash
# First Denix generation on a stock NixOS Unison install (no git/flakes yet).
#
# As rebb, with network:
#   nix --extra-experimental-features 'nix-command flakes' run nixpkgs#curl -- \
#     -fsSL https://raw.githubusercontent.com/RebbelPigman/Denix/main/scripts/bootstrap-unison.sh \
#     -o /tmp/bootstrap-unison.sh
#   bash /tmp/bootstrap-unison.sh
set -euo pipefail

REPO="https://github.com/RebbelPigman/Denix.git"
FLAKE="${HOME}/Nixos"
ATTR="Unison"
NIX_XTRA=(--extra-experimental-features "nix-command flakes")
HERMES_SUB="https://hermes-agent.cachix.org"
HERMES_KEY="hermes-agent.cachix.org-1:jN3pjR50Mxi4SESKC/FIMNM6/LCosvPk2VUwzVvebzU="
NIX_CONFIG_BOOTSTRAP="experimental-features = nix-command flakes
extra-substituters = ${HERMES_SUB}
extra-trusted-public-keys = ${HERMES_KEY}
"

nix_run() {
  local pkg=$1
  shift
  nix "${NIX_XTRA[@]}" run "nixpkgs#${pkg}" -- "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

run_git() {
  if have git; then
    git "$@"
  else
    nix_run git "$@"
  fi
}

host=$(tr -d '[:space:]' </etc/hostname)
case "$host" in
  Unison|nixos) ;;
  *)
    echo "bootstrap-unison: refuse hostname '$host' (want nixos or Unison)" >&2
    exit 1
    ;;
esac

if [ "$(id -un)" != "rebb" ]; then
  echo "bootstrap-unison: run as rebb, not $(id -un)" >&2
  exit 1
fi

if [ ! -d "$FLAKE/.git" ]; then
  run_git clone "$REPO" "$FLAKE"
else
  run_git -C "$FLAKE" pull --ff-only
fi

rebuild=/run/current-system/sw/bin/nixos-rebuild
if [ ! -x "$rebuild" ]; then
  if have nixos-rebuild; then
    rebuild=$(command -v nixos-rebuild)
  else
    echo "bootstrap-unison: nixos-rebuild missing; using nix run nixpkgs#nixos-rebuild" >&2
    rebuild=""
  fi
fi

workdir=$(mktemp -d /tmp/denix-bootstrap.XXXXXX)
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

rebuild_args=(
  switch
  --flake "$FLAKE#$ATTR"
  --option extra-substituters "$HERMES_SUB"
  --option extra-trusted-public-keys "$HERMES_KEY"
)

if [ -n "$rebuild" ]; then
  sudo env NIX_CONFIG="$NIX_CONFIG_BOOTSTRAP" "$rebuild" "${rebuild_args[@]}"
else
  sudo env NIX_CONFIG="$NIX_CONFIG_BOOTSTRAP" nix "${NIX_XTRA[@]}" \
    run nixpkgs#nixos-rebuild -- "${rebuild_args[@]}"
fi
