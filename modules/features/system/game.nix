{ self, inputs, ... }: {
  flake.nixosModules.game = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      vesktop prismlauncher 
    ];
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
    };
  };
}
