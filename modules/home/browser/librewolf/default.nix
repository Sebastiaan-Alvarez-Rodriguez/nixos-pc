{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.librewolf;
in {
  options.my.home.librewolf = with lib; {
    enable = mkEnableOption "librewolf configuration";
    nightly = mkEnableOption "Get nightly build instead of beta.";
  };

  config = lib.mkIf cfg.enable {
    programs.librewolf.enable = true; 
    programs.librewolf.profiles."default" = { # new stuff!
      name = "default";
      id = 0;
      isDefault = true;
    };

    stylix.targets.librewolf.profileNames = [ "default" ]; # Required for stylix styling.
  };
}
