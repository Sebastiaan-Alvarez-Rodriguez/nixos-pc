{ config, lib, pkgs, ... }: let
  cfg = config.my.home.firefox.tridactyl;

  vimCommandLine = {
    alacritty = ''-e "vim" "%f" "+normal!%lGzv%c|"''; # seb: TODO what if I have no vim? Maybe better to just make this an option.
    # Termite wants the whole command in a single argument...
    foot = ''-e "vim %f '+normal!%lGzv%c|'"'';
    termite = ''-e "vim %f '+normal!%lGzv%c|'"'';
  };
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr cfg.term vimCommandLine;
        message = "Your terminal \"${cfg.term}\" is not configured to work with tridactyl (configured are: \"${builtins.toString (builtins.attrNames vimCommandLine)}\").";
      }
    ];
    xdg.configFile."tridactyl/tridactylrc".source = pkgs.substituteAll {
      src = ./tridactylrc;

      editorcmd = lib.concatStringsSep " " [
        # Use my configured terminal
        cfg.term
        # Make it easy to pick out with a window class name
        "--class tridactyl_editor"
        # Open vim with the cursor in the correct position
        (vimCommandLine.${cfg.term} or "ERROR") # seb TODO: does this actually work? src: https://discourse.nixos.org/t/how-to-gracefully-deal-with-missing-attributes/5407
      ];
    };
  };
}
