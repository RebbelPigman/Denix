{ ... }: {
  # Nightly limp-mode swap for Garden girls on Unison.
  # Import once from unisonHome:
  #   self.homeModules.limpMode
  # Do not import on Aurelius. Hermes lives on Unison.
  # Persistent=false: skip if Unison was off at the wall-clock.
  flake.homeModules.limpMode = { pkgs, config, ... }:
  let
    limp = "/home/rebb/Dropbox/AgentGarden/Scripts/limpMode.sh";
    mkWrapper = action:
      pkgs.writeShellApplication {
        name = "limpmode-${action}";
        runtimeInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.git
          pkgs.gnugrep
          pkgs.python3
          pkgs.systemd
        ];
        text = ''
          export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/rebb/bin:/home/rebb/.nix-profile/bin:$PATH"
          export HOME="${config.home.homeDirectory}"
          export HERMES_HOME="${config.home.homeDirectory}/Hermes"
          exec ${pkgs.bash}/bin/bash ${limp} ${action}
        '';
      };
    mkService = action: {
      Unit.Description = "Agent Garden limp mode ${action}";
      Service = {
        Type = "oneshot";
        ExecStart = "${mkWrapper action}/bin/limpmode-${action}";
        TimeoutStartSec = "10min";
      };
    };
  in {
    systemd.user.services.limpmode-on = mkService "on";
    systemd.user.services.limpmode-off = mkService "off";
    systemd.user.timers.limpmode-on = {
      Unit.Description = "Limp mode on at 19:00 SAST";
      Timer = {
        OnCalendar = "*-*-* 19:00:00 Africa/Johannesburg";
        Persistent = false;
        Unit = "limpmode-on.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
    systemd.user.timers.limpmode-off = {
      Unit.Description = "Limp mode off at 07:00 SAST";
      Timer = {
        OnCalendar = "*-*-* 07:00:00 Africa/Johannesburg";
        Persistent = false;
        Unit = "limpmode-off.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
