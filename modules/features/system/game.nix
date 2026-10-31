{ self, inputs, ... }: {
  flake.nixosModules.game = { pkgs, lib, ... }: {
    environment.systemPackages = with pkgs; [
      vesktop
      # Upstream Name=Vesktop. A hiPrio sibling that only ships vesktop.desktop
      # wins the collision so fuzzel lists it as Discord. Exec and WM class stay.
      (lib.hiPrio (pkgs.runCommand "vesktop-desktop-name" { } ''
        mkdir -p $out/share/applications
        sed -E 's/^Name(\[[^]]+\])?=Vesktop$/Name\1=Discord/' \
          ${pkgs.vesktop}/share/applications/vesktop.desktop \
          > $out/share/applications/vesktop.desktop
      ''))
      prismlauncher
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
        # Dedicated-server ports stay closed. These hosts are laptops, not servers.
        dedicatedServer.openFirewall = false;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
    };
    # 32-bit ALSA for Steam / Proton. Hosts enable pipewire; this flag lives here.
    services.pipewire.alsa.support32Bit = true;
  };
}
