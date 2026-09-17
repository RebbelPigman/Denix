{ self, inputs, ... }: {
  # JupyterLab + common kernel packages, launched in Chromium.
  # Import once from a host home module (rebbModule / aureliusHome):
  #   imports = [ self.homeModules.jupyter ];
  # Do not also add this to home-manager.sharedModules.
  #
  # Desktop file lands in ~/.local/share/applications so fuzzel, the
  # Noctalia launcher, and Plasma's app menu all see "JupyterLab".
  # The Exec line calls a wrapper (no %s field codes) that starts Lab
  # bound to 127.0.0.1 and opens ungoogled-chromium --app=<token-url>.
  flake.homeModules.jupyter = { pkgs, lib, ... }:
  let
    jupyterEnv = pkgs.python3.withPackages (ps: with ps; [
      jupyterlab
      ipykernel
      ipywidgets
      ipympl
      numpy
      pandas
      polars
      pyarrow
      matplotlib
      seaborn
      plotly
      scipy
      statsmodels
      sympy
      scikit-learn
      tqdm
      rich
      openpyxl
      requests
    ]);
    chromium = lib.getExe pkgs.ungoogled-chromium;
    jupyterLabDesktop = pkgs.writeShellApplication {
      name = "jupyter-lab-desktop";
      runtimeInputs = [ jupyterEnv pkgs.ungoogled-chromium ];
      text = ''
        mkdir -p "$HOME/Notebooks"
        cd "$HOME/Notebooks"
        exec jupyter-lab \
          --notebook-dir="$HOME/Notebooks" \
          --ServerApp.ip=127.0.0.1 \
          --ServerApp.open_browser=True \
          --ServerApp.browser="${chromium} --new-window --app=%s"
      '';
    };
    # Local SVG so the desktop file does not depend on jupyterlab internals.
    labIcon = pkgs.writeText "jupyterlab.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
        <rect width="64" height="64" rx="12" fill="#F37626"/>
        <rect x="14" y="12" width="36" height="40" rx="3" fill="#fff"/>
        <rect x="20" y="20" width="24" height="3" rx="1.5" fill="#F37626"/>
        <rect x="20" y="28" width="18" height="3" rx="1.5" fill="#F37626"/>
        <rect x="20" y="36" width="22" height="3" rx="1.5" fill="#F37626"/>
        <circle cx="48" cy="16" r="6" fill="#9B59B6"/>
        <circle cx="16" cy="48" r="5" fill="#4E4A78"/>
      </svg>
    '';
  in {
    home.packages = [
      jupyterEnv
      jupyterLabDesktop
    ];

    # Named icon so desktop files can use Icon=jupyterlab.
    xdg.dataFile."icons/hicolor/scalable/apps/jupyterlab.svg".source = labIcon;

    xdg.desktopEntries.jupyter-lab = {
      name = "JupyterLab";
      genericName = "Notebook";
      comment = "JupyterLab in Chromium";
      exec = lib.getExe jupyterLabDesktop;
      icon = "jupyterlab";
      terminal = false;
      categories = [ "Development" "Education" "Science" ];
      mimeType = [ "application/x-ipynb+json" ];
      startupNotify = true;
    };
  };
}
