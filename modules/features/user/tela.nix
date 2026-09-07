{ self, inputs, ... }: {
  # GTK + Qt icon theme for niri hosts.
  # Import once from the host home module (aureliusHome / rebbModule).
  # Do not also add this to home-manager.sharedModules — gtk.iconTheme.package
  # is unique and a double attach fails the rebuild.
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
