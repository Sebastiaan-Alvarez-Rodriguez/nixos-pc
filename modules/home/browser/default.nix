{ config, lib, pkgs, ... }: let
  cfg = config.my.home.browser;
  supported = [ "chromium" "firefox" "librewolf" "zen-browser" ];
in {
  imports = [ ./firefox ./librewolf ./zen-browser ];
  options.my.home.browser = with lib; {
    program = mkOption {
      type = with types; nullOr (enum supported);
      default = null;
      description = "Which browser to use for home session";
    };

    extras = with types; mkOption {
      type = with types; listOf (enum supported);
      default = [];
      description = "extra browsers to make available";
    };
  };

  config = let
    is-selected = name: cfg.program == name || (builtins.elem name cfg.extras);
  in lib.mkIf (cfg.program != null) {
    home.sessionVariables.browser = pkgs.${cfg.program}; # this works as long as 'supported' only contains actual package names;

    my.home.firefox.enable = is-selected "firefox";
    my.home.librewolf.enable = is-selected "librewolf";
    my.home.zen-browser.enable = is-selected "zen-browser";
  };
}
