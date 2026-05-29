{ self, inputs, ... }: {

  flake.nixosModules.lenovusHardware = { config, lib, pkgs, modulesPath, ... }:{
    imports = [ 
      (modulesPath + "/installer/scan/not-detected.nix")
      ];
  
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];
  
    fileSystems."/" =
      { device = "/dev/mapper/luks-519ee85b-dd59-4d94-b72c-c0f3ccc1e0ab";
        fsType = "ext4";
      };
  
    boot.initrd.luks.devices."luks-519ee85b-dd59-4d94-b72c-c0f3ccc1e0ab".device = "/dev/disk/by-uuid/519ee85b-dd59-4d94-b72c-c0f3ccc1e0ab";
  
    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/F9A2-05B0";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
  
    swapDevices = [ ];
  
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

}
