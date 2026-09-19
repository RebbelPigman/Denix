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
    # Container Android (Lineage). nixpkgs pulls the package, LXC,
    # waydroid0 firewall trust, and psi=1. Images are not in the
    # closure — after the first switch: sudo waydroid init -s GAPPS
    # Needs a Wayland session (niri / sway). NVIDIA needs software
    # GL in /var/lib/waydroid/waydroid_base.prop (wiki).
    #
    # linuxPackages_latest often has no ip_tables. Stock pkgs.waydroid
    # still drives waydroid-net.sh through iptables-legacy, which then
    # dies with "Command failed: waydroid-net.sh start". The nftables
    # build uses nft instead. Does not turn on networking.nftables.
    virtualisation.waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  };
}
