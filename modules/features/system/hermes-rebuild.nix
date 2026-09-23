{ ... }: {
  # Passwordless rebuild for the Hermes agent (no TTY / askpass).
  # Import from a host that already runs homeModules.hermes:
  #   self.nixosModules.hermesRebuild
  #
  # `nixos-rebuild --sudo` builds as rebb, then escalates these:
  #   nix-env  (set /nix/var/nix/profiles/system)
  #   systemd-run + switch-to-configuration  (activate / bootloader)
  # A rule on nixos-rebuild alone is not enough.
  flake.nixosModules.hermesRebuild = { ... }: {
    security.sudo.extraRules = [
      {
        users = [ "rebb" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-env";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-store";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemd-run";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/store/*/bin/switch-to-configuration";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
