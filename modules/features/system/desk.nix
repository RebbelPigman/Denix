{ self, inputs, ... }: {
  flake.nixosModules.desk = { pkgs, lib, ... }: {
    services.gvfs.enable = true;

    # Nemo / xdg-open handlers. mkForce wins over core's vim maps.
    xdg.mime.defaultApplications = {
      "inode/directory" = "nemo.desktop";
      "application/x-gnome-saved-search" = "nemo.desktop";

      # Text → Kate
      "text/plain" = lib.mkForce "org.kde.kate.desktop";
      "text/*" = lib.mkForce "org.kde.kate.desktop";
      "application/json" = lib.mkForce "org.kde.kate.desktop";
      "application/x-shellscript" = lib.mkForce "org.kde.kate.desktop";
      "application/xml" = lib.mkForce "org.kde.kate.desktop";
      "application/yaml" = lib.mkForce "org.kde.kate.desktop";
      "application/toml" = lib.mkForce "org.kde.kate.desktop";

      # Documents → Zathura
      "application/pdf" = "org.pwmt.zathura.desktop";
      "application/postscript" = "org.pwmt.zathura.desktop";
      "application/epub+zip" = "org.pwmt.zathura.desktop";
      "image/vnd.djvu" = "org.pwmt.zathura.desktop";

      # Torrents → qBittorrent
      "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
      "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
    };

    environment.systemPackages = with pkgs; [
      nemo-with-extensions
      # Upstream desktop entry is Name=Files (Nautilus-style generic name).
      # A hiPrio sibling that only ships nemo.desktop wins the collision in
      # /share/applications without rebuilding nemo.
      (lib.hiPrio (pkgs.runCommand "nemo-desktop-name" { } ''
        mkdir -p $out/share/applications
        src=${pkgs.nemo-with-extensions}/share/applications/nemo.desktop
        if [ ! -e "$src" ]; then
          src=${pkgs.nemo}/share/applications/nemo.desktop
        fi
        sed -E 's/^Name(\[[^]]+\])?=Files$/Name\1=nemo/' "$src" \
          > $out/share/applications/nemo.desktop
      ''))
      kdePackages.kalk
      kdePackages.kate
      kdePackages.kolourpaint
      kdePackages.qt6ct
      qalculate-gtk
      adw-gtk3
      nwg-look
      zathura
      rmpc
      vlc
      qbittorrent
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
