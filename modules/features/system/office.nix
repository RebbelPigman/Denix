{ self, inputs, ... }: {
  flake.nixosModules.office = { pkgs, ... }: {
    imports = [
      self.nixosModules.plasma
    ];

    environment.systemPackages = with pkgs; [
      libreoffice-qt6
      hunspell
      hunspellDicts.en-gb-ise
      hunspellDicts.en-us
      pdfarranger
      texstudio
      (texlive.combine {
        inherit (texlive)
          scheme-medium
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
          ;
      })
      ghostscript
      poppler-utils
      krita
      gimp
      kdePackages.kdenlive
    ];
  };
}
