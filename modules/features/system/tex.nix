{ ... }: {
  # TeXstudio + texliveMedium. Not imported. office does not pull this.
  # Import from the host that wants it:
  #   self.nixosModules.tex
  flake.nixosModules.tex = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      texstudio
      (texliveMedium.withPackages (ps: with ps; [
        latexmk
        amsmath
        mathtools
        physics
        enumitem
        cancel
        collection-fontsrecommended
        biber
        biblatex
        csquotes
        hyperref
        geometry
        xcolor
        listings
        booktabs
        siunitx
      ]))
    ];
  };
}
