{ self, inputs, ... }: {
  flake.nixosModules.game = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      vesktop prismlauncher
	  (heroic.override {
        extraPkgs = pkgs': with pkgs'; [
          gamescope
          gamemode
        ];
      })
    ];
    programs = {
	  gamescope.enable = true;
	  gamemode.enable = true;
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
    };
  };
}
