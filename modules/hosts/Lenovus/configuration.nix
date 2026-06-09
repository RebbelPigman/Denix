{ self, inputs, ... }: {

  flake.nixosModules.lenovusConfiguration = { pkgs, lib, ... }: {
    
# system module imports
    imports = [
      self.nixosModules.core # must have
      self.nixosModules.lenovusHardware
      self.nixosModules.myHomeManager
      self.nixosModules.desk
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
        };  # Grub boot loader
        efi.canTouchEfiVariables = true;
      };
  	  kernelPackages = pkgs.linuxPackages_latest;
    # to help with hibernation on encrypted partition
      resumeDevice = "/dev/mapper/luks-519ee85b-dd59-4d94-b72c-c0f3ccc1e0ab";
	  kernelParams = [ "resume_offset=PUT_THE_NUMBER_HERE" ];
      initrd.systemd.enable = true;
    };

    time.timeZone = "Africa/Johannesburg";  # Required for network scync

    networking.hostName = "Lenovus";  # Devive name

    users.users.rebb= {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ]; 
    };  # wheel for sudo usage networkmanager for network manager

    home-manager.users.rebb = self.homeModules.rebbModule;
  
    system.stateVersion = "25.11";  #first instalation on device
    
	swapDevices = [{
      device = "/var/lib/swapfile";
      size = 24 * 1024;
    }];
# for Noctalia
	hardware.bluetooth = {
      enable = true;
	  powerOnBoot = true;
    };
    services = {
	  power-profiles-daemon.enable = true;
	  upower.enable = true;
      logind.lidSwitch = "suspend-then-hibernate";
    };
  };
}  
