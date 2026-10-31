{ ... }: {
  # Container Android. Not part of game.
  # Aurelius has images under /var/lib/waydroid. Unison does not.
  # Import only on the host that should run it:
  #   self.nixosModules.waydroid
  #
  # linuxPackages_latest often has no ip_tables. Stock pkgs.waydroid
  # drives waydroid-net.sh through iptables-legacy and dies.
  # waydroid-nftables uses nft. Does not turn on networking.nftables.
  # Images are not in the closure. First init, as root:
  #   sudo waydroid init -s GAPPS
  flake.nixosModules.waydroid = { pkgs, ... }: {
    virtualisation.waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  };
}
