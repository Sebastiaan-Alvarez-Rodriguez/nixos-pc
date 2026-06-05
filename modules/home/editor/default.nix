{ config, lib, pkgs, ... }: let
  cfg = config.my.home.editor;
in {
  options.my.home.editor = with lib; {
    helix = mkEnableOption "hx";

    editor-name = mkOption {
      type = types.str;
      default = "hx";
      description = "The name of the editor to use. Some programs use this environment variable to call the editor. Use just a name, no path needed";
    };
  };

  config = (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.editor-name != null && cfg.editor-name != "";
          message = "Found editor name to be null/empty. Please specify the name using `my.home.editor.editor-name` manually.";
        }
      ];
      home.sessionVariables.EDITOR = cfg.editor-name;
    }
    (lib. mkIf cfg.helix {
      programs.helix.enable = true; 
      stylix.targets.helix.enable = true; # for styling automatically with system theme.
    })
  ]);
}
