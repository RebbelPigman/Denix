{ ... }: {
  # Sunday 20:00 SAST rebuild-switch for reachable Denix hosts.
  # Import once, on the orchestrator (Unison):
  #   self.nixosModules.denixWeeklySwitch
  # Hermes cron cannot run this: 3-minute interrupt.
  flake.nixosModules.denixWeeklySwitch = { pkgs, ... }:
  let
    flake = "/home/rebb/Dropbox/Projects/Denix";
    script = pkgs.writeShellApplication {
      name = "denix-weekly-switch";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.hostname
        pkgs.openssh
        pkgs.nixos-rebuild
      ];
      text = ''
        set -euo pipefail
        export PATH="/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
        flake=${flake}

        log() { printf '%s %s\n' "$(date -Iseconds)" "$*"; }

        if [ "$(id -u)" -ne 0 ]; then
          log "must run as root (systemd timer)"
          exit 1
        fi

        cd /tmp
        host=$(tr -d '[:space:]' </etc/hostname)
        log "start host=$host"

        if [ ! -d "$flake/.git" ]; then
          log "missing flake $flake"
          exit 1
        fi

        # System ssh_config Includes a nix-store file owned by nobody.
        # OpenSSH rejects it. -F skips that include. Origin is SSH.
        git_ssh="ssh -F /home/rebb/.ssh/config -o BatchMode=yes -o IdentitiesOnly=yes"
        log "git pull --ff-only"
        runuser -u rebb -- env \
          HOME=/home/rebb \
          GIT_SSH_COMMAND="$git_ssh" \
          git -C "$flake" pull --ff-only

        case "$host" in
          Unison) local_attr=Unison ;;
          Aurelius) local_attr=Aurelius ;;
          *) log "unknown hostname $host"; exit 1 ;;
        esac

        log "switch local $local_attr"
        /run/current-system/sw/bin/nixos-rebuild switch --flake "$flake#$local_attr"

        switch_remote() {
          local name=$1 attr=$2
          if [ "$name" = "$host" ]; then
            return 0
          fi
          log "probe $name"
          if ! runuser -u rebb -- ssh -F /home/rebb/.ssh/config -o BatchMode=yes -o IdentitiesOnly=yes -o ConnectTimeout=15 "$name" true; then
            log "skip $name (ssh failed)"
            return 0
          fi
          log "switch $name"
          runuser -u rebb -- ssh -F /home/rebb/.ssh/config -o BatchMode=yes -o IdentitiesOnly=yes -o ConnectTimeout=15 "$name" \
            "export PATH=/run/wrappers/bin:/run/current-system/sw/bin:\$PATH
             export GIT_SSH_COMMAND='ssh -F /home/rebb/.ssh/config -o BatchMode=yes -o IdentitiesOnly=yes'
             cd /tmp
             git -C $flake pull --ff-only
             /run/wrappers/bin/sudo -n /run/current-system/sw/bin/nixos-rebuild switch --flake $flake#$attr"
        }

        switch_remote Aurelius Aurelius
        switch_remote Unison Unison
        log "done"
      '';
    };
  in {
    environment.systemPackages = [ script ];
    systemd.services.denix-weekly-switch = {
      description = "Weekly Denix nixos-rebuild switch for Unison/Aurelius";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}/bin/denix-weekly-switch";
      };
    };
    systemd.timers.denix-weekly-switch = {
      description = "Sunday 20:00 SAST Denix rebuild-switch";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun 20:00:00";
        Persistent = true;
        Unit = "denix-weekly-switch.service";
      };
    };
  };
}
