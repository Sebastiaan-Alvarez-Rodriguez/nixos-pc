{ config, lib, ... }: let
  cfg = config.my.home.nix-index;
in {
  options.my.home.nix-index = with lib; {
    enable = mkEnableOption "nix-index configuration";
  };

  config.programs.nix-index = lib.mkIf cfg.enable {
    enable = true;
  };
}
