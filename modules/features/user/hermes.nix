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
  # Agent API:  http://127.0.0.1:8642/v1  (needs API_SERVER_KEY in ~/.hermes/secrets.env)
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
  in {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    nixpkgs.config.allowUnfree = true;

    # Same env as the user unit. Bare `open-webui` starts the server;
    # extra args are passed through (`open-webui --version`, `open-webui serve …`).
    home.packages = [
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

    services.hermes-agent = {
      enable = true;
      package = hermesPkg;
      hermesHome = hermesHome;
      gateway.enable = true;
      backend.mode = "none";
      settings = {
        model.provider = "xai-oauth";
        model.default = "grok-4.6";
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
        # Default provider is nous. Without --provider xai this unit exits 2
        # when the only login is `hermes auth add xai-oauth`.
        ExecStart = "${hermesPkg}/bin/hermes proxy start --provider xai --host 127.0.0.1 --port ${toString proxyPort}";
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
        # 0.11.x first boot can fail mid-alembic. A 5s restart on a locked
        # sqlite file loops (100+ times) and leaves `no such table: config`.
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
          # Four slashes = absolute sqlite path. Alembic and the app must
          # share one file; a relative URL plus HOME=DATA_DIR races.
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
