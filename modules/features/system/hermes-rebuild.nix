{ ... }: {
  # Passwordless rebuild for the Hermes agent (no TTY / askpass).
  # Import from a host that already runs homeModules.hermes:
  #   self.nixosModules.hermesRebuild
  #
  # Never pass --sudo. That wraps activation as `sudo env -i … systemd-run …`,
  # which does not match any NOPASSWD rule.
  # Outer sudo on nixos-rebuild is already root, so test/boot/switch work on
  # every running generation that includes this module (nixos-rebuild is
  # always at /run/current-system/sw/bin). denix-rebuild is the same actions
  # with the flake evaluated as rebb, once that generation is current.
  flake.nixosModules.hermesRebuild = { pkgs, ... }:
  let
    denixRebuild = pkgs.writeShellApplication {
      name = "denix-rebuild";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.nix
        pkgs.nixos-rebuild
        pkgs.systemd
        pkgs.util-linux
      ];
      text = ''
        if [ "$#" -ne 1 ]; then
          echo "usage: denix-rebuild {test|boot|switch}" >&2
          exit 1
        fi

        action=$1
        case "$action" in
          test|boot|switch) ;;
          *)
            echo "usage: denix-rebuild {test|boot|switch}" >&2
            exit 1
            ;;
        esac

        if [ "$(id -u)" -ne 0 ]; then
          echo "denix-rebuild must run as root: sudo /run/current-system/sw/bin/denix-rebuild $action" >&2
          exit 1
        fi

        if [ "''${SUDO_USER:-}" != "rebb" ]; then
          echo "denix-rebuild is only for rebb via sudo" >&2
          exit 1
        fi

        host=$(tr -d '[:space:]' </etc/hostname)
        case "$host" in
          Lenovus) attr=Lenovus ;;
          Aurelius) attr=Aurelius ;;
          default) attr=Default ;;
          *)
            echo "denix-rebuild: unknown hostname $host" >&2
            exit 1
            ;;
        esac

        flake=/home/rebb/Nixos
        if [ ! -d "$flake" ]; then
          echo "denix-rebuild: missing flake $flake" >&2
          exit 1
        fi

        workdir=$(mktemp -d /tmp/denix-rebuild.XXXXXX)
        trap 'rm -rf "$workdir"' EXIT
        chown "''${SUDO_UID}:''${SUDO_GID}" "$workdir"

        (
          cd "$workdir"
          runuser -u rebb -- env HOME=/home/rebb USER=rebb LOGNAME=rebb PATH="$PATH" \
            nixos-rebuild build --flake "$flake#$attr"
        )

        result=$(readlink -f "$workdir/result")
        if [ ! -x "$result/bin/switch-to-configuration" ]; then
          echo "denix-rebuild: no switch-to-configuration in $result" >&2
          exit 1
        fi

        if [ "$action" = boot ] || [ "$action" = switch ]; then
          nix-env -p /nix/var/nix/profiles/system --set "$result"
        fi

        export NIXOS_INSTALL_BOOTLOADER=0
        systemd-run \
          -E LOCALE_ARCHIVE \
          -E NIXOS_INSTALL_BOOTLOADER \
          --collect \
          --no-ask-password \
          --pipe \
          --wait \
          --service-type=exec \
          --unit="denix-rebuild-$action-$$" \
          "$result/bin/switch-to-configuration" "$action"
      '';
    };
  in {
    environment.systemPackages = [ denixRebuild ];
    security.sudo.extraRules = [
      {
        users = [ "rebb" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/denix-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
