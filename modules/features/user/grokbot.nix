{ inputs, ... }: {
  # Grok Bot desktop agent.
  # homeModules.hermes imports this. aureliusHome imports it directly
  # (Aurelius does not import hermes). Do not also import it from a host
  # that already imports hermes, and do not add it to home-manager.sharedModules.
  #
  # Package comes from the flake input grok-bot (github:jordangarrison/grok-bot-flake).
  flake.homeModules.grokbot = { pkgs, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    grokBotPkg = inputs.grok-bot.packages.${system}.default;
  in {
    home.packages = [ grokBotPkg ];
  };
}
