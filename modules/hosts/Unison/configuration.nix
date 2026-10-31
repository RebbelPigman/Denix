{ self, inputs, ... }: {

  flake.nixosModules.unisonConfiguration = { pkgs, lib, ... }: {
    
# system module imports
    imports = [
      self.nixosModules.core # must have
      self.nixosModules.unisonHardware
      self.nixosModules.myHomeManager
      self.nixosModules.office
      self.nixosModules.game
      self.nixosModules.hermesRebuild
      self.nixosModules.lanSsh
      self.nixosModules.denixWeeklySwitch
    ];

# system specific configuration
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
  	  kernelPackages = pkgs.linuxPackages_latest;
    };

    time.timeZone = "Africa/Johannesburg";

    i18n.defaultLocale = "en_ZA.UTF-8";

    networking.hostName = "Unison";

    users.users.rebb = {
      isNormalUser = true;
      description = "rebb";
      extraGroups = [ "wheel" "networkmanager" ];
      linger = true;
    };

    home-manager.users.rebb = self.homeModules.unisonHome;
  
    system.stateVersion = "26.05";

	hardware.bluetooth = {
      enable = true;
	  powerOnBoot = true;
    };

    services = {
      printing.enable = true;
      pulseaudio.enable = false;
      power-profiles-daemon.enable = true;
      upower.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };

    security.rtkit.enable = true;
  };
}
