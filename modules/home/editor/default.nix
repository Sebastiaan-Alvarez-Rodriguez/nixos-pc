{ config, lib, pkgs, ... }: let
  cfg = config.my.home.editor;
  supported = [ "helix" "neovim" "vim" ];
in {
  options.my.home.editor = with lib; {
    program = mkOption {
      type = with types; nullOr (enum supported);
      default = null;
      description = "Which editor to use for home session";
    };

    extras = with types; mkOption {
      type = with types; listOf (enum supported);
      default = [];
      description = "extra editors to make available";
    };
  };

  config = lib.mkIf (cfg.program != null) {
    home.sessionVariables.EDITOR = lib.mkForce (lib.getExe (pkgs.${cfg.program})); # this works as long as 'supported' only contains actual package names;
    home.packages = [ pkgs.${cfg.program} ] ++ builtins.map (i: pkgs.${i}) cfg.extras;
  };
}
