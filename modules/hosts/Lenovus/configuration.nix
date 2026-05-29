{ self, inputs, ... }: {

  flake.nixosModules.lenovusConfiguration = { pkgs, lib, ... }: {
    
# system module imports
    imports = [
      self.nixosModules.core # must have
      self.nixosModules.lenovusHardware
      self.nixosModules.myHomeManager
 	  #self.nixosModules.kdeUtilities
      self.nixosModules.niri
      self.nixosModules.game
    ];

# system specific configuration
   boot = {
      loader = {
        grub = {
          device = "nodev";
          enable = true;
          useOSProber = true;
          efiSupport = true;
        };
        efi.canTouchEfiVariables = true;
      };
  	  kernelPackages = pkgs.linuxPackages_latest;
    };
   
    time.timeZone = "Africa/Johannesburg";

    networking.hostName = "Lenovus";

    users.users.rebb= {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
    };

    home-manager.users.rebb = self.homeModules.rebbModule;
  
    system.stateVersion = "25.11";

# for Noctalia
	hardware.bluetooth = {
      enable = true;
	  powerOnBoot = true;
    };
    services = {
	  power-profiles-daemon.enable = true;
	  upower.enable = true;
    };
  };
}  
