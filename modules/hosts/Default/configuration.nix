{ self, inputs, ... }: {

  flake.nixosModules.defaultConfiguration = { pkgs, lib, ... }: {
    
# system module imports
    imports = [
      self.nixosModules.core # needed utilities to make system usable
      self.nixosModules.defaultHardware # hardware configuration
      self.nixosModules.myHomeManager # home manager
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

    networking.hostName = "default";

    users.users.john= {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
    };

    home-manager.users.john = self.homeModules.johnModule;
  
    system.stateVersion = "26.05";

    # Bluetooth (noctalia)
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # power management (noctalia)
    services = {
      power-profiles-daemon.enable = true;
      upower.enable = true;
    };
  };
}
