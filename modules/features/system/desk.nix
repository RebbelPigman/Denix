{ self, inputs, ... }: {
  flake.nixosModules.desk = { pkgs, lib, ... }: {
    services.gvfs.enable = true;

    # Nemo / xdg-open handlers. mkForce wins over core's chromium/vim maps.
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

      # Images → imv
      "image/jpeg" = lib.mkForce "imv.desktop";
      "image/png" = lib.mkForce "imv.desktop";
      "image/gif" = lib.mkForce "imv.desktop";
      "image/webp" = lib.mkForce "imv.desktop";
      "image/svg+xml" = lib.mkForce "imv.desktop";
      "image/bmp" = lib.mkForce "imv.desktop";
      "image/tiff" = lib.mkForce "imv.desktop";
      "image/avif" = lib.mkForce "imv.desktop";
      "image/heic" = lib.mkForce "imv.desktop";
      "image/*" = "imv.desktop";

      # Audio / video → mpv
      "audio/mpeg" = lib.mkForce "mpv.desktop";
      "audio/ogg" = lib.mkForce "mpv.desktop";
      "audio/wav" = lib.mkForce "mpv.desktop";
      "audio/aac" = lib.mkForce "mpv.desktop";
      "audio/flac" = lib.mkForce "mpv.desktop";
      "audio/mp4" = lib.mkForce "mpv.desktop";
      "audio/webm" = lib.mkForce "mpv.desktop";
      "audio/*" = "mpv.desktop";
      "video/mp4" = lib.mkForce "mpv.desktop";
      "video/webm" = lib.mkForce "mpv.desktop";
      "video/ogg" = lib.mkForce "mpv.desktop";
      "video/x-matroska" = lib.mkForce "mpv.desktop";
      "video/quicktime" = lib.mkForce "mpv.desktop";
      "video/x-msvideo" = lib.mkForce "mpv.desktop";
      "video/mp2t" = lib.mkForce "mpv.desktop";
      "video/*" = "mpv.desktop";

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
