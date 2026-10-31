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
      ghostscript
      poppler-utils
      krita
      gimp
      kdePackages.kdenlive
    ];
  };
}
