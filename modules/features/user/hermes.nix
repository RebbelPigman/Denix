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
        ExecStart = "${hermesPkg}/bin/hermes proxy start --host 127.0.0.1 --port ${toString proxyPort}";
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
      };
      Service = {
        ExecStart = "${lib.getExe webuiPkg} serve --host 127.0.0.1 --port ${toString webuiPort}";
        Restart = "on-failure";
        RestartSec = "5s";
        WorkingDirectory = webuiHome;
        Environment = [
          "HOME=${webuiHome}"
          "DATA_DIR=${webuiHome}"
          "STATIC_DIR=${webuiHome}"
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
