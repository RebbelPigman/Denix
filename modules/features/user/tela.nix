{ self, inputs, ... }: {
  # GTK + Qt icon theme for niri hosts.
  # Import from a host home module, or let nixosModules.niri
  # attach it via home-manager.sharedModules.
  flake.homeModules.tela = { pkgs, ... }: {
    gtk = {
      enable = true;
      iconTheme = {
        # Directory name from tela-circle-icon-theme (standard variant).
        # Dark session: "Tela-circle-dark".
        # Plasma rice match: "Tela-circle-purple-dark" + colorVariants = [ "purple" ].
        name = "Tela-circle";
        package = pkgs.tela-circle-icon-theme;
      };
    };

    # qt6ct is the niri wrapper's platform theme; point it at the same set.
    qt = {
      enable = true;
      platformTheme.name = "qtct";
    };

    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Tela-circle
    '';

    home.sessionVariables.GTK_ICON_THEME = "Tela-circle";
  };
}
