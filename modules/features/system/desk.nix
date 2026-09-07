{ self, inputs, ... }: {
  flake.nixosModules.desk = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.kolourpaint
      kdePackages.qt6ct
      qalculate-gtk
      adw-gtk3
      nwg-look
      zathura
      rmpc
      vlc
      qbittorrent
      mpv
      imv
      pavucontrol
      wl-clipboard
      wayland-utils
      xdg-utils
      ffmpeg
      unzip
      zip
      p7zip
      unrar
    ];
  };
}
