{ self, inputs, ... }: {
  # JupyterLab + common kernel packages, launched in Chromium.
  # Import once from a host home module (aureliusHome / unisonHome):
  #   imports = [ self.homeModules.jupyter ];
  # Do not also add this to home-manager.sharedModules.
  #
  # Desktop file lands in ~/.local/share/applications so fuzzel, the
  # Noctalia launcher, and Plasma's app menu all see "JupyterLab".
  # The Exec line calls a wrapper (no %s field codes) that starts Lab
  # bound to 127.0.0.1 and opens ungoogled-chromium --app=<token-url>.
  #
  # Lab UI is web CSS. Qt/GTK only paint the Chromium frame.
  # catppuccin-jupyterlab is not in nixpkgs; the wheel is fetched directly.
  # Default flavor matches Plasma: Mocha, brand mauve.
  # ~/.jupyter/lab/user-settings still wins over overrides.json.
  # jupyterlab-vim is in-cell vi (normal/insert/visual). Esc from insert
  # enters normal. Esc from normal leaves the cell (extension default).
  # Shift-Esc also enters Jupyter command mode.
  flake.homeModules.jupyter = { pkgs, lib, ... }:
  let
    catppuccin-jupyterlab = pkgs.python3Packages.buildPythonPackage rec {
      pname = "catppuccin-jupyterlab";
      version = "0.2.5";
      format = "wheel";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/7e/33/445cd4ea73fbcd0d4d11f1a15d4cb77334675ffce5732586235bac81a8f0/catppuccin_jupyterlab-0.2.5-py3-none-any.whl";
        hash = "sha256-d5uxZIf3AJ7AX9GEfWdb/+KMTi7xA3Df+SkZgVD6C6Y=";
      };
      doCheck = false;
    };

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
      jupyterlab-vim
    ] ++ [ catppuccin-jupyterlab ]);

    labOverrides = pkgs.writeText "jupyterlab-overrides.json" ''
      {
        "@jupyterlab/apputils-extension:themes": {
          "theme": "Catppuccin Mocha"
        },
        "catppuccin_jupyterlab:plugin": {
          "brandColor": "mauve",
          "accentColor": "green"
        },
        "@axlair/jupyterlab_vim:plugin": {
          "enabled": true,
          "enabledInEditors": true
        }
      }
    '';

    # share/jupyter/lab in the withPackages env is a symlink into jupyterlab.
    # A second file cannot be dropped beside it. JUPYTERLAB_DIR is a merged
    # app dir: lab assets plus settings/overrides.json.
    labAppDir = pkgs.runCommand "jupyterlab-appdir" { } ''
      mkdir -p "$out"
      ${pkgs.lndir}/bin/lndir -silent ${pkgs.python3Packages.jupyterlab}/share/jupyter/lab "$out"
      mkdir -p "$out/settings"
      cp ${labOverrides} "$out/settings/overrides.json"
    '';

    jupyterWrapped = pkgs.symlinkJoin {
      name = "jupyter-env";
      paths = [ jupyterEnv ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for b in jupyter jupyter-lab; do
          if [ -e "$out/bin/$b" ]; then
            rm "$out/bin/$b"
            makeWrapper ${jupyterEnv}/bin/$b "$out/bin/$b" \
              --set JUPYTERLAB_DIR ${labAppDir}
          fi
        done
      '';
    };

    chromium = lib.getExe pkgs.ungoogled-chromium;
    jupyterLabDesktop = pkgs.writeShellApplication {
      name = "jupyter-lab-desktop";
      runtimeInputs = [ jupyterWrapped pkgs.ungoogled-chromium ];
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
      jupyterWrapped
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
