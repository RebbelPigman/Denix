
{ self, inputs, ... }: {

  flake.homeModules.nemo = { pkgs, ... }: {
    home.packages = pkgs.nemo-with-extensions;
	xdg = {
      desktopEntries.nemo = {
        name = "Nemo";
        exec = "${pkgs.nemo-with-extensions}/bin/nemo";
      };
	  mimeApps = {
        enable = true;
        defaultApplications = {
            "inode/directory" = [ "nemo.desktop" ];
            "application/x-gnome-saved-search" = [ "nemo.desktop" ];
			"text/html" = "chromium.desktop";
            "x-scheme-handler/http" = "chromium.desktop";
            "x-scheme-handler/https" = "chromium.desktop";
            "x-scheme-handler/about" = "chromium.desktop";
            "x-scheme-handler/unknown" = "chromium.desktop";
        };
      };
	};
  };
}
