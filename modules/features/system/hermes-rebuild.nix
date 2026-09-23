{ ... }: {
  # Passwordless nixos-rebuild for the Hermes agent (no TTY / askpass).
  # Import from a host that already runs homeModules.hermes:
  #   self.nixosModules.hermesRebuild
  # Do not put this on Default. First enable still needs one interactive
  # `nixos-rebuild switch` so the sudoers rule exists.
  flake.nixosModules.hermesRebuild = { pkgs, lib, ... }: {
    security.sudo.extraRules = [
      {
        users = [ "rebb" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
