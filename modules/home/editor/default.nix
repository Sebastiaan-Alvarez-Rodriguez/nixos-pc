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

    editor-name = mkOption {
      type = types.str;
      default = lib.getExe (pkgs.${cfg.program});
      description = "The name of the editor to use. Some programs use this environment variable to call the editor. Use just a name, no path needed";
    };

    extras = mkOption {
      type = with types; listOf (enum supported);
      default = [];
      description = "extra editors to make available";
    };
  };

  config = lib.mkIf (cfg.program != null) {
    assertions = [
      {
        assertion = cfg.editor-name != null && cfg.editor-name != "";
        message = "Found editor name to be null/empty. Please specify the name using `my.home.editor.editor-name` manually.";
      }
    ];
    home.sessionVariables.EDITOR = cfg.editor-name;
    home.packages = [ pkgs.${cfg.program} ] ++ builtins.map (i: pkgs.${i}) cfg.extras;
  };
}
