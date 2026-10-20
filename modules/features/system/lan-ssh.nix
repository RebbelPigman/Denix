{ ... }: {
  # OpenSSH + mDNS for Unison <-> Aurelius.
  # Private key lives in ~/.ssh/id_ed25519_lan (not this repo).
  # Import from those hosts:
  #   self.nixosModules.lanSsh
  flake.nixosModules.lanSsh = { ... }: {
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

    users.users.rebb.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvCM2N/+T32dZhEn3A2NeoO7JiAnIU2QwB5vOsDFMvu rebb@lan"
    ];
  };
}
