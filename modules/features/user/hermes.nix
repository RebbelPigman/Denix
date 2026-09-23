{ self, inputs, ... }: {
  # Hermes Agent + SuperGrok OAuth + Open WebUI as user services.
  # Import once from a host home module (rebbModule / aureliusHome):
  #   imports = [ self.homeModules.catfish self.homeModules.tela self.homeModules.hermes ];
  # Do not also add this to home-manager.sharedModules.
  #
  # Host NixOS module still needs:
  #   users.users.rebb.linger = true;
  # Home Manager cannot enable linger. Without it these units die at logout.
  #
  # After the first switch, as rebb:
  #   hermes auth add xai-oauth
  # Open WebUI: http://127.0.0.1:3000  (points at the Grok proxy on :8645)
  # Dashboard:  http://127.0.0.1:9119  (hermes dashboard --no-open)
  # Agent API:  http://127.0.0.1:8642/v1  (needs API_SERVER_KEY in ~/.hermes/secrets.env)
  #
  # Denix edit policy lives in repo-root AGENTS.md. This module pins the
  # agent write root and terminal cwd to ~/Nixos and installs the
  # denix-host skill into HERMES_HOME.
  flake.homeModules.hermes = { pkgs, config, lib, inputs, ... }: 
  let
    system = pkgs.stdenv.hostPlatform.system;
    hermesPkg = inputs.hermes-agent.packages.${system}.default;
    pkgsUnfree = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    webuiPkg = pkgsUnfree.open-webui;
    hermesHome = "${config.home.homeDirectory}/.hermes";
    webuiHome = "${config.xdg.dataHome}/open-webui";
    secretsEnv = "${hermesHome}/secrets.env";
    apiPort = 8642;
    proxyPort = 8645;
    webuiPort = 3000;
    dashPort = 9119;
    chromium = lib.getExe pkgs.ungoogled-chromium;
    waitForPort = port: ''
      i=0
      while [ "$i" -lt 50 ]; do
        if (echo >/dev/tcp/127.0.0.1/${toString port}) >/dev/null 2>&1; then
          break
        fi
        i=$((i + 1));
        sleep 0.2
      done
    '';
    openWebuiDesktop = pkgs.writeShellApplication {
      name = "open-webui-desktop";
      runtimeInputs = [ pkgs.ungoogled-chromium pkgs.systemd ];
      text = ''
        systemctl --user start open-webui.service || true
        ${waitForPort webuiPort}
        exec ${chromium} --new-window --app=http://127.0.0.1:${toString webuiPort}
      '';
    };
    hermesDesktop = pkgs.writeShellApplication {
      name = "hermes-dashboard-desktop";
      runtimeInputs = [ pkgs.ungoogled-chromium pkgs.systemd ];
      text = ''
        systemctl --user start hermes-dashboard.service || true
        ${waitForPort dashPort}
        exec ${chromium} --new-window --app=http://127.0.0.1:${toString dashPort}
      '';
    };
    webuiIcon = pkgs.writeText "open-webui.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <rect width="64" height="64" rx="12" fill="#343541"/>
        <circle cx="32" cy="32" r="16" fill="none" stroke="#10A37F" stroke-width="4"/>
        <circle cx="32" cy="32" r="6" fill="#10A37F"/>
      </svg>
    '';
    hermesIcon = pkgs.writeText "hermes.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <rect width="64" height="64" rx="12" fill="#1B1B2F"/>
        <path d="M16 44 L32 12 L48 44" fill="none" stroke="#C9A227" stroke-width="4" stroke-linejoin="round"/>
        <circle cx="32" cy="48" r="5" fill="#C9A227"/>
      </svg>
    '';
  in {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    nixpkgs.config.allowUnfree = true;

    home.packages = [
      openWebuiDesktop
      hermesDesktop
      (pkgs.writeShellApplication {
        name = "open-webui";
        text = ''
          export HOME=${lib.escapeShellArg config.home.homeDirectory}
          export DATA_DIR=${lib.escapeShellArg webuiHome}
          export DATABASE_URL=${lib.escapeShellArg "sqlite:////${webuiHome}/webui.db"}
          export HF_HOME=${lib.escapeShellArg "${webuiHome}/hf"}
          export SENTENCE_TRANSFORMERS_HOME=${lib.escapeShellArg "${webuiHome}/st"}
          export WEBUI_URL=${lib.escapeShellArg "http://127.0.0.1:${toString webuiPort}"}
          export ENABLE_OLLAMA_API=False
          export OPENAI_API_BASE_URL=${lib.escapeShellArg "http://127.0.0.1:${toString proxyPort}/v1"}
          export OPENAI_API_KEY="''${OPENAI_API_KEY:-sk-unused}"
          export SCARF_NO_ANALYTICS=True
          export DO_NOT_TRACK=True
          export ANONYMIZED_TELEMETRY=False
          mkdir -p "$DATA_DIR"
          if [ -f ${lib.escapeShellArg secretsEnv} ]; then
            set -a
            # shellcheck disable=SC1091
            source ${lib.escapeShellArg secretsEnv}
            set +a
          fi
          if [ "$#" -eq 0 ]; then
            exec ${lib.getExe webuiPkg} serve --host 127.0.0.1 --port ${toString webuiPort}
          fi
          exec ${lib.getExe webuiPkg} "$@"
        '';
      })
    ];

    programs.hermes-agent = {
      enable = true;
      package = hermesPkg;
      desktop.enable = false;
    };

    xdg.dataFile."icons/hicolor/scalable/apps/open-webui.svg".source = webuiIcon;
    xdg.dataFile."icons/hicolor/scalable/apps/hermes.svg".source = hermesIcon;

    xdg.desktopEntries.open-webui = {
      name = "Open WebUI";
      genericName = "Chat";
      comment = "Open WebUI in Chromium (Grok via Hermes proxy)";
      exec = lib.getExe openWebuiDesktop;
      icon = "open-webui";
      terminal = false;
      categories = [ "Network" "Office" ];
      startupNotify = true;
    };

    xdg.desktopEntries.hermes = {
      name = "Hermes";
      genericName = "Agent";
      comment = "Hermes dashboard in Chromium";
      exec = lib.getExe hermesDesktop;
      icon = "hermes";
      terminal = false;
      categories = [ "Development" "Network" ];
      startupNotify = true;
    };

    services.hermes-agent = {
      enable = true;
      package = hermesPkg;
      hermesHome = hermesHome;
      gateway.enable = true;
      backend.mode = "none";
      hermesHomeFiles = {
        "skills/denix-host/SKILL.md" = ./denix-host/SKILL.md;
      };
      settings = {
        model.provider = "xai-oauth";
        model.default = "grok-4.6";
        terminal.backend = "local";
        terminal.cwd = "${config.home.homeDirectory}/Nixos";
        terminal.timeout = 600;
        approvals.mode = "smart";
        approvals.smart_policy = ''
          Allow nixos-rebuild test --sudo --flake ${config.home.homeDirectory}/Nixos#* so the agent can loop a failing eval.
          Require an explicit user phrase this turn before nixos-rebuild boot, nixos-rebuild switch, or git push.
          Phrase "set changes" authorizes boot plus a non-force git push of this repo.
          Phrase "update" authorizes switch only (not nix flake update).
          Deny git push --force, git reset --hard, and any write outside ${config.home.homeDirectory}/Nixos.
        '';
      };
      environment = {
        API_SERVER_ENABLED = "true";
        API_SERVER_HOST = "127.0.0.1";
        API_SERVER_PORT = toString apiPort;
        HERMES_WRITE_SAFE_ROOT = "${config.home.homeDirectory}/Nixos";
      };
      environmentFiles = [ secretsEnv ];
    };

    systemd.user.services.hermes-proxy = {
      Unit = {
        Description = "Hermes xAI subscription proxy";
        After = [ "hermes-agent.service" ];
      };
      Service = {
        ExecStart = "${hermesPkg}/bin/hermes proxy start --provider xai --host 127.0.0.1 --port ${toString proxyPort}";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [ "HERMES_HOME=${hermesHome}" ];
        WorkingDirectory = hermesHome;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.hermes-dashboard = {
      Unit = {
        Description = "Hermes Web Dashboard";
        After = [ "hermes-agent.service" ];
      };
      Service = {
        ExecStart = "${hermesPkg}/bin/hermes dashboard --no-open --host 127.0.0.1 --port ${toString dashPort}";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [ "HERMES_HOME=${hermesHome}" ];
        WorkingDirectory = hermesHome;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.open-webui = {
      Unit = {
        Description = "Open WebUI";
        After = [ "hermes-agent.service" "hermes-proxy.service" ];
        StartLimitIntervalSec = 120;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe webuiPkg} serve --host 127.0.0.1 --port ${toString webuiPort}";
        Restart = "on-failure";
        RestartSec = "20s";
        TimeoutStartSec = "180s";
        WorkingDirectory = webuiHome;
        Environment = [
          "HOME=${config.home.homeDirectory}"
          "DATA_DIR=${webuiHome}"
          "DATABASE_URL=sqlite:////${webuiHome}/webui.db"
          "HF_HOME=${webuiHome}/hf"
          "SENTENCE_TRANSFORMERS_HOME=${webuiHome}/st"
          "WEBUI_URL=http://127.0.0.1:${toString webuiPort}"
          "ENABLE_OLLAMA_API=False"
          "OPENAI_API_BASE_URL=http://127.0.0.1:${toString proxyPort}/v1"
          "OPENAI_API_KEY=sk-unused"
          "SCARF_NO_ANALYTICS=True"
          "DO_NOT_TRACK=True"
          "ANONYMIZED_TELEMETRY=False"
        ];
        EnvironmentFile = [ "-${secretsEnv}" ];
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.activation.hermesDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${lib.escapeShellArg hermesHome} ${lib.escapeShellArg webuiHome}
      if [ ! -f ${lib.escapeShellArg secretsEnv} ]; then
        umask 077
        printf '%s\n' '# API_SERVER_KEY=replace-me' > ${lib.escapeShellArg secretsEnv}
      fi
    '';
  };
}
