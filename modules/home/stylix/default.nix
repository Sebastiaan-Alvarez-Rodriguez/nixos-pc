# Apply styles over many packages
# For all supported packages (and configuration options per package),
# see the Reference > Modules here: https://nix-community.github.io/stylix/options/modules/alacritty.html 
{ config, lib, inputs, pkgs, ... }: let
  cfg = config.my.home.stylix;
in {
  imports = [ inputs.stylix.homeModules.stylix ];

  options.my.home.stylix = with lib; {
    enable = mkEnableOption "stylix";
    theme = mkOption {
      type = with types; nullOr types.str;
      default = "nord";
      description = ''
        Theme applied to all supported UI components.
        Pick any base-16 item from here: https://tinted-theming.github.io/tinted-gallery/
        Here is the related github repo: https://github.com/tinted-theming/schemes
      '';
    };

    auto-enable = mkEnableOption "Automatically enable themes if a package is detected";

    image = mkOption {
      type = with types; nullOr types.path;
      default = null;
      description = "Wallpaper to set. If set and `theme = null`, theme coloring will be based on this wallpaper";
    };

  };

  config.stylix = lib.mkIf cfg.enable {
    enable = true;
    autoEnable = cfg.auto-enable;
    base16Scheme = lib.mkIf (cfg.theme != null) "${pkgs.base16-schemes}/share/themes/${cfg.theme}.yaml";
    image = lib.mkIf (cfg.image != null) cfg.image;
  };
}
