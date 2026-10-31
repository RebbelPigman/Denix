{ self, ... }: {
  # Heavy kernel stack. Import instead of jupyter, or after it.
  # Not imported. Lab stays on homeModules.jupyter.
  #   imports = [ self.homeModules.jupyterScience ];
  flake.homeModules.jupyterScience = { ... }: {
    imports = [
      self.homeModules.jupyter
    ];
    denix.jupyter.science = true;
  };
}
