---
name: denix-host
description: Edit Denix hosts, test rebuilds, gate boot and switch.
version: 0.1.0
author: Rebbel Pigman (RebbelPigman), Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [NixOS, Flake, Denix]
    related_skills: [github]
    requires_toolsets: [terminal, file]
---

# Denix host skill

Operate github.com/RebbelPigman/Denix checked out at `~/Nixos`. Load repo-root `AGENTS.md` and follow it. File writes stay under `~/Nixos`.

## When to use

Any request to change a Denix module, activate a feature on a host, rebuild, or fix a NixOS eval/activate error.

## Procedure

1. `hostnamectl --static` → flake attr from `AGENTS.md` host map. Stop if unknown.
2. `cd ~/Nixos && git pull --ff-only`. Stop on a foreign dirty tree.
3. Read `README.md`, then only that host’s files plus the feature being changed.
4. Edit. `git add` new `.nix` files.
5. Loop up to five times:

```bash
sudo /run/current-system/sw/bin/denix-rebuild test
```

Fix the error in-tree and retry. After five failures, stop.

6. `sudo /run/current-system/sw/bin/denix-rebuild boot` and `git push` only if this turn contains **set changes**.
7. `sudo /run/current-system/sw/bin/denix-rebuild switch` only if this turn contains **update**.
   If sudo asks for a password, stop — `hermesRebuild` must be in the running generation. Tell the human: `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake ~/Nixos#ATTR` (no `--sudo`).

## Pitfalls

- Hostname `default` uses attr `Default`.
- Open WebUI on `:8645` has no tools. Use Hermes CLI, dashboard, or `:8642`.
- `update` is switch, not `nix flake update`.
- Untracked feature files are invisible to `self.nixosModules` / `self.homeModules`.
- If sudo asks for a password, do **not** tell the user to run `--sudo`. Tell them: `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake ~/Nixos#ATTR` (no `--sudo`).

## Verification

A clean `denix-rebuild test`. Do not claim the running system changed unless `switch` was authorized and succeeded.
