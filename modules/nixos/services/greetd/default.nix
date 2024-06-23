{ config, lib, pkgs, ... }: let
  cfg = config.my.services.greetd;
in {
  options.my.services.greetd = {
    enable = lib.mkEnableOption "GreetD login handler";
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      restart = false;
      settings = {
        default_session.command = let
          run = pkgs.writeShellScript "start-river" ''
            # Seems to be needed to get river to properly start
            sleep 1
            export XDG_SESSION_TYPE=wayland
            export XDG_CURRENT_DESKTOP=river
            ${pkgs.river}/bin/river
          ''; # TODO: should this not be 'my.home.packages.river'?
        in 
          ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --user-menu \
              --cmd "${run}";
          '';
      };
    };
  };
}
