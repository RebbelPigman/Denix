# Denix agent rules

This file is project context for Hermes (and any other agent) when the working directory is this flake. It is not imported by Nix.

Flake root on the hosts: `~/Nixos` (github.com/RebbelPigman/Denix). Stay inside that tree.

## Host map

Resolve the flake attr from the machine, then only edit that host plus shared features.

| `hostnamectl --static` | Flake attr | Host dir | Home module |
| --- | --- | --- | --- |
| `Lenovus` | `Lenovus` | `modules/hosts/Lenovus/` | `rebbModule` |
| `Aurelius` | `Aurelius` | `modules/hosts/Aurelius/` | `aureliusHome` |
| `default` | `Default` | `modules/hosts/Default/` | `johnModule` |

Command shape (replace `ATTR` with the table value, not the raw hostname when they differ). Call the system binary so passwordless sudo matches:

```bash
/run/current-system/sw/bin/nixos-rebuild test  --sudo --flake ~/Nixos#ATTR
/run/current-system/sw/bin/nixos-rebuild boot  --sudo --flake ~/Nixos#ATTR
/run/current-system/sw/bin/nixos-rebuild switch --sudo --flake ~/Nixos#ATTR
```

Keep `--sudo` so the flake is evaluated as `rebb` (root must not own `~/Nixos`). `hermesRebuild` grants NOPASSWD for `nixos-rebuild` and the inner activation commands (`nix-env`, `nix-store`, `systemd-run`, `switch-to-configuration`).

Do not prompt for a password. If sudo still asks, that expanded generation is not active yet. Stop and say so — do not invent askpass or write a password.

`Default` is the exception: hostname `default`, attr `Default`.

## What you may touch

- Files under `~/Nixos` only.
- Shared features: `modules/features/system/*.nix`, `modules/features/user/*.nix`.
- Host wiring: that host’s `configuration.nix` / `home.nix` (and hardware only if the user named it).
- Git in this repo: `status`, `diff`, `add`, `commit`, `fetch`, `pull --ff-only`.

Do not edit, read-for-rewrite, or run destructive commands outside `~/Nixos`. Do not change `~/.hermes` secrets, `/etc`, or another host’s files in the same turn.

## Phrase gates

Free to do on any Denix request:

1. `git fetch` and `git pull --ff-only` (stop if the tree is dirty from someone else).
2. Read `README.md`, then only the files that belong to this change.
3. Edit. `git add` every new module file (`import-tree` ignores untracked `.nix`).
4. Loop **test** until it succeeds or the cap is hit:

```bash
/run/current-system/sw/bin/nixos-rebuild test --sudo --flake ~/Nixos#ATTR
```

On failure: read the log, fix a file in `~/Nixos`, test again. Cap: **5** test attempts. Then stop and paste the last error.

Only when the user says **set changes** in this turn:

```bash
/run/current-system/sw/bin/nixos-rebuild boot --sudo --flake ~/Nixos#ATTR
git push
```

`boot` writes the new generation without switching the running system. Push only `origin` of this repo, never `--force`.

Only when the user says **update** in this turn:

```bash
/run/current-system/sw/bin/nixos-rebuild switch --sudo --flake ~/Nixos#ATTR
```

`update` here means switch the running generation. It does **not** mean `nix flake update`. Changing `flake.lock` needs its own explicit request.

If the user did not say those phrases, refuse `boot`, `switch`, and `git push`. Offer the test log instead.

## Module conventions

- Activate system features from `hosts/<Host>/configuration.nix` `imports`. Activate user features from that host’s `home.nix` `imports`.
- Do not put `tela` or `hermes` on `home-manager.sharedModules`.
- Niri/sway hosts (Lenovus, Aurelius) do not import `plasma`, `karousel`, or `office`.
- Do not copy package lists into a host file when a feature module already has them.
- New `flake.nixosModules.*` / `flake.homeModules.*` files must be git-added before they exist to the flake.
- Read `README.md` for the current import table before adding a module.

## Commands that stay off unless named

- `nixos-rebuild boot` / `switch` (phrase gates above)
- `git push` / `git push --force` / `git reset --hard` / rebase
- `nix flake update`
- `nixos-rebuild` against any path other than `~/Nixos#ATTR`
- `sudo` for anything except the `nixos-rebuild` lines above
