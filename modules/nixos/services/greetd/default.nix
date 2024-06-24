{ config, lib, pkgs, ... }: let
  cfg = config.my.services.greetd;
in {
  options.my.services.greetd = with lib; {
    enable = mkEnableOption "GreetD login handler";
    sessions = mkOption {
      type = with types; attrs;
      example = "my-session-name = ''do-start-my-window-manager param1 param2''";
      description = "List of session names and commands to execute after-login";
    };
    greeting = mkOption {
      type = with types; str;
      default = "";
      description = "One-line greeting shown at login screen";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = with lib; let 
        mkCommand = (_: cmd: {
          command =  ''${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --user-menu --greeting "${cfg.greeting}" --cmd "${cmd}";'';
        });
        sessions = mapAttrs (mkCommand) cfg.sessions;
      in {
        test_session = { # seb: TODO cannot have multiple greet commands which can be switched... Can make a bash script to switch usernames, and execute the actual graphical setup there.
          command =  ''${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --user-menu --greeting "${cfg.greeting}" --cmd "${pkgs.fish}/bin/fish";'';
          user = "greeter";
        };
      } // sessions;
    };
  };
}
