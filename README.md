# Denix

NixOS multi-host flake using [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree). Shared features live as named `nixosModules.*` / `homeModules.*`. Each machine opts in by importing those names from its host files.

Repo: [github.com/RebbelPigman/Denix](https://github.com/RebbelPigman/Denix)

This file is a map of the tree and how to turn pieces on. It is not a description of a running machine.

---

## How the flake is wired

`flake.nix` only declares inputs and hands every file under `modules/` to flake-parts:

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```

`modules/parts.nix` sets the systems list and imports Home Manager's flake module.

Every other `.nix` file under `modules/` is itself a flake-parts module. It typically writes into:

| Attrset | Purpose |
| --- | --- |
| `flake.nixosConfigurations.<Host>` | Buildable NixOS system (`nixos-rebuild --flake .#Host`) |
| `flake.nixosModules.<name>` | Shared system feature, imported by a host configuration |
| `flake.homeModules.<name>` | Shared Home Manager feature, imported by a host home module |
| `flake.homeConfigurations.<name>` | Standalone HM config (optional; used for `home-manager --flake`) |
| `perSystem.packages.<name>` | Wrapped packages (`myNiri`, `myNoctalia`) |

`import-tree` loads **git-tracked** files. A new module that is not `git add`ed does not exist as `self.nixosModules.*` / `self.homeModules.*` and evaluation fails with a missing attribute.

### Package channels

| Input | Role |
| --- | --- |
| `nixpkgs` (`nixos-26.05`) | NixOS system packages, niri / noctalia wrappers |
| `nixpkgs-unstable` | Home Manager package set (`useGlobalPkgs = false`) |
| `home-manager` (`release-26.05`) | Module API on 26.05; packages follow unstable |
| `wrapper-modules` | niri + noctalia-shell wrappers |
| `plasma-manager` | Plasma rice (`homeModules.plasma` / `homeModules.karousel`) |
| `hermes-agent` | Hermes Agent HM module + package |

---

## Layout

```
flake.nix
modules/
  parts.nix                          # flake-parts systems + HM flake module
  features/
    system/                          # flake.nixosModules.*  (+ perSystem wrappers)
      core.nix
      desk.nix
      game.nix
      home-manager.nix               # flake.nixosModules.myHomeManager
      niri.nix                       # nixosModules.niri + packages.myNiri
      noctalia.nix                   # packages.myNoctalia (not a nixosModule)
      noctalia.json                  # settings baked into myNoctalia
      plasma.nix                     # nixosModules.plasma + homeModules.plasma
      karousel.nix                   # nixosModules.karousel (packages only)
      office.nix                     # imports plasma
    user/                            # flake.homeModules.*
      catfish.nix                    # fish + kitty
      tela.nix                       # GTK/Qt Tela-circle for niri hosts
      hermes.nix                     # Hermes Agent + Open WebUI
      karousel.nix                   # Karousel shortcuts / kwinrc
  hosts/
    Default/   Lenovus/   Aurelius/
      default.nix                    # nixosConfigurations.<Host>
      configuration.nix              # nixosModules.*Configuration  ← activate system features here
      hardware-configuration.nix     # nixosModules.*Hardware
      home.nix                       # homeModules + optional homeConfigurations  ← activate user features here
```

Convention for a host named `Lenovus`:

| File | Exports |
| --- | --- |
| `default.nix` | `nixosConfigurations.Lenovus` → imports `nixosModules.lenovusConfiguration` |
| `configuration.nix` | `nixosModules.lenovusConfiguration` |
| `hardware-configuration.nix` | `nixosModules.lenovusHardware` |
| `home.nix` | `homeModules.rebbModule` and `homeConfigurations.rebb` |

Aurelius uses `aureliusHome` / `homeConfigurations.rebbAurelius` so the two `rebb` homes do not collide. Default uses `johnModule` / `john`.

---

## Where to activate modules

Nothing in `features/` turns itself on for a machine. You attach it in the host files.

### 1. System features — `hosts/<Host>/configuration.nix`

Add the feature to `imports` on `nixosModules.<host>Configuration`:

```nix
imports = [
  self.nixosModules.core            # baseline — every host
  self.nixosModules.lenovusHardware # that host's hardware module
  self.nixosModules.myHomeManager   # required if the host has HM users
  self.nixosModules.desk
  self.nixosModules.niri
  self.nixosModules.game
  # self.nixosModules.office        # pulls plasma + karousel + LO/TeX/…
];
```

Then wire the user:

```nix
home-manager.users.rebb = self.homeModules.rebbModule;
```

Host-only NixOS options (bootloader, hostname, users, linger, pipewire, bluetooth) stay in this same file. Do not copy shared package lists here — import the feature module instead.

### 2. User features — `hosts/<Host>/home.nix`

Add the feature to `imports` on that host's `homeModules.*`:

```nix
flake.homeModules.rebbModule = { ... }: {
  imports = [
    self.homeModules.catfish
    self.homeModules.tela
    self.homeModules.hermes
  ];
  # host-only packages / overlays below
};
```

Do **not** attach `tela` or `hermes` via `home-manager.sharedModules`. Those options (`gtk.iconTheme.package`, unique service units) are not merge-safe if imported twice.

### 3. Plasma rice — pulled by `office` / `plasma`, not by niri hosts

`nixosModules.plasma` already sets:

```nix
home-manager.sharedModules = [
  self.homeModules.plasma
  self.homeModules.karousel
];
```

So a host that imports `office` or `plasma` gets the rice for every HM user on that host. Niri hosts (Lenovus, Aurelius) must **not** import `plasma`, `karousel`, or `office`.

### 4. Wrappers — not imported as modules

`packages.myNiri` and `packages.myNoctalia` are `perSystem` outputs. `nixosModules.niri` points `programs.niri.package` at `myNiri`. `myNiri` starts `myNoctalia` at login. Edit:

- niri binds / outputs / window rules → `modules/features/system/niri.nix`
- noctalia bar / theme JSON → `modules/features/system/noctalia.json`

### 5. Hardware — `hosts/<Host>/hardware-configuration.nix`

Generated-style filesystem / initrd / CPU bits live here as `nixosModules.<host>Hardware`. The host configuration imports that name. Default's hardware file is a stub (`# Paste Hardware Configuration Here`).

---

## What each module does

### System — `modules/features/system/`

#### `core` → `nixosModules.core`

Baseline that every host should import.

- ly display manager, gnome-keyring, X + i3 (minimal config: st, rofi, chromium binds)
- NetworkManager, polkit, `allowUnfree`
- flakes + nix-command
- Hermes Agent cachix substituter (`https://hermes-agent.cachix.org`)
- BlexMono Nerd Font + Sarasa Gothic, fontconfig defaults
- CLI/GUI baseline: st, vim, git, wget, yazi, lynx, fzf, eza, bat, dust, tldr, atuin, zellij, atop/btop/htop/powertop, fastfetch, brightnessctl, ungoogled-chromium, mpv, imv
- MIME defaults: chromium / imv / mpv / vim
- yazi openers, `TERMINAL=st`, `EDITOR=vim`

The first rebuild that needs the Hermes cache must pass the same `--option extra-substituters` / `--option extra-trusted-public-keys` flags. `nix.settings` only apply after a successful switch.

#### `desk` → `nixosModules.desk`

DE-agnostic GUI layer. Import on desktop hosts (niri or plasma).

- gvfs
- MIME: directories → Nemo, text → Kate (`mkForce` over core's vim maps), PDF/epub → zathura, torrents → qBittorrent
- `nemo-with-extensions` plus a `hiPrio` runCommand that rewrites `nemo.desktop` `Name=Files` → `Name=nemo`
- kate, kalk, kolourpaint, qt6ct, qalculate-gtk, adw-gtk3, nwg-look, zathura, rmpc, vlc, qbittorrent, pavucontrol, wl-clipboard, wayland-utils, xdg-utils, ffmpeg, zip/unzip/p7zip/unrar

#### `game` → `nixosModules.game`

- Steam (`remotePlay` / dedicated server / LAN transfer firewall), `extraCompatPackages = [ proton-ge-bin ]`
- gamescope + gamemode
- Heroic overridden with gamescope + gamemode on its extraPkgs
- vesktop, prismlauncher

#### `myHomeManager` → `nixosModules.myHomeManager` (`home-manager.nix`)

Turns Home Manager on for the NixOS system.

- `useGlobalPkgs = false` — HM evaluates packages from the home-manager input (unstable)
- `useUserPackages = true`
- `backupFileExtension = "backup"`, `overwriteBackup = true`
- forwards `inputs` via `extraSpecialArgs`

Does not assign users. The host configuration sets `home-manager.users.<name> = self.homeModules.<thatHome>`.

#### `niri` → `nixosModules.niri` + `packages.myNiri`

- `programs.niri.enable`, package = wrapped `myNiri`
- system `tela-circle-icon-theme`

Wrapper settings (in the same file):

- toolkit env: `QT_SCALE_FACTOR=1`, `GDK_SCALE=1`, `GTK_THEME=adw-gtk3-dark`, `GTK_ICON_THEME=Tela-circle`, qt6ct
- outputs `eDP-1` / `HDMI-A-1` / `HDMI-A-2` / `DP-1` / `DP-2` / `DP-3` scale `1.0` (unknown connectors are ignored)
- spawn-at-startup: `myNoctalia`, `dropbox`
- US kbd with caps↔escape, ralt compose, mac numpad; touchpad tap + natural scroll
- Catppuccin-ish layout colors, named workspaces `1-Game` … `5-Other`
- window rules (floating kitty/nemo, browsers on Web, Obsidian/Grok on Work, Steam/Vesktop on Other)
- keybinds (kitty, fuzzel, noctalia IPC, browsers, yazi/nemo, volume/brightness)

Do not also put `homeModules.tela` on `home-manager.sharedModules`.

#### `noctalia` → `packages.myNoctalia` only

Not a NixOS module. Wraps `noctalia-shell` with `modules/features/system/noctalia.json` (`settings.bar`, wallpaper, launcher, control center, …). `myNiri` launches it. Hosts that use niri still enable bluetooth + `power-profiles-daemon` + `upower` in the host configuration so the bar's widgets have backends.

#### `plasma` → `nixosModules.plasma` + `homeModules.plasma`

NixOS side:

- imports `desk` + `karousel`
- Plasma 6, kdeconnect
- filelight, partitionmanager, ksystemlog, kcharselect, isoimagewriter
- Tela-circle, Catppuccin KDE mocha/mauve
- `home-manager.sharedModules` = plasma + karousel home modules

Home side (`homeModules.plasma`):

- plasma-manager rice: Scratchy + CatppuccinMocha + Tela-circle-purple-dark
- BlexMono fonts, four virtual desktops, focus-follows-mouse, shortcuts, kwinrules opacity for konsole/dolphin/okular/anki/kitty/obsidian
- wallpaper path `~/.wallpaper`

Office/plasma hosts only. Keep off Lenovus and Aurelius.

#### `karousel` → `nixosModules.karousel` (packages) + `homeModules.karousel` (rice)

System: `kdePackages.karousel` + `kwin-script-geometry-change`.

Home: enables the plugins, gaps, preset widths, windowRules (plasmashell/krunner/kitty/steam floating, etc.), and the full Karousel shortcut map.

Imported automatically by `nixosModules.plasma`. Do not import the home module on a niri host.

#### `office` → `nixosModules.office`

Imports `plasma` (and therefore desk + karousel + plasma rice). Adds LibreOffice-qt6, hunspell en-GB/en-US, pdfarranger, TeXstudio + texliveMedium extras, ghostscript, poppler-utils, krita, gimp, kdenlive.

Use this for a Plasma workstation. Do not combine with `niri` on the same host unless you intentionally want both sessions in ly.

---

### User — `modules/features/user/`

#### `catfish` → `homeModules.catfish`

Shared fish + kitty.

- fish aliases: `ff`, `yz`, `vi`/`vim` → nvim
- abbrs: `nixos-test`, `nixos-switch` (`--flake ~/.nixos`), `git-acp`
- kitty: BlexMono, fish, tall layout, noctalia theme include, split/tab maps

Host homes import this and then overlay host-only fish/kitty bits (Lenovus: grc plugin + fastfetch greeting; Aurelius: python nix-shell alias + Catppuccin-Mocha themeFile).

#### `tela` → `homeModules.tela`

GTK + Qt icon theme for **niri** hosts.

- `gtk.iconTheme` = Tela-circle from `tela-circle-icon-theme`
- qtct platform theme + `qt6ct.conf` icon_theme
- `GTK_ICON_THEME=Tela-circle`

Import **once** from the host home module (`rebbModule`, `aureliusHome`). Unique option — a second attach fails the rebuild.

#### `hermes` → `homeModules.hermes`

Hermes Agent + xAI proxy + Open WebUI as user systemd services.

- `programs.hermes-agent` / `services.hermes-agent` (gateway, `xai-oauth`, default model `grok-4.6`)
- API server on `127.0.0.1:8642` (needs `API_SERVER_KEY` in `~/.hermes/secrets.env`)
- `hermes-proxy` on `:8645`
- Open WebUI on `:3000` pointed at the proxy
- activation creates `~/.hermes` and a placeholder secrets file

The **NixOS** user must set `users.users.<name>.linger = true`. Home Manager cannot enable linger; without it the units die at logout.

Imported from `rebbModule` (Lenovus) and `aureliusHome` (Aurelius).

After the first switch, as that user:

```bash
hermes auth add xai-oauth
```

#### `karousel` (user) → `homeModules.karousel`

See system `karousel` above. Plasma-only.

---

## Current hosts (how they opt in)

| Host | System imports | Home imports | Notes |
| --- | --- | --- | --- |
| **Lenovus** | core, lenovusHardware, myHomeManager, desk, niri, game | catfish, tela, hermes | GRUB + LUKS, user `rebb` with linger, swapfile, lid → suspend-then-hibernate |
| **Aurelius** | core, aureliusHardware, myHomeManager, desk, niri, game | catfish, tela, hermes | systemd-boot, user `rebb` with linger, pipewire, printing. Home attr `aureliusHome` / `rebbAurelius` |
| **Default** | core, defaultHardware, myHomeManager | (bash only) | Template. User `john`. Hardware file is empty. See caveat below |

Neither live host imports `office` / `plasma` / `karousel`.

---

## Day-to-day use

Clone / update, then from the flake root (this repo is often checked out as `~/.nixos`):

```bash
# evaluate / test a host
nixos-rebuild test --sudo --flake .#Lenovus
nixos-rebuild switch --sudo --flake .#Lenovus

nixos-rebuild test --sudo --flake .#Aurelius
nixos-rebuild switch --sudo --flake .#Aurelius
```

Standalone Home Manager (same modules the NixOS system already attaches):

```bash
home-manager switch --flake .#rebb            # Lenovus home
home-manager switch --flake .#rebbAurelius    # Aurelius home
```

Fish abbrs on hosts that import `catfish` assume the flake lives at `~/.nixos`.

### First rebuild that pulls Hermes

`nix.settings` in `core` is not active until a generation that contains those settings has switched successfully. Until then:

```bash
nixos-rebuild switch --sudo --flake .#Lenovus \
  --option extra-substituters https://hermes-agent.cachix.org \
  --option extra-trusted-public-keys hermes-agent.cachix.org-1:jN3pjR50Mxi4SESKC/FIMNM6/LCosvPk2VUwzVvebzU=
```

---

## Adding a host

1. Copy `modules/hosts/Default/` to `modules/hosts/<Name>/`.
2. Rename the flake attrs to match the convention (`nixosConfigurations.<Name>`, `nixosModules.<name>Configuration`, `nixosModules.<name>Hardware`, a uniquely named `homeModules.*`).
3. Paste a real `hardware-configuration.nix` into the hardware module (keep the `flake.nixosModules.* = { ... }:` wrapper — do not drop a raw `hardware-configuration.nix` from `nixos-generate-config` at the repo root).
4. In `configuration.nix`, import `core` + hardware + `myHomeManager`, then the feature modules you want (`desk`, `niri` **or** `office`, `game`, …).
5. In `home.nix`, import `catfish` (and `tela` on niri, `hermes` only if linger is on).
6. `git add` the new files before evaluating.
7. `nixos-rebuild switch --sudo --flake .#<Name>`

Suggested stacks:

- Niri laptop/desktop: `core` + `desk` + `niri` + optional `game`. Home: `catfish` + `tela`.
- Plasma workstation: `core` + `office` (brings plasma, desk, karousel, rice). Home: `catfish` only — plasma/karousel arrive via `sharedModules`. Do not import `tela` unless you drop Plasma's icon theme.

Do not import both `niri` and `office` unless you want both sessions listed in ly.

---

## Adding a feature module

1. Create `modules/features/system/<name>.nix` or `modules/features/user/<name>.nix`.
2. Export `flake.nixosModules.<name>` or `flake.homeModules.<name>` — a complete Nix expression, never an empty file.
3. `git add` it.
4. Import that name from the host configuration or host home module. Prefer host `imports` over `home-manager.sharedModules` unless every user on every plasma host should get it.

If two modules set the same unique option (`gtk.iconTheme.package`, a single desktop entry rewrite, linger, …), import only one path.

---

## Caveats

- **Default configuration attr typo.** `hosts/Default/configuration.nix` currently defines `flake.nixosModules.deafaultConfiguration`, while `default.nix` imports `self.nixosModules.defaultConfiguration`. The Default host does not evaluate until those names match.
- **Default hardware** is a stub. Generate and wrap it before using that host.
- **Lenovus resume.** `boot.kernelParams` still has `resume_offset=PUT_THE_NUMBER_HERE`. Hibernate will not work until that offset is filled in.
- **Plasma vs niri.** Plasma/karousel home modules stay off niri hosts. `tela` stays off plasma hosts (or at least off `sharedModules`).
- **Hermes linger.** Lenovus and Aurelius set `users.users.rebb.linger = true`. A host that imports `homeModules.hermes` without linger will start units that vanish after logout.
- **Evaluation sees git.** Untracked feature files are invisible to `self.nixosModules` / `self.homeModules`.

---

## Inputs worth knowing when editing

| You want to change | Edit |
| --- | --- |
| Shared CLI, fonts, ly, nix settings | `features/system/core.nix` |
| File manager / MIME / extra GUI | `features/system/desk.nix` |
| Steam / Heroic / Proton-GE | `features/system/game.nix` |
| Niri binds, outputs, window rules | `features/system/niri.nix` |
| Noctalia bar / widgets | `features/system/noctalia.json` |
| Plasma look, shortcuts, kwin rules | `features/system/plasma.nix` (`homeModules.plasma`) |
| Karousel gaps / shortcuts | `features/user/karousel.nix` |
| Office / TeX / Krita | `features/system/office.nix` |
| fish + kitty shared | `features/user/catfish.nix` |
| GTK icons on niri | `features/user/tela.nix` |
| Hermes / Open WebUI | `features/user/hermes.nix` |
| Bootloader, users, hostname, linger | `hosts/<Host>/configuration.nix` |
| Disks / initrd | `hosts/<Host>/hardware-configuration.nix` |
| Per-user packages | `hosts/<Host>/home.nix` |
