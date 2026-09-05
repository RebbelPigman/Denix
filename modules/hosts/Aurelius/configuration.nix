{ self, inputs, ... }: {

  flake.nixosModules.aureliusConfiguration = { pkgs, lib, ... }: {
    
# system module imports
    imports = [
      self.nixosModules.core # must have
      self.nixosModules.aureliusHardware
      self.nixosModules.myHomeManager
      self.nixosModules.desk
      self.nixosModules.game
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

    networking.hostName = "Aurelius";

    users.users.rebb = {
      isNormalUser = true;
      description = "rebb";
      extraGroups = [ "wheel" "networkmanager" ];
    };

    home-manager.users.rebb = self.homeModules.aureliusHome;
  
    system.stateVersion = "26.05";

	hardware.bluetooth = {
      enable = true;
	  powerOnBoot = true;
    };

    services = {
      desktopManager.plasma6.enable = true;
      printing.enable = true;
      pulseaudio.enable = false;
      power-profiles-daemon.enable = true;
      upower.enable = true;
      xserver.xkb = {
        layout = "us";
        variant = "";
      };
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };

    security.rtkit.enable = true;
  };
}
