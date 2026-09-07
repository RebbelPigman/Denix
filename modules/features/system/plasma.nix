{ self, inputs, ... }: {
  flake.nixosModules.plasma = { pkgs, ... }: {
    imports = [
      self.nixosModules.desk
    ];

    services.desktopManager.plasma6.enable = true;

    programs.kdeconnect.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.filelight
      kdePackages.partitionmanager
      kdePackages.ksystemlog
      kdePackages.kcharselect
      kdePackages.isoimagewriter
    ];
  };
}
