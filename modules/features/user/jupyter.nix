{ self, inputs, ... }: {
  flake.homeModules.jupyter = { pkgs, lib, ... }:
  let
    jupyterEnv = pkgs.python3.withPackages (ps: with ps; [
      jupyterlab ipykernel ipywidgets ipympl
      numpy pandas polars pyarrow
      matplotlib seaborn plotly
      scipy statsmodels sympy scikit-learn
      tqdm rich openpyxl requests
    ]);
    chromium = lib.getExe pkgs.ungoogled-chromium;
    jupyterLabDesktop = pkgs.writeShellApplication {
      name = "jupyter-lab-desktop";
      runtimeInputs = [ jupyterEnv pkgs.ungoogled-chromium ];
      text = ''
        mkdir -p "$HOME/Notebooks"
        cd "$HOME/Notebooks"
        exec jupyter-lab --notebook-dir="$HOME/Notebooks" --ServerApp.ip=127.0.0.1 --ServerApp.open_browser=True --ServerApp.browser="${chromium} --new-window --app=%s"
      '';
    };
  in {
    home.packages = [ jupyterEnv jupyterLabDesktop ];
    xdg.desktopEntries.jupyter-lab = {
      name = "JupyterLab";
      exec = lib.getExe jupyterLabDesktop;
      icon = "jupyterlab";
      terminal = false;
      categories = [ "Development" "Education" "Science" ];
      startupNotify = true;
    };
  };
}
