{ config, inputs, lib, pkgs, ... }: let
  spicetify-nix = inputs.spicetify-nix.outputs.packages.x86_64-linux; # seb: TODO change hardcoded system here
  # spicePkgs = inputs.spicetify-nix.outputs.packages.${pkgs.system}.default;
  # spicePkgs = inputs.spicetify-nix.outputs.packages;
  # spicePkgs = inputs.spicetify-nix.outputs.packages.x86_64-linux.default;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  cfg = config.my.home.spotify;
in {
  # imports = [ inputs.spicetify-nix.outputs.homeManagerModule ];
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  options.my.home.spotify = with lib; {
    enable = mkEnableOption "Spotify";
  };  

  config.programs.spicetify = lib.mkIf cfg.enable {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    # theme = spicePkgs.themes.SpotifyNoPremium; //Same as default spotify but without ads and anything related to getting premium
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
    ];
  };
}
