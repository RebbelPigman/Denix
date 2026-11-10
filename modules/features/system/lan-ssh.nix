{ ... }: {
  # OpenSSH + mDNS for Unison <-> Aurelius.
  # Private keys live in ~/.ssh/id_ed25519_lan on each host (not this repo).
  # Client Host blocks: homeModules.lanSshClient.
  # Import from those hosts:
  #   self.nixosModules.lanSsh
  flake.nixosModules.lanSsh = { pkgs, ... }:
  let
    denixGc = pkgs.writeShellApplication {
      name = "denix-gc";
      runtimeInputs = [ pkgs.coreutils pkgs.nix pkgs.systemd ];
      text = ''
        if [ "$(id -u)" -ne 0 ]; then
          echo "denix-gc must run as root: sudo /run/current-system/sw/bin/denix-gc" >&2
          exit 1
        fi
        nix-collect-garbage --delete-older-than 30d
        switch=/nix/var/nix/profiles/system/bin/switch-to-configuration
        if [ ! -x "$switch" ]; then
          echo "denix-gc: missing $switch" >&2
          exit 1
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
          --unit="denix-gc-boot-$$" \
          "$switch" boot
      '';
    };
  in {
    environment.systemPackages = [ denixGc ];
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    # Unison key (rebb@lan) + Aurelius key (rebb@lan-aurelius). Private halves stay off-repo.
    users.users.rebb.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvCM2N/+T32dZhEn3A2NeoO7JiAnIU2QwB5vOsDFMvu rebb@lan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORpmSuKJvVLFaPteIgr3tNc8fDKaUPE7v261dP/Zms8 rebb@lan-aurelius"
    ];

    # Unattended remote switch from Unison's weekly timer.
    security.sudo.extraRules = [
      {
        users = [ "rebb" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/denix-gc";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-collect-garbage --delete-older-than 30d";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
