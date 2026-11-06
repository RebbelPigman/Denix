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

Operate github.com/RebbelPigman/Denix checked out at `~/Dropbox/Projects/Denix`. Load repo-root `AGENTS.md` and follow it. File writes stay under `~/Dropbox/Projects/Denix`.

## When to use

Any request to change a Denix module, activate a feature on a host, rebuild, or fix a NixOS eval/activate error.

## Procedure

1. `hostnamectl --static` → flake attr from `AGENTS.md` host map. Stop if unknown.
2. `cd ~/Dropbox/Projects/Denix && GIT_SSH_COMMAND='ssh -F ~/.ssh/config -o BatchMode=yes -o IdentitiesOnly=yes' git pull --ff-only`. Stop on a foreign dirty tree. Plain git hits the OpenSSH owner check.
3. Read `README.md`, then only that host’s files plus the feature being changed.
4. Edit. `git add` new `.nix` files.
5. Loop up to five times:

```bash
/run/wrappers/bin/sudo -n /run/current-system/sw/bin/nixos-rebuild test --flake ~/Dropbox/Projects/Denix#ATTR
```

Fix the error in-tree and retry. After five failures, stop.

6. When that test succeeded and the module goal is achieved, boot. There is no **set changes** phrase. Do not switch. Do not push unless Rebb said push.

```bash
/run/wrappers/bin/sudo -n /run/current-system/sw/bin/nixos-rebuild boot --flake ~/Dropbox/Projects/Denix#ATTR
```

7. `switch` is the Sunday 20:00 timer, or only if this turn contains **update**. Sunday also runs `denix-gc` (boot entries and store paths older than 30d).
   Never pass `--sudo`. If sudo asks for a password, stop.

## Pitfalls

- Hostname `default` uses attr `Default`.
- Open WebUI on `:8645` has no tools. Use Hermes CLI, dashboard, or `:8642`.
- There is no **set changes** phrase. Boot follows a successful test when the goal is done.
- `update` is switch, not `nix flake update`. Switch is Sunday unless they say update.
- Untracked feature files are invisible to `self.nixosModules` / `self.homeModules`.
- Never pass `--sudo` to nixos-rebuild. Outer sudo is enough.

## Verification

A clean `nixos-rebuild test` for the resolved attr. Do not claim the running system changed unless `switch` was authorized and succeeded.
