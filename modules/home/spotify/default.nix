{ config, inputs, lib, pkgs, ... }: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  cfg = config.my.home.spotify;
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  options.my.home.spotify = with lib; {
    enable = mkEnableOption "Spotify";
  };  

  config.programs.spicetify = lib.mkIf cfg.enable {
    enable = true;
    theme = spicePkgs.themes.spotifyNoPremium;
    enabledExtensions = with spicePkgs.extensions; [ adblock hidePodcasts ];
  };
}
