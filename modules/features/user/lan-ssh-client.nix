{ self, inputs, ... }: {
  # LAN SSH client: Host blocks for Unison <-> Aurelius.
  # Import from both host homes:
  #   self.homeModules.lanSshClient
  # Private key stays ~/.ssh/id_ed25519_lan (not this repo).
  # Aurelius-only remote dashboard tunnel:
  #   self.homeModules.hermesRemoteWebui
  flake.homeModules.lanSshClient = { lib, ... }: {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        aurelius = {
          host = "Aurelius aurelius Aurelius.local";
          hostname = "Aurelius.local";
          user = "rebb";
          identityFile = "~/.ssh/id_ed25519_lan";
          identitiesOnly = true;
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };
        unison = {
          host = "Unison unison Unison.local";
          hostname = "Unison.local";
          user = "rebb";
          identityFile = "~/.ssh/id_ed25519_lan";
          identitiesOnly = true;
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };
      };
    };
  };

  # Open Unison's Hermes dashboard (127.0.0.1:9119) from Aurelius via SSH -L.
  # Hermes stays on Unison. Import only on aureliusHome.
  flake.homeModules.hermesRemoteWebui = { pkgs, lib, config, ... }:
  let
    dashPort = 9119;
    chromium = lib.getExe pkgs.ungoogled-chromium;
    waitForPort = port: ''
      i=0
      while [ "$i" -lt 50 ]; do
        if (echo >/dev/tcp/127.0.0.1/${toString port}) >/dev/null 2>&1; then
          break
        fi
        i=$((i + 1))
        sleep 0.2
      done
    '';
    hermesRemoteDesktop = pkgs.writeShellApplication {
      name = "hermes-remote-dashboard";
      runtimeInputs = [ pkgs.ungoogled-chromium pkgs.systemd pkgs.coreutils ];
      text = ''
        systemctl --user start hermes-webui-tunnel.service || true
        ${waitForPort dashPort}
        exec ${chromium} --new-window --app=http://127.0.0.1:${toString dashPort}
      '';
    };
    hermesIcon = pkgs.writeText "hermes-remote.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <rect width="64" height="64" rx="12" fill="#1B1B2F"/>
        <path d="M16 44 L32 12 L48 44" fill="none" stroke="#C9A227" stroke-width="4" stroke-linejoin="round"/>
        <circle cx="32" cy="48" r="5" fill="#C9A227"/>
      </svg>
    '';
  in {
    home.packages = [ hermesRemoteDesktop ];

    xdg.dataFile."icons/hicolor/scalable/apps/hermes-remote.svg".source = hermesIcon;

    xdg.desktopEntries.hermes-remote = {
      name = "Hermes (Unison)";
      genericName = "Agent";
      comment = "Unison Hermes dashboard via SSH tunnel";
      exec = lib.getExe hermesRemoteDesktop;
      icon = "hermes-remote";
      terminal = false;
      categories = [ "Development" "Network" ];
      startupNotify = true;
    };

    systemd.user.services.hermes-webui-tunnel = {
      Unit = {
        Description = "SSH tunnel to Unison Hermes dashboard :${toString dashPort}";
        After = [ "network-online.target" "default.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        # -N: no remote shell. ExitOnForwardFailure so a dead bind restarts the unit.
        # -F user config: system ssh_config Includes a nobody-owned nix-store file.
        ExecStart = "${pkgs.openssh}/bin/ssh -F ${config.home.homeDirectory}/.ssh/config -N -o BatchMode=yes -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L ${toString dashPort}:127.0.0.1:${toString dashPort} Unison";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
