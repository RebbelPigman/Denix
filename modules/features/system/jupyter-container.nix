{ config, pkgs, lib, ... }:
let
  cfg = config.features.jupyter-container;
in
{
  options.features.jupyter-container = {
    enable = lib.mkEnableOption "Jupyter Notebook/Lab container (OCI + Podman)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Host port to expose Jupyter on";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/jupyter";
      description = "Host directory for notebooks (persisted)";
    };
    token = lib.mkOption {
      type = lib.types.str;
      default = "jupyter"; # Change this or use a secret manager later
      description = "Jupyter token (keep it secret in production)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Podman (works great with your wrappers)
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    # The actual container (systemd service: jupyter.service)
    virtualisation.oci-containers.containers.jupyter = {
      autoStart = true;
      image = "quay.io/jupyter/base-notebook:python-3.12"; # Official, well-maintained
      ports = [ "${toString cfg.port}:8888" ];
      volumes = [ "${cfg.dataDir}:/home/jovyan/work" ]; # Persist notebooks
      environment = {
        JUPYTER_ENABLE_LAB = "yes";
        JUPYTER_TOKEN = cfg.token;
      };
      # Run as non-root (default jovyan user in the image)
      user = "rebb";
      extraOptions = [ "--label" "nixos.container=jupyter" ];
    };

    # Optional: open firewall only on specific hosts
    networking.firewall.allowedTCPPorts = lib.mkIf config.networking.firewall.enable [ cfg.port ];

    # Create data dir (owned by podman user or your user)
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];
  };
}
