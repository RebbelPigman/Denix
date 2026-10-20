{ self, inputs, ... }: {
  # Hermes Agent + SuperGrok OAuth + Grok Bot as user services/packages.
  # Import once from a host home module (rebbModule / aureliusHome / unisonHome):
  #   imports = [ self.homeModules.catfish self.homeModules.tela self.homeModules.hermes ];
  # Do not also add this to home-manager.sharedModules.
  #
  # Host NixOS module still needs:
  #   users.users.rebb.linger = true;
  # Home Manager cannot enable linger. Without it these units die at logout.
  #
  # After the first switch, as rebb:
  #   hermes auth add xai-oauth
  # Dashboard:  http://127.0.0.1:9119  (hermes dashboard --no-open)
  # Agent API:  http://127.0.0.1:8642/v1  (needs API_SERVER_KEY in ~/Hermes/secrets.env)
  #
  # denix-rebuild overrides the hermes-agent input to github:NousResearch/hermes-agent
  # so each system rebuild evaluates upstream HEAD. flake.lock is the test/eval pin.
  #
  # The upstream HM module always writes terminal.cwd = workingDirectory
  # (default: $HOME). An absolute cwd wins over the directory you launched
  # `hermes` from. "." is the documented placeholder for "use launch dir"
  # on the local CLI/TUI. systemd WorkingDirectory stays $HOME so the
  # gateway unit still has an absolute path.
  flake.homeModules.hermes = { pkgs, config, lib, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    hermesPkg = inputs.hermes-agent.packages.${system}.default;
    grokBotPkg = inputs.grok-bot.packages.${system}.default;
    hermesHome = "${config.home.homeDirectory}/Hermes";
    secretsEnv = "${hermesHome}/secrets.env";
    apiPort = 8642;
    proxyPort = 8645;
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
    hermesDesktop = pkgs.writeShellApplication {
      name = "hermes-dashboard-desktop";
      runtimeInputs = [ pkgs.ungoogled-chromium pkgs.systemd ];
      text = ''
        systemctl --user start hermes-dashboard.service || true
        ${waitForPort dashPort}
        exec ${chromium} --new-window --app=http://127.0.0.1:${toString dashPort}
      '';
    };
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
      hermesDesktop
      grokBotPkg
    ];

    home.sessionVariables.HERMES_HOME = hermesHome;

    programs.hermes-agent = {
      enable = true;
      package = hermesPkg;
      desktop.enable = false;
    };

    xdg.dataFile."icons/hicolor/scalable/apps/hermes.svg".source = hermesIcon;

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
        # Banner is noise while denix-rebuild tracks upstream HEAD.
        updates.check = false;
        terminal.backend = "local";
        terminal.cwd = ".";
        terminal.timeout = 600;
        approvals.mode = "smart";
        approvals.smart_policy = ''
          Allow nixos-rebuild test --sudo --flake ${config.home.homeDirectory}/Dropbox/Projects/Denix#* so the agent can loop a failing eval.
          Require an explicit user phrase this turn before nixos-rebuild boot, nixos-rebuild switch, or git push.
          Phrase "set changes" authorizes boot plus a non-force git push of this repo.
          Phrase "update" authorizes switch only (not nix flake update).
          Deny git push --force, git reset --hard, and any write outside ${config.home.homeDirectory}/Dropbox/Projects/Denix.
        '';
      };
      environment = {
        API_SERVER_ENABLED = "true";
        API_SERVER_HOST = "127.0.0.1";
        API_SERVER_PORT = toString apiPort;
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

    home.activation.hermesDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${lib.escapeShellArg hermesHome}
      if [ ! -f ${lib.escapeShellArg secretsEnv} ]; then
        umask 077
        printf '%s\n' '# API_SERVER_KEY=replace-me' > ${lib.escapeShellArg secretsEnv}
      fi
    '';
  };
}
