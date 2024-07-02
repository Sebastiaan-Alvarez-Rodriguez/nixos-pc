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
    wait-for-graphical = mkEnableOption "If set, makes greetd wait for graphical-session.target. Nice, because console greeters do not get shifted by systemd messages. WARNING: do not use on headless systems, as they have no graphical-session.target.";
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
    systemd.services.greetd.unitConfig = let
      tty = "tty${toString config.services.greetd.vt}";
    in lib.mkIf cfg.wait-for-graphical (lib.mkForce {
      # as taken from https://github.com/NixOS/nixpkgs/blob/d032c1a6dfad4eedec7e35e91986becc699d7d69/nixos/modules/services/display-managers/greetd.nix#L80
      # enhanced with optional targets to wait for if so configured (should not do this on headless systems).
      BindsTo = [ "graphical.target" ];
      Wants = [ "systemd-user-sessions.service" ];
      After = [ "systemd-user-sessions.service" "getty@${tty}.service" "multi-user.target" ]
        ++ lib.optionals (!config.services.greetd.greeterManagesPlymouth) [ "plymouth-quit-wait.service" ];
      Conflicts = [ "getty@${tty}.service" ];
    });
  };
}
