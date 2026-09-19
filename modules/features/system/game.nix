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
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
    };
    # Container Android (Lineage). nixpkgs pulls waydroid, LXC, waydroid0
    # firewall trust, and psi=1. Images are not part of the closure —
    # after the first switch: sudo waydroid init -s GAPPS
    # Needs a Wayland session (niri / sway). NVIDIA needs software GL
    # in /var/lib/waydroid/waydroid_base.prop (wiki).
    virtualisation.waydroid.enable = true;
  };
}
